'use strict';

const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret, defineString} = require('firebase-functions/params');
const admin = require('firebase-admin');
const {
  submitAurenProviderJob,
  pollAurenProviderJob,
} = require('./provider_runtime');

const REPLICATE_API_TOKEN = defineSecret('REPLICATE_API_TOKEN');
const REPLICATE_AUDIO_MODEL_VERSION = defineString('REPLICATE_AUDIO_MODEL_VERSION', {
  default: '',
  description: 'Backend-only Replicate model version for episode voice/audio generation.',
});
const REPLICATE_MUSIC_MODEL_VERSION = defineString('REPLICATE_MUSIC_MODEL_VERSION', {
  default: '',
  description: 'Backend-only Replicate model version for original music generation.',
});
const REPLICATE_SUBTITLE_MODEL_VERSION = defineString('REPLICATE_SUBTITLE_MODEL_VERSION', {
  default: '',
  description: 'Backend-only Replicate model version for subtitle generation.',
});

const db = admin.firestore();
const LOCK_MS = 6 * 60 * 1000;
const MAX_ATTEMPTS = 3;

function modelVersionForType(type) {
  if (type === 'audio') return REPLICATE_AUDIO_MODEL_VERSION.value().trim();
  if (type === 'music') return REPLICATE_MUSIC_MODEL_VERSION.value().trim();
  if (type === 'subtitles') return REPLICATE_SUBTITLE_MODEL_VERSION.value().trim();
  return '';
}

function inputForTask(data) {
  const type = String(data.type || '');
  const episode = Math.max(1, Number(data.episodeNumber || 1));
  const base = {episodeNumber: episode};
  if (type === 'subtitles') {
    return {
      ...base,
      sourceLanguage: 'auto',
      targetLanguages: Array.isArray(data.targetLanguages) ? data.targetLanguages : ['ar', 'en'],
    };
  }
  if (type === 'music') return {...base, mode: 'original', instrumental: true};
  return {...base, mode: 'voice', language: 'auto'};
}

function hasRealOutput(output) {
  return Boolean(output && (output.url || output.storagePath || output.externalId));
}

async function claimTask() {
  const queries = [
    db.collectionGroup('postAssemblyTasks')
      .where('status', '==', 'queued')
      .orderBy('updatedAt', 'asc')
      .limit(10)
      .get(),
    db.collectionGroup('postAssemblyTasks')
      .where('status', '==', 'processing')
      .orderBy('updatedAt', 'asc')
      .limit(10)
      .get(),
  ];
  const snapshots = await Promise.all(queries);

  const candidates = snapshots.flatMap((snap) => snap.docs)
    .sort((a, b) => {
      const aMs = a.data()?.updatedAt?.toMillis?.() || 0;
      const bMs = b.data()?.updatedAt?.toMillis?.() || 0;
      return aMs - bMs || a.id.localeCompare(b.id);
    });

  for (const item of candidates) {
    const ok = await db.runTransaction(async (tx) => {
      const fresh = await tx.get(item.ref);
      if (!fresh.exists) return false;
      const d = fresh.data() || {};
      const status = String(d.status || '');
      const hasPendingJob = Boolean(String(d.externalJobId || '').trim() && String(d.providerId || '').trim());

      if (status === 'processing' && hasPendingJob) {
        if (Number(d.lockUntilMs || 0) > Date.now()) return false;
        tx.update(item.ref, {
          status: 'processing',
          lockUntilMs: Date.now() + LOCK_MS,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return true;
      }

      if (status !== 'queued') return false;
      if (Number(d.attempts || 0) >= MAX_ATTEMPTS) return false;

      tx.update(item.ref, {
        status: 'processing',
        attempts: admin.firestore.FieldValue.increment(1),
        lockUntilMs: Date.now() + LOCK_MS,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (ok) return item.ref;
  }
  return null;
}

async function processTask(ref) {
  const snap = await ref.get();
  if (!snap.exists) return;
  const task = snap.data() || {};
  const type = String(task.type || '');

  if (!['audio', 'music', 'subtitles'].includes(type)) {
    await ref.set({
      status: 'failed',
      lastError: 'Unsupported post-assembly task type.',
      lockUntilMs: 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    return;
  }

  const token = REPLICATE_API_TOKEN.value().trim();
  if (!token) {
    await ref.set({
      status: 'waiting_provider',
      providerState: 'configuration_required',
      lockUntilMs: 0,
      lastError: 'No provider credential configured.',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    return;
  }

  const externalJobId = String(task.externalJobId || '').trim();
  const providerId = String(task.providerId || '').trim();

  if (externalJobId && providerId) {
    const polled = await pollAurenProviderJob({
      provider: providerId,
      credentials: {token},
      externalJobId,
    });

    if (!polled.ok) {
      await ref.set({
        status: 'processing',
        providerState: 'poll_error',
        lockUntilMs: 0,
        lastError: String(polled.message || 'Provider polling failed').slice(0, 700),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      return;
    }

    if (polled.state === 'succeeded' || polled.state === 'completed') {
      if (!hasRealOutput(polled.output)) {
        await ref.set({
          status: 'failed',
          providerState: 'invalid_output',
          lockUntilMs: 0,
          lastError: 'Provider completed without a real output artifact.',
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
        return;
      }
      await ref.set({
        status: 'output',
        providerState: polled.state,
        output: polled.output,
        externalJobId: '',
        lockUntilMs: 0,
        lastError: '',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      return;
    }

    if (polled.state === 'failed' || polled.state === 'canceled') {
      const attempts = Number(task.attempts || 0);
      await ref.set({
        status: attempts < MAX_ATTEMPTS ? 'queued' : 'failed',
        providerState: polled.state,
        externalJobId: '',
        lockUntilMs: 0,
        lastError: String(polled.error || 'Provider job failed').slice(0, 700),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      return;
    }

    await ref.set({
      status: 'processing',
      providerState: polled.state,
      lockUntilMs: 0,
      lastError: '',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    return;
  }

  const version = modelVersionForType(type);
  if (!version) {
    await ref.set({
      status: 'waiting_provider',
      providerState: 'model_configuration_required',
      lockUntilMs: 0,
      lastError: 'No backend model version configured for task type.',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    return;
  }

  const result = await submitAurenProviderJob({
    provider: 'replicate',
    credentials: {token, version},
    task: {input: inputForTask(task)},
    idempotencyKey: String(task.idempotencyKey || ref.id),
  });

  if (!result.ok) {
    await ref.set({
      status: 'waiting_provider',
      providerState: 'provider_unavailable',
      lockUntilMs: 0,
      lastError: String(result.message || 'No provider accepted task').slice(0, 700),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    return;
  }

  const output = result.result?.output;
  const hasOutput = hasRealOutput(output);
  const externalId = String(result.result?.externalJobId || '').trim();

  await ref.set({
    status: hasOutput ? 'output' : (externalId ? 'processing' : 'failed'),
    providerId: result.providerId,
    providerState: result.result?.state || 'starting',
    externalJobId: hasOutput ? '' : externalId,
    output: hasOutput ? output : null,
    providerAttempts: result.attempts || [],
    lockUntilMs: 0,
    lastError: hasOutput || externalId ? '' : 'Provider accepted task without an output or asynchronous job id.',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

exports.runAurenPostAssemblyProvider = onSchedule({
  schedule: 'every 2 minutes',
  timeZone: 'UTC',
  region: 'us-central1',
  timeoutSeconds: 120,
  memory: '512MiB',
  concurrency: 1,
  secrets: [REPLICATE_API_TOKEN],
}, async () => {
  const ref = await claimTask();
  if (!ref) return;
  try {
    await processTask(ref);
  } catch (error) {
    await ref.set({
      status: 'queued',
      lockUntilMs: 0,
      lastError: String(error?.message || error).slice(0, 700),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  }
});
