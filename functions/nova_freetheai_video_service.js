'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret, defineString} = require('firebase-functions/params');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const db = getFirestore();
const FREETHEAI_API_KEY = defineSecret('FREETHEAI_API_KEY');
const FREETHEAI_FREE_VIDEO_MODEL_IDS = defineString('FREETHEAI_FREE_VIDEO_MODEL_IDS', {default: ''});
const REGION = 'us-central1';
const API_BASE = 'https://api.freetheai.org';
const TASK_ID_RE = /^[A-Za-z0-9_-]{8,160}$/;
const TERMINAL = new Set(['completed', 'succeeded', 'failed', 'cancelled', 'canceled', 'expired']);

function normalizePrompt(data = {}) {
  const prompt = String(data.prompt || '').trim();
  if (prompt.length < 8 || prompt.length > 1800) {
    throw new Error('Prompt must contain 8–1800 characters.');
  }
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  if (!/^[A-Za-z0-9_-]{12,100}$/.test(idempotencyKey)) {
    throw new Error('A 12–100 character idempotencyKey is required.');
  }
  const model = String(data.model || '').trim();
  if (!model || model.length > 180) throw new Error('Choose a video model returned by NOVA.');
  if (data.confirmFreeTierUsage !== true) {
    throw new Error('Confirm that you understand the provider free-tier limits before submitting.');
  }
  const seconds = Number(data.seconds || 5);
  if (!Number.isInteger(seconds) || seconds < 1 || seconds > 15) {
    throw new Error('Video duration must be between 1 and 15 seconds.');
  }
  const size = String(data.size || '720p');
  if (!/^(480p|720p|1080p|[0-9]{3,4}x[0-9]{3,4})$/.test(size)) {
    throw new Error('Invalid video size.');
  }
  return {prompt, idempotencyKey, model, seconds, size};
}

function freeModelIds() {
  return FREETHEAI_FREE_VIDEO_MODEL_IDS.value().split(',').map((x) => x.trim()).filter(Boolean);
}

async function requestFreeTheAI(path, method = 'GET', body) {
  const key = FREETHEAI_API_KEY.value().trim();
  if (!key) throw new Error('FREETHEAI_API_KEY is not configured in Firebase Secret Manager.');
  if (!path.startsWith('/v1/')) throw new Error('Invalid provider path.');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25000);
  try {
    const response = await fetch(API_BASE + path, {
      method,
      headers: {authorization: 'Bearer ' + key, 'content-type': 'application/json'},
      ...(body ? {body: JSON.stringify(body)} : {}),
      signal: controller.signal,
    });
    const raw = await response.text();
    let payload = {};
    try { payload = JSON.parse(raw); } catch (_) {}
    if (!response.ok) {
      throw new Error(String(payload?.error?.message || payload?.message || raw || 'FreeTheAI HTTP ' + response.status).slice(0, 350));
    }
    return payload;
  } finally {
    clearTimeout(timeout);
  }
}

function safeStatus(value) {
  const status = String(value || 'queued').toLowerCase();
  if (['queued', 'pending', 'processing', 'in_progress', 'running', 'completed', 'succeeded', 'failed', 'cancelled', 'canceled', 'expired'].includes(status)) return status;
  return 'queued';
}

exports.listNovaFreeTheAIVideoModels = onCall(
  {region: REGION, timeoutSeconds: 30, memory: '256MiB', enforceAppCheck: true, secrets: [FREETHEAI_API_KEY]},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in to inspect available NOVA video models.');
    try {
      const payload = await requestFreeTheAI('/v1/models');
      const models = Array.isArray(payload) ? payload : (Array.isArray(payload.models) ? payload.models : (Array.isArray(payload.data) ? payload.data : []));
      const allowed = new Set(freeModelIds());
      const videoModels = models.filter((model) => {
        const id = String(model?.id || model?.model || model?.name || '').trim();
        const type = String(model?.type || model?.task || model?.capability || '').toLowerCase();
        const isVideo = /video|text.to.video|image.to.video/i.test(type + ' ' + id);
        return id && isVideo && allowed.has(id);
      }).map((model) => ({
        id: String(model.id || model.model || model.name).trim(),
        name: String(model.name || model.display_name || model.id || model.model).slice(0, 140),
      }));
      return {
        ok: true,
        provider: 'freetheai',
        models: videoModels,
        configuredFreeModelAllowlist: allowed.size > 0,
        message: videoModels.length
          ? 'Only server-allowlisted video models are shown.'
          : 'No verified free video model is enabled. Review GET /v1/models and configure FREETHEAI_FREE_VIDEO_MODEL_IDS with a model explicitly confirmed as free for your account.',
      };
    } catch (error) {
      throw new HttpsError('unavailable', String(error?.message || error).slice(0, 350));
    }
  },
);

exports.submitNovaFreeTheAIVideo = onCall(
  {region: REGION, timeoutSeconds: 35, memory: '256MiB', enforceAppCheck: true, consumeAppCheckToken: true, secrets: [FREETHEAI_API_KEY],},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to generate a NOVA video.');
    let input;
    try { input = normalizePrompt(request.data || {}); }
    catch (error) { throw new HttpsError('invalid-argument', error.message); }
    if (!freeModelIds().includes(input.model)) {
      throw new HttpsError('failed-precondition', 'This model is not on the server allowlist of models verified as free. No provider request was sent.');
    }

    const taskRef = db.collection('users').doc(uid).collection('nova_video_generations').doc(input.idempotencyKey);
    const created = await db.runTransaction(async (tx) => {
      const snap = await tx.get(taskRef);
      if (snap.exists) return {created: false, data: snap.data() || {}};
      const record = {
        ownerUid: uid, provider: 'freetheai', model: input.model,
        prompt: input.prompt, duration: input.seconds, size: input.size,
        status: 'submitting', providerTaskId: null, videoUrl: null, error: null,
        createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
      };
      tx.create(taskRef, record);
      return {created: true, data: record};
    });
    if (!created.created) {
      const prior = created.data;
      if (prior.provider !== 'freetheai') throw new HttpsError('already-exists', 'This idempotency key belongs to another video provider.');
      return {ok: true, created: false, taskId: input.idempotencyKey, status: prior.status || 'submitting', videoUrl: prior.videoUrl || null, message: 'Existing task returned; no duplicate generation submitted.'};
    }

    try {
      const payload = await requestFreeTheAI('/v1/videos', 'POST', {
        model: input.model, prompt: input.prompt, seconds: input.seconds, size: input.size,
      });
      const providerTaskId = String(payload.id || payload.task_id || payload.video_id || '').trim();
      if (!TASK_ID_RE.test(providerTaskId)) throw new Error('Provider returned an invalid task identifier.');
      const status = safeStatus(payload.status);
      const videoUrl = typeof payload.content_url === 'string' && /^https:\/\//i.test(payload.content_url) ? payload.content_url : null;
      await taskRef.set({
        status, providerTaskId, videoUrl,
        error: payload.error ? String(payload.error).slice(0, 350) : null,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      return {ok: true, created: true, taskId: input.idempotencyKey, status, videoUrl, message: 'Submitted to FreeTheAI using the server-allowlisted model. Poll status to retrieve the result.'};
    } catch (error) {
      const message = String(error?.message || error).slice(0, 350);
      await taskRef.set({status: 'failed', error: message, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
      throw new HttpsError('unavailable', message);
    }
  },
);

exports.getNovaFreeTheAIVideoStatus = onCall(
  {region: REGION, timeoutSeconds: 30, memory: '256MiB', enforceAppCheck: true, secrets: [FREETHEAI_API_KEY]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to view NOVA video generations.');
    const taskId = String(request.data?.taskId || '').trim();
    if (!/^[A-Za-z0-9_-]{12,100}$/.test(taskId)) throw new HttpsError('invalid-argument', 'Invalid video task ID.');
    const taskRef = db.collection('users').doc(uid).collection('nova_video_generations').doc(taskId);
    const snap = await taskRef.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Video generation not found.');
    const task = snap.data() || {};
    if (task.ownerUid !== uid) throw new HttpsError('permission-denied', 'Video generation belongs to another user.');
    if (task.provider !== 'freetheai') throw new HttpsError('failed-precondition', 'This task belongs to another provider.');
    if (!task.providerTaskId || !TASK_ID_RE.test(String(task.providerTaskId))) {
      return {taskId, status: task.status || 'submitting', videoUrl: null, error: task.error || null};
    }
    try {
      const payload = await requestFreeTheAI('/v1/videos/' + encodeURIComponent(task.providerTaskId));
      const status = safeStatus(payload.status);
      const videoUrl = typeof payload.content_url === 'string' && /^https:\/\//i.test(payload.content_url)
        ? payload.content_url : (task.videoUrl || null);
      const error = payload.error ? String(payload.error).slice(0, 350) : null;
      await taskRef.set({status, videoUrl, error, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
      return {taskId, status, videoUrl, error, terminal: TERMINAL.has(status)};
    } catch (error) {
      throw new HttpsError('unavailable', String(error?.message || error).slice(0, 350));
    }
  },
);

exports.normalizeNovaFreeTheAIVideoInput = normalizePrompt;
exports.novaFreeTheAIVideoSafeStatus = safeStatus;
