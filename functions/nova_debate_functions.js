'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {
  normalizeDebateInput,
  buildDebateMessages,
  normalizeDebateResult,
  parseModelJson,
} = require('./nova_debate_engine');

const OPENROUTER_API_KEY = defineSecret('OPENROUTER_API_KEY');
const db = getFirestore();

async function requestDebateModel(messages) {
  const key = OPENROUTER_API_KEY.value().trim();
  if (!key) throw new HttpsError('failed-precondition', 'مفتاح OpenRouter غير مضبوط في Firebase Secrets.');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 45000);
  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method:'POST',
      headers:{
        'content-type':'application/json',
        authorization:'Bearer ' + key,
        'HTTP-Referer':'https://auren.app',
        'X-Title':'NOVA Strategic Debate',
      },
      body:JSON.stringify({
        model:'openrouter/free',
        messages,
        temperature:0.2,
        response_format:{type:'json_object'},
      }),
      signal:controller.signal,
    });
    const raw = await response.text();
    let payload = {};
    try { payload = JSON.parse(raw); } catch (_) {}
    if (!response.ok) {
      throw new HttpsError('unavailable', 'تعذر الوصول إلى نموذج النقاش: ' +
        String(payload?.error?.message || payload?.message || raw).slice(0, 300));
    }
    const content = payload?.choices?.[0]?.message?.content;
    if (typeof content !== 'string' || !content.trim()) {
      throw new HttpsError('unavailable', 'لم يرجع مزود الذكاء الاصطناعي نتيجة قابلة للقراءة.');
    }
    return parseModelJson(content);
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', 'فشل طلب مجلس النقاش: ' + String(error?.message || error).slice(0, 250));
  } finally {
    clearTimeout(timeout);
  }
}

exports.novaStrategicDebate = onCall(
  {region:'us-central1', timeoutSeconds:60, memory:'256MiB', secrets:[OPENROUTER_API_KEY]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    let input;
    try { input = normalizeDebateInput(request.data || {}); }
    catch (error) { throw new HttpsError('invalid-argument', error.message); }

    const rawResult = await requestDebateModel(buildDebateMessages(input));
    const debate = normalizeDebateResult(rawResult);
    const ref = db.collection('users').doc(uid).collection('nova_debates').doc();
    await ref.set({
      ownerId:uid,
      prompt:input.prompt,
      context:input.context,
      debate,
      provider:'openrouter',
      model:'openrouter/free',
      status:'awaiting_user_agreement',
      createdAt:FieldValue.serverTimestamp(),
      updatedAt:FieldValue.serverTimestamp(),
      approvedAt:null,
      approvedBy:null,
    });
    return {debateId:ref.id, debate, status:'awaiting_user_agreement'};
  },
);

exports.novaApproveDebatePlan = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB'},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const debateId = String(request.data?.debateId || '').trim();
    if (!/^[A-Za-z0-9A-Za-z_-]{1,128}$/.test(debateId)) {
      throw new HttpsError('invalid-argument', 'Invalid debate id.');
    }
    const ref = db.collection('users').doc(uid).collection('nova_debates').doc(debateId);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Debate not found.');
      const data = snap.data() || {};
      if (data.ownerId !== uid) throw new HttpsError('permission-denied', 'Only the owner may approve this plan.');
      if (data.status !== 'awaiting_user_agreement') {
        throw new HttpsError('failed-precondition', 'This plan is not awaiting approval.');
      }
      tx.update(ref, {
        status:'plan_approved',
        approvedBy:uid,
        approvedAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
        executionStarted:false,
      });
    });
    return {
      debateId,
      status:'plan_approved',
      executionStarted:false,
      message:'تم تسجيل موافقتك فقط. لم يبدأ التنفيذ أو النشر أو إرسال الرسائل أو أي إجراء مالي.',
    };
  },
);
