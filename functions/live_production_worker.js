'use strict';

const crypto = require('node:crypto');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret, defineString} = require('firebase-functions/params');
const admin = require('firebase-admin');
const {
  submitAurenProviderJob,
  pollAurenProviderJob,
} = require('./provider_runtime');

const REPLICATE_API_TOKEN = defineSecret('REPLICATE_API_TOKEN');
const REPLICATE_VIDEO_MODEL_VERSION = defineString('REPLICATE_VIDEO_MODEL_VERSION', {default:'', description:'Replicate version ID for AUREN video generation. Leave empty until a real video model is configured.'});
const db = admin.firestore();

const LOCK_MS = 6 * 60 * 1000;
const MAX_ATTEMPTS = 5;
const POLL_BACKOFF_BASE_MS = 60 * 1000;
const POLL_BACKOFF_MAX_MS = 15 * 60 * 1000;

function isTransientProviderError(error) {
  const status = Number(error?.status || error?.statusCode || 0);
  if (error?.name === 'AbortError') return true;
  return status === 408 || status === 425 || status === 429 || status >= 500;
}

function nextPollAtMs(pollFailures) {
  const failures = Math.max(1, Number(pollFailures || 0));
  return Date.now() + Math.min(POLL_BACKOFF_MAX_MS, POLL_BACKOFF_BASE_MS * (2 ** Math.min(failures - 1, 4)));
}


async function exhaustGenerationAttempts() {
  const snap = await db.collectionGroup('productionTasks')
    .where('status','==','generation')
    .orderBy('updatedAt','asc')
    .limit(10).get();

  for (const item of snap.docs) {
    let exhausted = false;
    await db.runTransaction(async tx => {
      const fresh = await tx.get(item.ref);
      if (!fresh.exists) return;
      const data = fresh.data() || {};
      if (String(data.status || '') !== 'generation') return;
      if (Number(data.generationAttempts || 0) < MAX_ATTEMPTS) return;
      tx.update(item.ref, {
        status:'failed',
        providerState:'attempts_exhausted',
        providerLockUntilMs:0,
        lastError:`Generation attempt limit (${MAX_ATTEMPTS}) reached. Retry the task to start a new generation cycle.`,
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      });
      exhausted = true;
    });
    if (exhausted) {
      try {
        await syncProductionLifecycle(item.ref, null, 'failed',
          `Generation attempt limit (${MAX_ATTEMPTS}) reached.`);
      } catch (_) {
        // Lifecycle telemetry must never prevent other tasks from running.
      }
    }
  }
}

async function recoverStaleLocks() {
  const now = Date.now();
  const snap = await db.collectionGroup('productionTasks')
    .where('status','in',['provider_pending','processing'])
    .orderBy('updatedAt','asc')
    .limit(20).get();

  for (const item of snap.docs) {
    let recovered = false;
    await db.runTransaction(async tx => {
      const fresh = await tx.get(item.ref);
      if (!fresh.exists) return;
      const data = fresh.data() || {};
      const status = String(data.status || '');
      const lockUntil = Number(data.providerLockUntilMs || 0);
      if (!['provider_pending','processing'].includes(status)) return;
      if (lockUntil <= 0 || lockUntil > now) return;
      tx.update(item.ref, {
        providerLockUntilMs: 0,
        providerState: 'stale_lock_recovered',
        lastError: 'Worker lock expired; task released for safe recovery.',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      recovered = true;
    });
    if (recovered) {
      try {
        await syncProductionLifecycle(item.ref, null, 'stale_lock_recovered',
          'Worker lock expired; task released for safe recovery.');
      } catch (_) {
        // Lifecycle telemetry must never prevent other tasks from running.
      }
    }
  }
}


async function claimTask() {
  const snap = await db.collectionGroup('productionTasks')
    .where('status','in',['generation','provider_pending','processing'])
    .orderBy('updatedAt','asc')
    .limit(10).get();

  for (const item of snap.docs) {
    const claimed = await db.runTransaction(async tx => {
      const fresh = await tx.get(item.ref);
      if (!fresh.exists) return false;
      const data=fresh.data() || {};
      if (!['generation','provider_pending','processing'].includes(String(data.status || ''))) return false;
      if (Number(data.providerLockUntilMs || 0) > Date.now()) return false;
      if (Number(data.nextPollAtMs || 0) > Date.now()) return false;
      if (Number(data.generationAttempts || 0) >= MAX_ATTEMPTS) return false;
      tx.update(item.ref,{
        status:'provider_pending',
        ...(String(data.status || '') === 'generation'
          ? {generationAttempts:admin.firestore.FieldValue.increment(1)}
          : {}),
        providerLockUntilMs:Date.now()+LOCK_MS,
        providerClaimedAt:admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (claimed) return item.ref;
  }
  return null;
}

function taskInput(data) {
  return {
    prompt:String(data.prompt || '').slice(0,3000),
    negative_prompt:String(data.negativePrompt || '').slice(0,1000),
    ...(data.input && typeof data.input === 'object' ? data.input : {}),
  };
}


function outputKey(taskId, output) {
  const raw = [taskId, output?.externalId || '', output?.storagePath || '', output?.url || ''].join('|');
  return crypto.createHash('sha256').update(raw).digest('hex').slice(0, 32);
}

function lifecycleEventId(task, event) {
  return `${String(task.id || task.taskId || 'task')}_${event}_${Number(task.generationAttempts || 0)}_${Number(task.retryCount || 0)}`.replace(/[^A-Za-z0-9_-]/g, '_').slice(0, 120);
}

async function syncProductionLifecycle(ref, output = null, event = 'output', error = '') {
  const snap = await ref.get();
  if (!snap.exists) return;
  const task = snap.data() || {};
  const uid = ref.parent.parent?.id;
  if (!uid) return;
  const history = db.collection('users').doc(uid).collection('productionHistory').doc(lifecycleEventId({...task, id:ref.id}, event));
  const payload = {
    taskId: ref.id,
    taskPath: ref.path,
    event,
    status: String(task.status || ''),
    type: String(task.type || task.kind || task.mediaType || 'production'),
    title: String(task.title || task.name || 'Untitled production').slice(0, 200),
    attempt: Number(task.generationAttempts || 0),
    retryCount: Number(task.retryCount || 0),
    error: String(error || task.lastError || '').slice(0, 700),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (output && (output.url || output.storagePath || output.externalId)) {
    const outputDoc = db.collection('users').doc(uid).collection('outputLibrary').doc(outputKey(ref.id, output));
    const normalized = {
      url: output.url || null,
      storagePath: output.storagePath || null,
      externalId: output.externalId || null,
    };
    await outputDoc.set({
      taskId: ref.id,
      taskPath: ref.path,
      type: payload.type,
      title: payload.title,
      output: normalized,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    payload.outputLibraryId = outputDoc.id;
  }
  await history.set(payload);
}

async function processTask(ref) {
  const snap=await ref.get();
  if (!snap.exists) return;
  const task=snap.data() || {};
  // Cancellation is authoritative: never let an in-flight provider job revive a
  // task after the user has cancelled it.
  if (String(task.status || '') === 'cancelled' || task.cancelRequested === true) {
    return;
  }
  const idempotencyKey=String(task.idempotencyKey || ref.id);

  // Resume an already-submitted asynchronous job instead of submitting twice.
  if (task.externalJobId && task.providerId) {
    const polled=await pollAurenProviderJob({
      provider:String(task.providerId),
      credentials:{token:REPLICATE_API_TOKEN.value()},
      externalJobId:String(task.externalJobId),
    });
    if (!polled.ok) {
      if (isTransientProviderError(polled)) {
        const pollFailures = Number(task.providerPollFailures || 0) + 1;
        await ref.set({
          status:'processing',
          providerState:'poll_backoff',
          providerPollFailures:pollFailures,
          nextPollAtMs:nextPollAtMs(pollFailures),
          providerLockUntilMs:0,
          lastError:String(polled.message || 'Temporary provider polling failure.').slice(0,700),
          updatedAt:admin.firestore.FieldValue.serverTimestamp(),
        },{merge:true});
        await syncProductionLifecycle(ref, null, 'poll_backoff', polled.message || 'Temporary provider polling failure.');
        return;
      }
      throw Object.assign(new Error(polled.message || 'Provider polling failed.'), {status:polled.status});
    }
    const state=String(polled.state || '').toLowerCase();
    const latest = await ref.get();
    if (!latest.exists) return;
    const latestTask = latest.data() || {};
    if (String(latestTask.status || '') === 'cancelled' || latestTask.cancelRequested === true) {
      return;
    }
    if (polled.output && (polled.output.url || polled.output.storagePath || polled.output.externalId)) {
      await ref.set({
        status:'output',
        output:polled.output,
        providerState:state,
        providerLockUntilMs:0,
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      },{merge:true});
      await syncProductionLifecycle(ref, polled.output, 'output');
      return;
    }
    if (state === 'failed' || state === 'canceled') {
      await ref.set({
        status:'failed',
        providerState:state,
        externalJobId:'',
        providerLockUntilMs:0,
        lastError:String(polled.error || 'Provider job failed.').slice(0,700),
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      },{merge:true});
      await syncProductionLifecycle(ref, null, 'failed', polled.error || 'Provider job failed.');
      return;
    }
    await ref.set({
      status:'processing',
      providerState:state,
      providerLockUntilMs:0,
      providerPollFailures:0,
      nextPollAtMs:0,
      updatedAt:admin.firestore.FieldValue.serverTimestamp(),
    },{merge:true});
    return;
  }

  const candidates=Array.isArray(task.providerCandidates) && task.providerCandidates.length
    ? task.providerCandidates.map((id)=>String(id || '').trim()).filter(Boolean)
    : ['replicate'];

  // The current live video adapter is Replicate. Provider/model selection and
  // executable credentials are backend-controlled only.

  // A video task must use the backend deployment configuration. The catalog
  // alone is never treated as an executable integration.
  const version=String(REPLICATE_VIDEO_MODEL_VERSION.value() || '').trim();
  if (!version) {
    await ref.set({
      status:'waiting_provider',
      providerState:'configuration_required',
      providerLockUntilMs:0,
      lastError:'No Replicate model version configured for this video task.',
      updatedAt:admin.firestore.FieldValue.serverTimestamp(),
    },{merge:true});
    await syncProductionLifecycle(ref, null, 'waiting_provider', 'No Replicate model version configured for this video task.');
    return;
  }

  const provider = candidates.includes('replicate') ? 'replicate' : '';
  if (!provider) {
    await ref.set({status:'waiting_provider',providerState:'no_live_video_adapter',providerLockUntilMs:0,lastError:'No live video provider adapter is configured for this task.',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    await syncProductionLifecycle(ref, null, 'waiting_provider', 'No live video provider adapter is configured for this task.');
    return;
  }

  const result=await submitAurenProviderJob({
    provider,
    credentials:{token:REPLICATE_API_TOKEN.value(),version},
    task:{input:taskInput(task)},
    idempotencyKey,
  });

  if (!result.ok) {
    await ref.set({
      status:'waiting_provider',
      providerState:'provider_unavailable',
      providerLockUntilMs:0,
      lastError:String(result.message || 'Provider rejected task').slice(0,700),
      updatedAt:admin.firestore.FieldValue.serverTimestamp(),
    },{merge:true});
    await syncProductionLifecycle(ref, null, 'waiting_provider', result.message || 'Provider rejected task');
    return;
  }

  const realOutput=result.result.output &&
    (result.result.output.url || result.result.output.storagePath || result.result.output.externalId)
    ? result.result.output : null;
  await ref.set({
    status:realOutput ? 'output' : 'processing',
    providerId:result.providerId,
    providerState:result.result.state || (realOutput ? 'completed' : 'starting'),
    externalJobId:realOutput ? '' : (result.result.externalJobId || ''),
    idempotencyKey,
    output:realOutput,
    providerAttempts:result.attempts || [],
    providerLockUntilMs:0,
    providerPollFailures:0,
    nextPollAtMs:0,
    updatedAt:admin.firestore.FieldValue.serverTimestamp(),
  },{merge:true});
  if (realOutput) await syncProductionLifecycle(ref, realOutput, 'output');
}

exports.runAurenLiveProductionProvider = onSchedule(
  {
    schedule:'every 2 minutes',
    timeZone:'UTC',
    region:'us-central1',
    timeoutSeconds:120,
    memory:'512MiB',
    concurrency:1,
    secrets:[REPLICATE_API_TOKEN],
  },
  async () => {
    await exhaustGenerationAttempts();
    await recoverStaleLocks();
    const ref=await claimTask();
    if (!ref) return;
    try {
      await processTask(ref);
    } catch (error) {
      const latest = await ref.get();
      if (latest.exists && (String(latest.data()?.status || '') === 'cancelled' || latest.data()?.cancelRequested === true)) {
        return;
      }
      await ref.set({
        status:'failed',
        providerLockUntilMs:0,
        lastError:String(error?.message || error).slice(0,700),
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      },{merge:true});
      try {
        await syncProductionLifecycle(ref, null, 'failed', error?.message || error);
      } catch (_) {
        // Lifecycle telemetry must never crash the scheduled worker.
      }
    }
  }
);
