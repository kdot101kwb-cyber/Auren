'use strict';

const {onSchedule}=require('firebase-functions/v2/scheduler');
const {defineSecret,defineString}=require('firebase-functions/params');
const admin=require('firebase-admin');
const {submitAurenProviderJob,pollAurenProviderJob}=require('./provider_runtime');

const REPLICATE_API_TOKEN=defineSecret('REPLICATE_API_TOKEN');
const REPLICATE_MUSIC_CREATION_MODEL_VERSION=defineString('REPLICATE_MUSIC_CREATION_MODEL_VERSION',{default:'',description:'Backend-only Replicate model version for AUREN original music creation.'});
const db=admin.firestore(),LOCK_MS=6*60*1000,MAX_ATTEMPTS=5;
const hasOutput=o=>Boolean(o&&(o.url||o.storagePath||o.externalId));

async function claim(){
 const snap=await db.collectionGroup('entertainmentCreationJobs').where('mode','==','أغنية').where('musicProductionStage','in',['blueprint_ready','generation','processing']).orderBy('updatedAt','asc').limit(10).get();
 for(const item of snap.docs){
  const ok=await db.runTransaction(async tx=>{
   const fresh=await tx.get(item.ref);if(!fresh.exists)return false;const d=fresh.data()||{};
   if(!['blueprint_ready','generation','processing'].includes(String(d.musicProductionStage||''))||Number(d.musicWorkerLockUntilMs||0)>Date.now()||Number(d.musicWorkerAttempts||0)>=MAX_ATTEMPTS)return false;
   tx.update(item.ref,{musicProductionStage:'processing',musicWorkerLockUntilMs:Date.now()+LOCK_MS,musicWorkerAttempts:admin.firestore.FieldValue.increment(1),updatedAt:admin.firestore.FieldValue.serverTimestamp()});return true;
  }); if(ok)return item.ref;
 }
 return null;
}
async function run(ref){
 const snap=await ref.get();if(!snap.exists)return;const job=snap.data()||{},bp=job.musicBlueprint||{};
 if(!bp.title||!bp.concept)throw new Error('Music blueprint is incomplete.');
 const version=String(REPLICATE_MUSIC_CREATION_MODEL_VERSION.value()||'').trim();
 if(!version){await ref.set({musicProductionStage:'waiting_provider',musicProviderState:'model_configuration_required',musicWorkerLockUntilMs:0,lastError:'No backend music model version configured.',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});return;}
 const taskRef=ref.collection('musicProductionTasks').doc('main'),existing=await taskRef.get();
 if(!existing.exists){
  await taskRef.set({jobId:ref.id,type:'original_music',status:'queued',attempts:0,externalJobId:'',providerId:'',output:null,idempotencyKey:ref.id+':music:main',
   input:{mode:'original_song',title:String(bp.title).slice(0,300),language:String(bp.language||''),genre:String(bp.genre||''),mood:String(bp.mood||job.mood||''),tempoBpm:Number(bp.tempoBpm||0)||null,concept:String(bp.concept||'').slice(0,1200),lyrics:bp.lyrics||{},arrangement:bp.arrangement||{},vocalDirection:String(bp.vocalDirection||'').slice(0,800)},
   createdAt:admin.firestore.FieldValue.serverTimestamp(),updatedAt:admin.firestore.FieldValue.serverTimestamp()});
  await ref.set({musicProductionStage:'generation',musicProductionStatus:'queued',musicWorkerLockUntilMs:0,progress:20,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});return;
 }
 const d=existing.data()||{};
 if(d.status==='output'){await ref.set({musicProductionStage:'ready',musicProductionStatus:'ready',musicWorkerLockUntilMs:0,musicArtifact:d.output,musicProductionQc:{version:1,result:'passed',taskCount:1},progress:100,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});return;}
 if(d.status==='failed'||Number(d.lockUntilMs||0)>Date.now())return;
 const token=String(REPLICATE_API_TOKEN.value()||'').trim();if(!token)throw new Error('No Replicate token configured.');
 await taskRef.set({status:'processing',attempts:admin.firestore.FieldValue.increment(1),lockUntilMs:Date.now()+LOCK_MS,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
 const fresh=(await taskRef.get()).data()||{};
 if(fresh.externalJobId&&fresh.providerId){
  const p=await pollAurenProviderJob({provider:fresh.providerId,credentials:{token},externalJobId:String(fresh.externalJobId)});
  if(p.ok&&(p.state==='succeeded'||p.state==='completed')&&hasOutput(p.output))await taskRef.set({status:'output',output:p.output,externalJobId:'',lockUntilMs:0,providerState:p.state,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
  else if(p.state==='failed'||p.state==='canceled')await taskRef.set({status:Number(fresh.attempts||0)<MAX_ATTEMPTS?'queued':'failed',externalJobId:'',lockUntilMs:0,lastError:String(p.error||'Music provider failed').slice(0,700),updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
  else await taskRef.set({status:'processing',lockUntilMs:0,providerState:p.state||'processing',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
  return;
 }
 const result=await submitAurenProviderJob({provider:'replicate',credentials:{token,version},task:{input:d.input||{}},idempotencyKey:String(d.idempotencyKey||taskRef.id)});
 const output=result.result?.output,externalId=String(result.result?.externalJobId||'').trim();
 await taskRef.set({status:result.ok?(hasOutput(output)?'output':externalId?'processing':'failed'):'queued',output:hasOutput(output)?output:null,externalJobId:hasOutput(output)?'':externalId,providerId:result.providerId||'',providerState:result.result?.state||'starting',lockUntilMs:0,lastError:result.ok?(hasOutput(output)||externalId?'':'Provider returned no artifact.'):String(result.message||'Provider unavailable').slice(0,700),updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
}
exports.runAurenMusicCreationWorker=onSchedule({schedule:'every 2 minutes',timeZone:'UTC',region:'us-central1',timeoutSeconds:120,memory:'512MiB',concurrency:1,secrets:[REPLICATE_API_TOKEN]},async()=>{const ref=await claim();if(!ref)return;try{await run(ref);}catch(error){await ref.set({musicProductionStage:'generation',musicWorkerLockUntilMs:0,lastError:String(error?.message||error).slice(0,700),updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});}});
