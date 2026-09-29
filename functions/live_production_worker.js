'use strict';

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

async function syncProductionLifecycle(ref, output, event='output', error='') {
  const pathParts=ref.path.split('/');
  const uid=pathParts[1];
  if (!uid) return;
  const taskSnap=await ref.get();
  const task=taskSnap.exists ? (taskSnap.data() || {}) : {};
  const historyRef=db.collection('users').doc(uid).collection('productionHistory').doc();
  const outputRef=db.collection('users').doc(uid).collection('outputLibrary').doc();
  const safeOutput = output && typeof output === 'object' ? {
    url: output.url ? String(output.url) : null,
    storagePath: output.storagePath ? String(output.storagePath) : null,
    externalId: output.externalId ? String(output.externalId) : null,
  } : null;
  const batch=db.batch();
  batch.set(historyRef,{
    taskId:ref.id,
    taskPath:ref.path,
    event,
    status:String(task.status || (event === 'output' ? 'output' : 'failed')),
    type:String(task.type || task.kind || task.mediaType || 'production'),
    title:String(task.title || task.name || 'Untitled production').slice(0,200),
    attempt:Number(task.generationAttempts || 0),
    retryCount:Number(task.retryCount || 0),
    error:String(error || task.lastError || '').slice(0,700),
    createdAt:admin.firestore.FieldValue.serverTimestamp(),
    ...(safeOutput ? {output:safeOutput} : {}),
  });
  if (safeOutput && (safeOutput.url || safeOutput.storagePath || safeOutput.externalId)) {
    batch.set(outputRef,{
      taskId:ref.id,
      taskPath:ref.path,
      type:String(task.type || task.kind || task.mediaType || 'production'),
      title:String(task.title || task.name || 'Untitled production').slice(0,200),
      output:safeOutput,
      createdAt:admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}

async function processTask(ref) {
  const snap=await ref.get();
  if (!snap.exists) return;
  const task=snap.data() || {};
  const idempotencyKey=String(task.idempotencyKey || ref.id);

  // Resume an already-submitted asynchronous job instead of submitting twice.
  if (task.externalJobId && task.providerId) {
    const polled=await pollAurenProviderJob({
      provider:String(task.providerId),
      credentials:{token:REPLICATE_API_TOKEN.value()},
      externalJobId:String(task.externalJobId),
    });
    if (!polled.ok) throw new Error(polled.message || 'Provider polling failed.');
    const state=String(polled.state || '').toLowerCase();
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
      const errorMessage=String(polled.error || 'Provider job failed.').slice(0,700);
      await ref.set({
        status:'generation',
        providerState:state,
        externalJobId:'',
        providerLockUntilMs:0,
        lastError:errorMessage,
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      },{merge:true});
      await syncProductionLifecycle(ref, null, 'failed', errorMessage);
      return;
    }
    await ref.set({
      status:'processing',
      providerState:state,
      providerLockUntilMs:0,
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
    return;
  }

  const provider = candidates.includes('replicate') ? 'replicate' : '';
  if (!provider) {
    await ref.set({status:'waiting_provider',providerState:'no_live_video_adapter',providerLockUntilMs:0,lastError:'No live video provider adapter is configured for this task.',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
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
    const ref=await claimTask();
    if (!ref) return;
    try {
      await processTask(ref);
    } catch (error) {
      const errorMessage=String(error?.message || error).slice(0,700);
      await ref.set({
        status:'generation',
        providerLockUntilMs:0,
        lastError:errorMessage,
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      },{merge:true});
      await syncProductionLifecycle(ref, null, 'failed', errorMessage);
    }
  }
);
