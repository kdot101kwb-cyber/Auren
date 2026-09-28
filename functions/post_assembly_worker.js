'use strict';

const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const {submitAurenProviderJob} = require('./provider_runtime');

const REPLICATE_API_TOKEN = defineSecret('REPLICATE_API_TOKEN');
const db = admin.firestore();
const LOCK_MS = 6 * 60 * 1000;
const MAX_ATTEMPTS = 3;

function inputForTask(data) {
  const type=String(data.type||'');
  const episode=Math.max(1,Number(data.episodeNumber||1));
  const base={episodeNumber:episode};
  if(type==='subtitles') return {...base,sourceLanguage:'auto',targetLanguages:Array.isArray(data.targetLanguages)?data.targetLanguages:['ar','en']};
  if(type==='music') return {...base,mode:'original',instrumental:true};
  return {...base,mode:'voice',language:'auto'};
}

async function claimTask() {
  const snap=await db.collectionGroup('postAssemblyTasks')
    .where('status','==','queued').orderBy('updatedAt','asc').limit(10).get();
  for(const item of snap.docs){
    const ok=await db.runTransaction(async tx=>{
      const fresh=await tx.get(item.ref); if(!fresh.exists)return false;
      const d=fresh.data()||{};
      if(d.status!=='queued'||Number(d.attempts||0)>=MAX_ATTEMPTS)return false;
      tx.update(item.ref,{status:'processing',attempts:admin.firestore.FieldValue.increment(1),
        lockUntilMs:Date.now()+LOCK_MS,updatedAt:admin.firestore.FieldValue.serverTimestamp()});
      return true;
    });
    if(ok)return item.ref;
  }
  return null;
}

async function processTask(ref){
  const snap=await ref.get(); if(!snap.exists)return;
  const task=snap.data()||{};
  const type=String(task.type||'');
  if(!['audio','music','subtitles'].includes(type)){
    await ref.set({status:'failed',lastError:'Unsupported post-assembly task type.',lockUntilMs:0},{merge:true}); return;
  }

  const token=REPLICATE_API_TOKEN.value().trim();
  if(!token){
    await ref.set({status:'waiting_provider',providerState:'configuration_required',lockUntilMs:0,
      lastError:'No provider credential configured.',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true}); return;
  }

  // Provider execution is fail-closed. No synthetic media is created.
  const result=await submitAurenProviderJob({
    provider:'replicate',
    credentials:{token,version:String(task.providerVersion||'').trim()},
    task:{input:inputForTask(task)},
    idempotencyKey:String(task.idempotencyKey||ref.id),
  });

  if(!result.ok){
    await ref.set({status:'waiting_provider',providerState:'provider_unavailable',
      lockUntilMs:0,lastError:String(result.message||'No provider accepted task').slice(0,700),
      updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true}); return;
  }

  const output=result.result?.output;
  const hasOutput=Boolean(output&&(output.url||output.storagePath||output.externalId));
  await ref.set({
    status:hasOutput?'output':'processing',
    providerId:result.providerId,
    providerState:result.result?.state||'starting',
    externalJobId:hasOutput?'':(result.result?.externalJobId||''),
    output:hasOutput?output:null,
    providerAttempts:result.attempts||[],
    lockUntilMs:0,
    updatedAt:admin.firestore.FieldValue.serverTimestamp(),
  },{merge:true});
}

exports.runAurenPostAssemblyProvider = onSchedule({
  schedule:'every 2 minutes',timeZone:'UTC',region:'us-central1',
  timeoutSeconds:120,memory:'512MiB',concurrency:1,secrets:[REPLICATE_API_TOKEN],
},async()=>{
  const ref=await claimTask(); if(!ref)return;
  try{await processTask(ref);}
  catch(error){await ref.set({status:'queued',lockUntilMs:0,lastError:String(error?.message||error).slice(0,700),updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});}
});
