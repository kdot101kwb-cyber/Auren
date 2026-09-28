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

const REPLICATE_THUMBNAIL_MODEL_VERSION = defineString('REPLICATE_THUMBNAIL_MODEL_VERSION', {
  default: '',
  description: 'Backend-only Replicate model version for episode thumbnail generation.',
});
const REPLICATE_TRAILER_MODEL_VERSION = defineString('REPLICATE_TRAILER_MODEL_VERSION', {
  default: '',
  description: 'Backend-only Replicate model version for episode trailer generation.',
});

const db = admin.firestore();
const LOCK_MS = 6 * 60 * 1000;
const MAX_ATTEMPTS = 3;

function modelVersionForType(type) {
  if (type === 'audio') return REPLICATE_AUDIO_MODEL_VERSION.value().trim();
  if (type === 'music') return REPLICATE_MUSIC_MODEL_VERSION.value().trim();
  if (type === 'subtitles') return REPLICATE_SUBTITLE_MODEL_VERSION.value().trim();
  if (type === 'thumbnail') return REPLICATE_THUMBNAIL_MODEL_VERSION.value().trim();
  if (type === 'trailer') return REPLICATE_TRAILER_MODEL_VERSION.value().trim();
  return '';
}

function inputForTask(data) {
  const type = String(data.type || '');
  const episode = Math.max(1, Number(data.episodeNumber || 1));
  const base = {episodeNumber: episode};
  if (type === 'thumbnail') return {...base, mode:'poster', aspectRatio:'16:9'};
  if (type === 'trailer') return {...base, mode:'trailer', durationSeconds:30};
  if (type === 'subtitles') {
    return {
      ...base,
      sourceLanguage: 'auto',
      targetLanguages: Array.isArray(data.targetLanguages) && data.targetLanguages.length > 0 ? data.targetLanguages : ['ar', 'en', 'fr', 'es', 'pt', 'de', 'it', 'tr', 'zh', 'ja', 'ko', 'hi'],
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


async function validatePostAssemblyArtifact(output, type) {
  if (!hasRealOutput(output)) return {ok:false, reason:'missing_artifact_reference'};
  const url = String(output.url || '').trim();
  if (!url) return {ok:true, verification:'provider_artifact_reference'};
  if (!/^https?:\\/\\//i.test(url)) return {ok:false, reason:'invalid_output_url'};
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 10000);
  try {
    const response = await fetch(url, {method:'HEAD', signal:controller.signal});
    if (!response.ok) return {ok:false, reason:'artifact_http_'+response.status};
    const contentType = String(response.headers.get('content-type') || '').toLowerCase();
    const expectedAudio = type === 'audio' || type === 'music';
    const expectedImage = type === 'thumbnail';
    const expectedVideo = type === 'trailer';
    if (contentType) {
      const valid = expectedAudio
        ? contentType.startsWith('audio/')
        : expectedImage
          ? contentType.startsWith('image/')
          : expectedVideo
            ? contentType.startsWith('video/')
            : contentType.includes('text/') || contentType.includes('json') || contentType.includes('vtt') || contentType.includes('subtitle');
      if (!valid) return {ok:false, reason:'artifact_type_mismatch'};
    }
    return {ok:true, verification:'http_head', contentType:contentType || 'unknown'};
  } catch (_) {
    return {ok:false, reason:'artifact_unreachable'};
  } finally {
    clearTimeout(timer);
  }
}

async function finalizeEpisodeAssembly(ref) {
  const assemblyRef = ref.parent.parent;
  if (!assemblyRef) return;
  const snap = await assemblyRef.collection('postAssemblyTasks').get();
  const tasks = snap.docs.map((d) => ({id:d.id, ...d.data()}));
  if (!tasks.length) return;
  if (tasks.some((t) => t.status === 'failed')) {
    await assemblyRef.set({
      postAssemblyStatus:'qc_failed',
      postAssemblyQcVersion:1,
      updatedAt:admin.firestore.FieldValue.serverTimestamp(),
    }, {merge:true});
    return;
  }
  if (tasks.some((t) => t.status !== 'output')) return;
  const checks = [];
  for (const task of tasks) {
    const check = await validatePostAssemblyArtifact(task.output, String(task.type || ''));
    checks.push({taskId:task.id, type:task.type, ...check});
    if (!check.ok) {
      await assemblyRef.set({
        postAssemblyStatus:'qc_failed',
        postAssemblyQcVersion:1,
        postAssemblyArtifactChecks:checks,
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      }, {merge:true});
      return;
    }
  }
  const episodes = {};
  for (const task of tasks) {
    const n = Math.max(1, Number(task.episodeNumber || 1));
    if (!episodes[n]) episodes[n] = {};
    episodes[n][String(task.type)] = task.output;
  }
  const jobRef = assemblyRef.parent && assemblyRef.parent.parent;
  const jobSnap = jobRef ? await jobRef.get() : null;
  const job = jobSnap && jobSnap.exists ? (jobSnap.data() || {}) : {};
  const packageEpisodes = Object.keys(episodes).sort((a,b)=>Number(a)-Number(b)).map((n) => ({
    episodeNumber:Number(n),
    media:episodes[n],
    status:'ready',
  }));
  await assemblyRef.set({
    postAssemblyStatus:'ready',
    postAssemblyQcVersion:1,
    finalPackageVersion:1,
    finalPackageStatus:'ready',
    postAssemblyArtifactChecks:checks,
    finalizedEpisodes:episodes,
    finalPackage:{
      version:1,
      status:'ready',
      seriesId:assemblyRef.parent.parent.id,
      title:String(job.title || job.name || job.seriesTitle || '').slice(0,300),
      episodeCount:packageEpisodes.length,
      episodes:packageEpisodes,
      availableAssets:['video','audio','music','subtitles','thumbnail','trailer'],
    },
    finalizedAt:admin.firestore.FieldValue.serverTimestamp(),
    updatedAt:admin.firestore.FieldValue.serverTimestamp(),
  }, {merge:true});
}

async function processTask(ref) {
  const snap = await ref.get();
  if (!snap.exists) return;
  const task = snap.data() || {};
  const type = String(task.type || '');

  if (!['audio', 'music', 'subtitles', 'thumbnail', 'trailer'].includes(type)) {
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
      await finalizeEpisodeAssembly(ref);
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
  if (hasOutput) await finalizeEpisodeAssembly(ref);
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
