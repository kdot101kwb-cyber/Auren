'use strict';

const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret, defineString} = require('firebase-functions/params');
const admin = require('firebase-admin');
const {submitAurenProviderJob, pollAurenProviderJob} = require('./provider_runtime');
const {isMaterializedMusicOutput, validateMaterializedMusicOutput} = require('./music_output_validation');

async function validateProductionOutput(output) {
  return validateMaterializedMusicOutput(output, {
    getStorageFile: path => admin.storage().bucket().file(path),
  });
}

const REPLICATE_API_TOKEN = defineSecret('REPLICATE_API_TOKEN');
const REPLICATE_MUSIC_MODEL_VERSION = defineString('REPLICATE_MUSIC_MODEL_VERSION', {
  default: '',
  description: 'Replicate version ID for AUREN original music/audio generation.',
});
const db = admin.firestore();
const LOCK_MS = 6 * 60 * 1000;
const MAX_ATTEMPTS = 5;

async function claimMusicTask() {
  // Do not consume retry budget while deployment configuration is unavailable.
  if (!String(REPLICATE_API_TOKEN.value() || '').trim() ||
      !String(REPLICATE_MUSIC_MODEL_VERSION.value() || '').trim()) return null;
  const snap = await db.collectionGroup('productionTasks')
    .where('type', '==', 'music_generation')
    .where('status', 'in', ['generation', 'provider_pending', 'processing', 'waiting_provider'])
    .orderBy('updatedAt', 'asc').limit(10).get();
  for (const item of snap.docs) {
    const claimed = await db.runTransaction(async tx => {
      const fresh = await tx.get(item.ref);
      if (!fresh.exists) return false;
      const d = fresh.data() || {};
      if (!['generation','provider_pending','processing','waiting_provider'].includes(String(d.status || ''))) return false;
      if (Number(d.providerLockUntilMs || 0) > Date.now()) return false;
      const stage = String(d.status || '');
      if (stage !== 'waiting_provider' && Number(d.generationAttempts || 0) >= MAX_ATTEMPTS) return false;
      tx.update(item.ref, {
        status:'provider_pending',
        ...(stage === 'waiting_provider' ? {} : {generationAttempts:admin.firestore.FieldValue.increment(1)}),
        providerLockUntilMs:Date.now()+LOCK_MS,
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (claimed) return item.ref;
  }
  return null;
}

async function updateMusicParentJob(ref, patch) {
  const parent = ref.parent.parent;
  if (!parent) return;
  await parent.set({...patch, updatedAt:admin.firestore.FieldValue.serverTimestamp()}, {merge:true});
}

async function processMusicTask(ref) {
  const snap = await ref.get();
  if (!snap.exists) return;
  const task = snap.data() || {};
  const token = REPLICATE_API_TOKEN.value().trim();
  const version = REPLICATE_MUSIC_MODEL_VERSION.value().trim();
  if (!token || !version) {
    await ref.set({
      status:'waiting_provider',
      providerState:'configuration_required',
      providerLockUntilMs:0,
      lastError:'AUREN music provider credentials/model version are not configured.',
      updatedAt:admin.firestore.FieldValue.serverTimestamp(),
    }, {merge:true});
    await updateMusicParentJob(ref, {status:'waiting_provider', productionStage:'generation', progress:5});
    return;
  }

  if (task.externalJobId && task.providerId) {
    const polled = await pollAurenProviderJob({
      provider:String(task.providerId),
      credentials:{token},
      externalJobId:String(task.externalJobId),
    });
    if (!polled.ok) throw new Error(polled.message || 'Music provider polling failed.');
    const state = String(polled.state || '').toLowerCase();
    if (isMaterializedMusicOutput(polled.output)) {
      const artifactCheck = await validateProductionOutput(polled.output);
      if (!artifactCheck.ok) {
        const message = 'Music output failed artifact validation: ' + artifactCheck.reason;
        await ref.set({
          status:'waiting_provider',
          providerState:'artifact_validation_failed',
          providerLockUntilMs:0,
          lastError:message,
          updatedAt:admin.firestore.FieldValue.serverTimestamp(),
        }, {merge:true});
        await updateMusicParentJob(ref, {status:'waiting_provider', productionStage:'output', progress:90, providerState:'artifact_validation_failed', lastError:message});
        return;
      }
      await ref.set({
        status:'output',
        output:polled.output,
        artifactValidation:artifactCheck,
        providerState:state,
        providerLockUntilMs:0,
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      }, {merge:true});
      await updateMusicParentJob(ref, {status:'completed', productionStage:'output', progress:100, output:polled.output, artifactValidation:artifactCheck});
      return;
    }
    if ((state === 'succeeded' || state === 'completed') && polled.output && polled.output.externalId && !polled.output.url && !polled.output.storagePath) {
      await ref.set({status:'waiting_provider',providerState:'artifact_not_materialized',externalJobId:'',providerLockUntilMs:0,lastError:'Music provider completed without a playable audio URL or Storage object.',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
      await updateMusicParentJob(ref,{status:'waiting_provider',productionStage:'output',progress:90,providerState:'artifact_not_materialized',lastError:'Music provider completed without a playable audio artifact.'});
      return;
    }
    if (state === 'failed' || state === 'canceled') {
      await ref.set({
        status:'generation',
        providerState:state,
        externalJobId:'',
        providerLockUntilMs:0,
        lastError:String(polled.error || 'Music provider job failed.').slice(0,700),
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      }, {merge:true});
      await updateMusicParentJob(ref, {status:'generation', productionStage:'generation', progress:10, lastError:String(polled.error || 'Music provider job failed.').slice(0,700)});
      return;
    }
    await ref.set({status:'processing',providerState:state,providerLockUntilMs:0,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    await updateMusicParentJob(ref, {status:'processing', productionStage:'generation', progress:50, providerState:state});
    return;
  }

  const result = await submitAurenProviderJob({
    provider:'replicate',
    credentials:{token,version},
    task:{input:{
      prompt:String(task.prompt || '').slice(0,3000),
      duration:Number(task.duration || 30),
      ...(task.input && typeof task.input === 'object' ? task.input : {}),
    }},
    idempotencyKey:String(task.idempotencyKey || ref.id),
  });

  if (!result.ok) {
    await ref.set({status:'waiting_provider',providerState:'provider_unavailable',providerLockUntilMs:0,lastError:String(result.message || 'Music provider rejected task').slice(0,700),updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    await updateMusicParentJob(ref, {status:'waiting_provider', productionStage:'generation', progress:5, lastError:String(result.message || 'Music provider rejected task').slice(0,700)});
    return;
  }

  // provider_runtime returns the normalized adapter payload directly. Keep
  // support for a wrapped payload during migrations, but never assume wrapping.
  const providerPayload = result.result && typeof result.result === 'object' ? result.result : result;
  const outputCandidate = isMaterializedMusicOutput(providerPayload.output) ? providerPayload.output : null;
  const artifactCheck = outputCandidate ? await validateProductionOutput(outputCandidate) : null;
  const output = artifactCheck?.ok ? outputCandidate : null;
  const unmaterializedExternalId = !output && providerPayload.output && providerPayload.output.externalId;
  const artifactValidationFailed = Boolean(outputCandidate && !artifactCheck?.ok);
  await ref.set({
    status:output ? 'output' : (artifactValidationFailed ? 'waiting_provider' : 'processing'),
    providerId:result.providerId,
    providerState:artifactValidationFailed ? 'artifact_validation_failed' : (providerPayload.state || (output ? 'completed' : 'starting')),
    externalJobId:output ? '' : (providerPayload.externalJobId || ''),
    output,
    ...(artifactCheck ? {artifactValidation:artifactCheck} : {}),
    providerAttempts:result.attempts || [],
    providerLockUntilMs:0,
    ...(artifactValidationFailed ? {lastError:'Music output failed artifact validation: ' + artifactCheck.reason} : {}),
    updatedAt:admin.firestore.FieldValue.serverTimestamp(),
  }, {merge:true});
  if (output) {
    await updateMusicParentJob(ref, {status:'completed', productionStage:'output', progress:100, output, artifactValidation:artifactCheck});
  } else if (artifactValidationFailed) {
    await updateMusicParentJob(ref, {status:'waiting_provider', productionStage:'output', progress:90, providerState:'artifact_validation_failed', lastError:'Music output failed artifact validation: ' + artifactCheck.reason});
  } else if (unmaterializedExternalId && !providerPayload.externalJobId) {
    await ref.set({status:'waiting_provider',providerState:'artifact_not_materialized',providerLockUntilMs:0,lastError:'Music provider returned only an external artifact ID, not a playable audio URL or Storage object.',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    await updateMusicParentJob(ref,{status:'waiting_provider',productionStage:'output',progress:90,providerState:'artifact_not_materialized',lastError:'Music provider returned no playable audio artifact.'});
  } else {
    await updateMusicParentJob(ref, {status:'processing', productionStage:'generation', progress:35, providerJobId:providerPayload.externalJobId || ''});
  }
}

exports.runAurenMusicProductionWorker = onSchedule({
  schedule:'every 2 minutes',
  timeZone:'UTC',
  region:'us-central1',
  timeoutSeconds:120,
  memory:'512MiB',
  concurrency:1,
  secrets:[REPLICATE_API_TOKEN],
}, async () => {
  const ref=await claimMusicTask();
  if (!ref) return;
  try { await processMusicTask(ref); }
  catch (error) {
    const message=String(error?.message || error).slice(0,700);
    await ref.set({status:'generation',providerLockUntilMs:0,lastError:message,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    await updateMusicParentJob(ref,{status:'generation',productionStage:'generation',progress:10,lastError:message});
  }
});
