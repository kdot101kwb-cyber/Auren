'use strict';
const {requireNovaOwner} = require('./nova_owner_auth');

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const db = getFirestore();
const HF_API_KEY_ID = defineSecret('HF_API_KEY_ID');
const HF_API_KEY_SECRET = defineSecret('HF_API_KEY_SECRET');
const REGION = 'us-central1';
const VIDEO_ENDPOINT = 'https://api.higgsfield.ai/minimax/hailuo-2.3/standard/text-to-video';
const REQUEST_ID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function normalizeVideoInput(data = {}) {
  const prompt = String(data.prompt || '').trim();
  if (prompt.length < 8 || prompt.length > 1800) {
    throw new Error('Prompt must contain 8–1800 characters.');
  }
  const duration = Number(data.duration || 6);
  if (![6, 10].includes(duration)) throw new Error('Duration must be 6 or 10 seconds.');
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  if (!/^[A-Za-z0-9_-]{12,100}$/.test(idempotencyKey)) {
    throw new Error('A 12–100 character idempotencyKey is required.');
  }
  if (data.confirmPaidGeneration !== true) {
    throw new Error('Explicit confirmation is required because video generation can incur charges.');
  }
  return {prompt, duration, idempotencyKey};
}

async function higgsfieldRequest(url, method, body) {
  const id = HF_API_KEY_ID.value().trim();
  const secret = HF_API_KEY_SECRET.value().trim();
  if (!id || !secret) throw new Error('Higgsfield API credentials are not configured in Firebase Secret Manager.');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25000);
  try {
    const response = await fetch(url, {
      method,
      headers: {
        authorization: 'Key ' + id + ':' + secret,
        'content-type': 'application/json',
      },
      ...(body ? {body:JSON.stringify(body)} : {}),
      signal:controller.signal,
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new Error(String(payload.detail || payload.error || 'Higgsfield HTTP ' + response.status).slice(0, 350));
    }
    return payload;
  } finally {
    clearTimeout(timeout);
  }
}

exports.submitNovaHiggsfieldVideo = onCall(
  {region:REGION, timeoutSeconds:35, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true, secrets:[HF_API_KEY_ID, HF_API_KEY_SECRET]},
  async (request) => {
    const uid = requireNovaOwner(request);
    let input;
    try { input = normalizeVideoInput(request.data || {}); }
    catch (error) { throw new HttpsError('invalid-argument', error.message); }

    const taskRef = db.collection('users').doc(uid).collection('nova_video_generations').doc(input.idempotencyKey);
    const created = await db.runTransaction(async (tx) => {
      const snap = await tx.get(taskRef);
      if (snap.exists) return {created:false, data:snap.data() || {}};
      const record = {
        ownerUid:uid,
        provider:'higgsfield',
        workflow:'video_generation_api',
        model:'minimax/hailuo-2.3/standard/text-to-video',
        prompt:input.prompt,
        duration:input.duration,
        status:'submitting',
        requestId:null,
        videoUrl:null,
        error:null,
        createdAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
      };
      tx.create(taskRef, record);
      return {created:true, data:record};
    });
    if (!created.created) {
      return {ok:true, created:false, taskId:input.idempotencyKey, status:created.data.status || 'submitting', requestId:created.data.requestId || null, videoUrl:created.data.videoUrl || null, message:'This idempotency key was already used; no second generation was submitted.'};
    }

    try {
      const payload = await higgsfieldRequest(VIDEO_ENDPOINT, 'POST', {
        prompt:input.prompt,
        duration:input.duration,
        prompt_optimizer:true,
      });
      const requestId = String(payload.request_id || '');
      if (!REQUEST_ID_RE.test(requestId)) throw new Error('Higgsfield returned an invalid request identifier.');
      const status = String(payload.status || 'queued');
      await taskRef.set({
        status:['queued','in_progress','completed','failed','canceled','nsfw'].includes(status) ? status : 'queued',
        requestId,
        statusUrl:'https://api.higgsfield.ai/requests/' + requestId + '/status',
        videoUrl:payload.video?.url || null,
        error:payload.error ? String(payload.error).slice(0,350) : null,
        updatedAt:FieldValue.serverTimestamp(),
      }, {merge:true});
      return {ok:true, created:true, taskId:input.idempotencyKey, requestId, status, videoUrl:payload.video?.url || null, message:'Generation submitted to Higgsfield. Poll status to retrieve the finished video.'};
    } catch (error) {
      const message = String(error?.message || error).slice(0,350);
      await taskRef.set({status:'failed', error:message, updatedAt:FieldValue.serverTimestamp()}, {merge:true});
      throw new HttpsError('unavailable', message);
    }
  }
);

exports.getNovaHiggsfieldVideoStatus = onCall(
  {region:REGION, timeoutSeconds:30, memory:'256MiB', enforceAppCheck:true, secrets:[HF_API_KEY_ID, HF_API_KEY_SECRET]},
  async (request) => {
    const uid = requireNovaOwner(request);
    const taskId = String(request.data?.taskId || '').trim();
    if (!/^[A-Za-z0-9_-]{12,100}$/.test(taskId)) throw new HttpsError('invalid-argument', 'Invalid video task ID.');
    const taskRef = db.collection('users').doc(uid).collection('nova_video_generations').doc(taskId);
    const snap = await taskRef.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Video generation not found.');
    const task = snap.data() || {};
    if (task.ownerUid !== uid) throw new HttpsError('permission-denied', 'Video generation belongs to another user.');
    if (!task.requestId || !REQUEST_ID_RE.test(String(task.requestId))) {
      return {taskId, status:task.status || 'submitting', videoUrl:null, error:task.error || null};
    }
    try {
      const payload = await higgsfieldRequest('https://api.higgsfield.ai/requests/' + task.requestId + '/status', 'GET');
      const status = String(payload.status || task.status || 'queued');
      const videoUrl = payload.video?.url || task.videoUrl || null;
      const error = payload.error ? String(payload.error).slice(0,350) : null;
      await taskRef.set({status, videoUrl, error, updatedAt:FieldValue.serverTimestamp()}, {merge:true});
      return {taskId, requestId:task.requestId, status, videoUrl, error};
    } catch (error) {
      throw new HttpsError('unavailable', String(error?.message || error).slice(0,350));
    }
  }
);

module.exports.normalizeVideoInput = normalizeVideoInput;
