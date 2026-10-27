'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {normalizeGrokInput, buildGrokInput, extractResponseText, normalizeGrokReply} = require('./nova_grok_bot_core');
const {resolveGrokBotEngine} = require('./nova_grok_agent_registry');
const {buildGrokSuperpowers} = require('./nova_grok_superpowers');
const {normalizeLesson, buildLearningContext} = require('./nova_grok_learning');

const XAI_API_KEY = defineSecret('XAI_API_KEY');
const db = getFirestore();
const REGION = 'us-central1';
const WINDOW_MS = 60 * 1000;
const MAX_CALLS_PER_WINDOW = 8;
const MODEL = 'grok-4.7';

async function enforceRateLimit(uid) {
  const ref = db.collection('nova_grok_rate_limits').doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() || {} : {};
    const now = Date.now();
    const startedAt = Number(data.windowStartedAtMs || 0);
    const count = startedAt > 0 && now - startedAt < WINDOW_MS ? Number(data.count || 0) : 0;
    if (count >= MAX_CALLS_PER_WINDOW) throw new HttpsError('resource-exhausted', 'وصلت إلى الحد المؤقت لـ Grok Bot. انتظر دقيقة ثم حاول مجدداً.');
    tx.set(ref, {windowStartedAtMs: count === 0 ? now : startedAt, count: count + 1, updatedAt: FieldValue.serverTimestamp()});
  });
}

exports.novaGrokBot = onCall({
  region: REGION,
  timeoutSeconds: 60,
  memory: '256MiB',
  enforceAppCheck: true,
  secrets: [XAI_API_KEY],
}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'سجّل الدخول لاستخدام NOVA Grok Bot.');
  let input;
  try { input = normalizeGrokInput(request.data || {}); }
  catch (error) { throw new HttpsError('invalid-argument', error.message || 'طلب Grok Bot غير صالح.'); }

  const engine = resolveGrokBotEngine('grok-api');
  if (!engine.ok) throw new HttpsError('failed-precondition', 'محرك Grok غير متاح حالياً.');
  const superpowers = buildGrokSuperpowers({mode: input.mode});
  let learningContext = [];
  try {
    const lessons = await db.collection('users').doc(uid).collection('nova_grok_lessons')
      .orderBy('createdAt', 'desc').limit(12).get();
    learningContext = buildLearningContext(lessons.docs.map((doc) => doc.data()));
  } catch (_) {
    // Learning memory is optional; do not fail the user's request if it is unavailable.
    learningContext = [];
  }

  await enforceRateLimit(uid);
  const key = XAI_API_KEY.value().trim();
  if (!key) throw new HttpsError('failed-precondition', 'Grok Bot غير مفعّل بعد. يلزم ضبط XAI_API_KEY على الخادم؛ لا تضع المفتاح داخل التطبيق.');

  let response;
  try {
    response = await fetch('https://api.x.ai/v1/responses', {
      method: 'POST',
      headers: {'content-type': 'application/json', authorization: 'Bearer ' + key},
      body: JSON.stringify({
        model: MODEL,
        input: [
          buildGrokInput(input),
          {role: 'user', content: JSON.stringify({mode: input.mode, request: input.prompt, context: input.context, confirmedLessons: learningContext})},
        ],
        store: false,
        text: {format: {type: 'json_object'}},
      }),
      signal: AbortSignal.timeout(45000),
    });
  } catch (_) {
    throw new HttpsError('unavailable', 'تعذر الاتصال بخدمة Grok. لم يتم تنفيذ أي إجراء.');
  }

  if (!response.ok) {
    if (response.status === 401 || response.status === 403) throw new HttpsError('failed-precondition', 'مفتاح Grok غير صالح أو لا يملك الصلاحية المطلوبة.');
    if (response.status === 429) throw new HttpsError('resource-exhausted', 'حد استخدام Grok وصل إلى الحد المتاح. تحقق من حدود حسابك وتكلفته.');
    throw new HttpsError('unavailable', 'خدمة Grok لم تقبل الطلب (' + response.status + '). لم يتم تنفيذ أي إجراء.');
  }

  let payload;
  try { payload = await response.json(); }
  catch (_) { throw new HttpsError('internal', 'استجابة Grok غير قابلة للقراءة.'); }
  let result;
  try { result = normalizeGrokReply(extractResponseText(payload)); }
  catch (error) { throw new HttpsError('internal', error.message || 'تعذر تجهيز استجابة Grok.'); }

  await db.collection('users').doc(uid).collection('nova_grok_audit').add({
    mode: input.mode,
    model: MODEL,
    engine: engine.engine.id,
    proposedAction: result.proposedAction !== null,
    requiresApproval: result.requiresApproval,
    executionStatus: 'not_executed',
    createdAt: FieldValue.serverTimestamp(),
  });

  return {
    ok: true,
    bot: 'NOVA Grok Bot',
    model: MODEL,
    engine: engine.engine.id,
    mode: input.mode,
    ...result,
    superpowers,
    learning: {confirmedLessonsApplied: learningContext.length, persistenceRequiresExplicitConsent: true},
    executionStatus: 'not_executed',
    message: result.proposedAction
      ? 'تم تجهيز مقترح فقط. لم يبدأ التنفيذ؛ يلزم ربطه بمركز المهام وموافقة المستخدم.'
      : 'تم تجهيز الرد. لم يتم تنفيذ أي إجراء خارجي.',
  };
});

exports.novaGrokSaveLesson = onCall({
  region: REGION,
  timeoutSeconds: 15,
  memory: '256MiB',
  enforceAppCheck: true,
}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'سجّل الدخول لحفظ درس لـ NOVA.');
  if (request.data?.save !== true) throw new HttpsError('failed-precondition', 'يلزم تأكيدك الصريح لحفظ الملاحظة.');
  let lesson;
  try { lesson = normalizeLesson(request.data || {}); }
  catch (error) { throw new HttpsError('invalid-argument', error.message || 'الملاحظة غير صالحة.'); }
  const ref = await db.collection('users').doc(uid).collection('nova_grok_lessons').add({
    ...lesson,
    createdAt: FieldValue.serverTimestamp(),
    source: 'user-confirmed-feedback',
  });
  return {ok: true, lessonId: ref.id, message: 'تم حفظ الملاحظة المؤكدة لاستخدامها في المهام المناسبة لاحقاً.'};
});
