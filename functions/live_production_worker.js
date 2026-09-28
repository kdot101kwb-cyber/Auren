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
        generationAttempts:admin.firestore.FieldValue.increment(1),
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
      return;
    }
    if (state === 'failed' || state === 'canceled') {
      await ref.set({
        status:'generation',
        providerState:state,
        externalJobId:'',
        providerLockUntilMs:0,
        lastError:String(polled.error || 'Provider job failed.').slice(0,700),
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      },{merge:true});
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

  // The current live video adapter is Replicate. Keep provider/model selection
  // backend-controlled; never accept a provider URL, token, or model version
  // from the client task payload as executable credentials.

  // A video task must supply a Replicate model version. The catalog alone is
  // never treated as an executable integration.
  const version=String(task.providerVersion || task.replicateVersion || REPLICATE_VIDEO_MODEL_VERSION.value() || '').trim();
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

  await ref.set({
    status:'processing',
    providerId:result.providerId,
    providerState:result.result.state || 'starting',
    externalJobId:result.result.externalJobId || '',
    idempotencyKey,
    output:result.result.output || null,
    providerAttempts:result.attempts || [],
    providerLockUntilMs:0,
    updatedAt:admin.firestore.FieldValue.serverTimestamp(),
  },{merge:true});
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
      await ref.set({
        status:'generation',
        providerLockUntilMs:0,
        lastError:String(error?.message || error).slice(0,700),
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      },{merge:true});
    }
  }
);
