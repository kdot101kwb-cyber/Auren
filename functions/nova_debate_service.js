'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {normalizeDebateInput, buildDebateMessages, parseModelJson} = require('./nova_debate_engine');

const OPENROUTER_API_KEY = defineSecret('OPENROUTER_API_KEY');
const db = getFirestore();
const WINDOW_MS = 60 * 1000;
const MAX_CALLS_PER_WINDOW = 6;

async function enforceNovaDebateRateLimit(uid) {
  const ref = db.collection('nova_debate_rate_limits').doc(uid);
  await db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    const data = snapshot.exists ? snapshot.data() || {} : {};
    const now = Date.now();
    const windowStartedAtMs = Number(data.windowStartedAtMs || 0);
    const count = windowStartedAtMs > 0 && now - windowStartedAtMs < WINDOW_MS
      ? Number(data.count || 0) : 0;
    if (count >= MAX_CALLS_PER_WINDOW) {
      throw new HttpsError('resource-exhausted', 'وصلت إلى حد النقاش المؤقت. انتظر دقيقة ثم حاول مجدداً.');
    }
    tx.set(ref, {
      windowStartedAtMs: count === 0 ? now : windowStartedAtMs,
      count: count + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

exports.novaStrategicDebate = onCall({
  region: 'us-central1',
  timeoutSeconds: 60,
  memory: '256MiB',
  secrets: [OPENROUTER_API_KEY],
}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول لاستخدام مجلس نقاش NOVA.');
  let input;
  try {
    input = normalizeDebateInput(request.data || {});
  } catch (error) {
    throw new HttpsError('invalid-argument', error.message || 'طلب النقاش غير صالح.');
  }

  await enforceNovaDebateRateLimit(uid);
  const key = OPENROUTER_API_KEY.value().trim();
  if (!key) {
    throw new HttpsError('failed-precondition', 'خدمة النقاش غير مهيأة: يلزم ضبط OPENROUTER_API_KEY على الخادم.');
  }

  let response;
  try {
    response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: 'Bearer ' + key,
        'HTTP-Referer': 'https://auren.app',
        'X-Title': 'NOVA AI Strategic Debate',
      },
      body: JSON.stringify({
        model: 'openrouter/free',
        messages: buildDebateMessages(input),
        temperature: 0.2,
        max_tokens: 3500,
        response_format: {type: 'json_object'},
      }),
      signal: AbortSignal.timeout(45000),
    });
  } catch (error) {
    throw new HttpsError('unavailable', 'تعذر الوصول إلى مزود الذكاء الاصطناعي. لم يتم تنفيذ أي خطة.');
  }
  if (!response.ok) {
    const body = await response.text().catch(() => '');
    console.error('NOVA debate provider failure', {status:response.status, detail:body.slice(0,300)});
    throw new HttpsError('unavailable', 'تعذر إنشاء مراجعة النقاش حالياً. لم يتم تنفيذ أي خطة.');
  }

  let payload;
  try {
    payload = await response.json();
  } catch (_) {
    throw new HttpsError('internal', 'وصل رد غير صالح من مزود النقاش. لم يتم تنفيذ أي خطة.');
  }
  let debate;
  try {
    debate = parseModelJson(payload?.choices?.[0]?.message?.content || '');
  } catch (_) {
    throw new HttpsError('internal', 'لم ينتج مجلس النقاش تقريراً منظماً صالحاً. لم يتم تنفيذ أي خطة.');
  }

  const record = {
    prompt: input.prompt,
    context: input.context,
    strategy: input.strategy,
    reviewRoles: input.roles.map((role) => role.id),
    debate,
    status: 'awaiting_user_agreement',
    executionStarted: false,
    provider: 'openrouter',
    model: 'openrouter/free',
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
  const ref = await db.collection('users').doc(uid).collection('novaDebates').add(record);
  return {
    status: 'awaiting_user_agreement',
    debateId: ref.id,
    debate,
    disclaimer: 'هذه مراجعة متعددة المنظورات من استدعاء نموذج واحد وليست أربعة وكلاء مستقلين. لم يبدأ التنفيذ.',
  };
});

exports.novaApproveDebatePlan = onCall({
  region: 'us-central1',
  timeoutSeconds: 20,
  memory: '256MiB',
}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول لاعتماد الخطة.');
  const debateId = String(request.data?.debateId || '').trim();
  if (!/^[A-Za-z0-9]{16,32}$/.test(debateId)) {
    throw new HttpsError('invalid-argument', 'معرّف مراجعة غير صالح.');
  }
  const ref = db.collection('users').doc(uid).collection('novaDebates').doc(debateId);
  const auditRef = db.collection('users').doc(uid).collection('nova_audit').doc();
  return db.runTransaction(async (tx) => {
    const snapshot = await tx.get(ref);
    if (!snapshot.exists) throw new HttpsError('not-found', 'لم يتم العثور على سجل النقاش.');
    const record = snapshot.data() || {};
    if (record.status !== 'awaiting_user_agreement') {
      throw new HttpsError('failed-precondition', 'هذا النقاش ليس بانتظار الموافقة.');
    }
    if (!Array.isArray(record.debate?.plan) || record.debate.plan.length === 0) {
      throw new HttpsError('failed-precondition', 'لا توجد خطة قابلة للاعتماد.');
    }
    tx.update(ref, {
      status: 'plan_approved',
      approvedBy: uid,
      approvedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      executionStarted: false,
      executionStatus: 'blocked_adapter_not_connected',
    });
    tx.create(auditRef, {
      action: 'nova.debate.plan_approved',
      actorUid: uid,
      debateId,
      planStepCount: record.debate.plan.length,
      executionStarted: false,
      note: 'Approval recorded only; no repository changes or external side effects were executed.',
      createdAt: FieldValue.serverTimestamp(),
    });
    return {
      status: 'plan_approved',
      executionStarted: false,
      executionStatus: 'blocked_adapter_not_connected',
      message: 'تم تسجيل موافقتك. لم يبدأ التنفيذ لأن موصل تنفيذ آمن للخطة غير متصل بعد.',
    };
  });
});

