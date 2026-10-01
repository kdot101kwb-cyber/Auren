'use strict';

const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret, defineString} = require('firebase-functions/params');
const admin = require('firebase-admin');
const {submitAurenProviderJob, pollAurenProviderJob} = require('./provider_runtime');

const REPLICATE_API_TOKEN = defineSecret('REPLICATE_API_TOKEN');
const REPLICATE_MOVIE_MODEL_VERSION = defineString('REPLICATE_MOVIE_MODEL_VERSION', {
  default: '', description: 'Backend-only Replicate model version for AUREN movie scene generation.',
});
const db = admin.firestore();
const LOCK_MS = 6 * 60 * 1000;
const MAX_ATTEMPTS = 5;

function taskId(sceneNumber) { return 'movie_sc_' + Math.max(1, Number(sceneNumber || 1)); }
function hasOutput(o) { return Boolean(o && (o.url || o.storagePath || o.externalId)); }
async function validateArtifact(o) {
  if (!hasOutput(o)) return {ok:false, reason:'missing_artifact'};
  if (o.storagePath || o.externalId) return {ok:true,referenceOnly:true};
  const url=String(o.url||'');
  if (!/^https?:\/\//i.test(url)) return {ok:false,reason:'invalid_url'};
  const controller=new AbortController(); const timer=setTimeout(()=>controller.abort(),10000);
  try {
    const r=await fetch(url,{method:'HEAD',signal:controller.signal});
    if(!r.ok)return {ok:false,reason:'http_'+r.status};
    const type=String(r.headers.get('content-type')||'').toLowerCase();
    if(type && !type.startsWith('video/'))return {ok:false,reason:'not_video',contentType:type};
    return {ok:true,contentType:type||null};
  } catch(e){ return {ok:false,reason:'artifact_unreachable'}; }
  finally{clearTimeout(timer);}
}

function sceneInput(job, scene) {
  const blueprint = job.movieBlueprint || {};
  return {
    mode: 'original_movie_scene',
    title: String(blueprint.title || job.title || '').slice(0,300),
    genre: String(blueprint.genre || '').slice(0,120),
    visualStyle: String(blueprint.visualStyle || '').slice(0,600),
    sceneNumber: Math.max(1, Number(scene.number || 1)),
    location: String(scene.location || '').slice(0,300),
    time: String(scene.time || '').slice(0,100),
    beat: String(scene.beat || '').slice(0,1200),
    visualDirection: String(scene.visualDirection || '').slice(0,1200),
    durationSeconds: Math.max(3, Math.min(60, Number(scene.durationSeconds || 8))),
  };
}

async function claim() {
  const snap = await db.collectionGroup('entertainmentCreationJobs')
    .where('mode','==','فيلم').where('movieProductionStage','in',['movie_blueprint_ready','blueprint_ready','generation','processing'])
    .limit(10).get();
  for (const item of snap.docs) {
    const ok = await db.runTransaction(async tx => {
      const fresh=await tx.get(item.ref); if(!fresh.exists)return false;
      const d=fresh.data()||{}, stage=String(d.movieProductionStage||'');
      if(!['movie_blueprint_ready','blueprint_ready','generation','processing'].includes(stage))return false;
      if(Number(d.movieWorkerLockUntilMs||0)>Date.now())return false;
      if(Number(d.movieWorkerAttempts||0)>=MAX_ATTEMPTS)return false;
      tx.update(item.ref,{movieProductionStage:'processing',movieWorkerLockUntilMs:Date.now()+LOCK_MS,
        movieWorkerAttempts:admin.firestore.FieldValue.increment(1),updatedAt:admin.firestore.FieldValue.serverTimestamp()});
      return true;
    });
    if(ok)return item.ref;
  }
  return null;
}

async function run(ref) {
  const snap=await ref.get(); if(!snap.exists)return;
  const job=snap.data()||{}, blueprint=job.movieBlueprint||{};
  if (String(job.movieProductionStage||'') === 'movie_blueprint_ready') {
    await ref.set({movieProductionStage:'blueprint_ready',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
  }
  const scenes=Array.isArray(blueprint.scenes)?blueprint.scenes.slice(0,60):[];
  if(!scenes.length) throw new Error('Movie blueprint has no scenes.');
  const version=String(REPLICATE_MOVIE_MODEL_VERSION.value()||'').trim();
  if(!version) {
    await ref.set({movieProductionStage:'waiting_provider',movieProviderState:'model_configuration_required',
      movieWorkerLockUntilMs:0,lastError:'No backend movie model version configured.',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true}); return;
  }
  const tasksRef=ref.collection('movieProductionTasks');
  const existing=await tasksRef.get();
  if(existing.empty) {
    const batch=db.batch();
    scenes.forEach(scene=>batch.set(tasksRef.doc(taskId(scene.number)),{
      jobId:ref.id,id:taskId(scene.number),type:'movie_scene',sceneNumber:Math.max(1,Number(scene.number||1)),
      input:sceneInput(job,scene),status:'queued',attempts:0,externalJobId:'',providerId:'',
      output:null,idempotencyKey:ref.id+':movie:'+taskId(scene.number),createdAt:admin.firestore.FieldValue.serverTimestamp(),
      updatedAt:admin.firestore.FieldValue.serverTimestamp(),
    }));
    await batch.commit();
    await ref.set({movieProductionStage:'generation',movieTaskCount:scenes.length,movieCompletedTaskCount:0,movieWorkerLockUntilMs:0,
      progress:20,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true}); return;
  }
  const tasks=existing.docs.map(d=>({ref:d.ref,data:d.data()||{}}));
  const pending=tasks.find(t=>['queued','processing'].includes(String(t.data.status||'')) && Number(t.data.attempts||0)<MAX_ATTEMPTS);
  if(!pending) {
    const failed=tasks.some(t=>t.data.status==='failed');
    const outputs=tasks.filter(t=>t.data.status==='output');
    if(failed) {
      await ref.set({movieProductionStage:'failed',status:'failed',movieWorkerLockUntilMs:0,lastError:'One or more movie scene tasks failed.',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    } else if(outputs.length===tasks.length) {
      const artifacts=outputs.sort((a,b)=>Number(a.data.sceneNumber||0)-Number(b.data.sceneNumber||0)).map(t=>({sceneNumber:t.data.sceneNumber,output:t.data.output||null}));
      const checks=[];
      for(const artifact of artifacts){ checks.push({sceneNumber:artifact.sceneNumber,check:await validateArtifact(artifact.output)}); }
      const bad=checks.find(x=>!x.check.ok);
      if(bad){
        await ref.set({movieProductionStage:'qc_failed',movieProductionStatus:'qc_failed',movieWorkerLockUntilMs:0,
          movieProductionQc:{version:2,result:'failed',taskCount:tasks.length,artifactChecks:checks},
          lastError:'Movie artifact QC failed for scene '+bad.sceneNumber,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
      } else {
        const assemblyId='movie_assembly_'+ref.id;
        const manifest={version:1,format:'scene_sequence_v1',assemblyId,jobId:ref.id,sceneCount:artifacts.length,
          scenes:artifacts.map(a=>({sceneNumber:a.sceneNumber,output:a.output}))};
        await ref.collection('movieAssemblies').doc(assemblyId).set({
          ...manifest,status:'manifest_ready',createdAt:admin.firestore.FieldValue.serverTimestamp(),updatedAt:admin.firestore.FieldValue.serverTimestamp(),
        },{merge:true});
        await ref.set({movieProductionStage:'ready',status:'ready',movieProductionStatus:'ready',movieWorkerLockUntilMs:0,
          movieArtifacts:artifacts,movieAssemblyId:assemblyId,movieAssemblyManifest:manifest,
          movieProductionQc:{version:2,result:'passed',taskCount:tasks.length,artifactChecks:checks},
          progress:100,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
      }
    }
    return;
  }
  const d=pending.data;
  const token=String(REPLICATE_API_TOKEN.value()||'').trim(); if(!token) throw new Error('No Replicate token configured.');
  const locked=await db.runTransaction(async tx=>{
    const fresh=await tx.get(pending.ref); const x=fresh.data()||{};
    if(!['queued','processing'].includes(String(x.status||'')) || Number(x.lockUntilMs||0)>Date.now())return false;
    tx.update(pending.ref,{status:'processing',attempts:admin.firestore.FieldValue.increment(1),lockUntilMs:Date.now()+LOCK_MS,updatedAt:admin.firestore.FieldValue.serverTimestamp()}); return true;
  });
  if(!locked)return;
  const fresh=(await pending.ref.get()).data()||{};
  if(fresh.externalJobId && fresh.providerId) {
    const polled=await pollAurenProviderJob({provider:fresh.providerId,credentials:{token},externalJobId:String(fresh.externalJobId)});
    if(polled.ok && (polled.state==='succeeded'||polled.state==='completed') && hasOutput(polled.output))
      await pending.ref.set({status:'output',output:polled.output,externalJobId:'',lockUntilMs:0,providerState:polled.state,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    else if(polled.state==='failed'||polled.state==='canceled')
      await pending.ref.set({status:Number(fresh.attempts||0)<MAX_ATTEMPTS?'queued':'failed',externalJobId:'',lockUntilMs:0,lastError:String(polled.error||'Movie provider failed').slice(0,700),updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    else await pending.ref.set({status:'processing',lockUntilMs:0,providerState:polled.state||'processing',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    return;
  }
  const result=await submitAurenProviderJob({provider:'replicate',credentials:{token,version},
    task:{input:d.input||{}},idempotencyKey:String(d.idempotencyKey||pending.ref.id)});
  if(!result.ok){await pending.ref.set({status:'queued',lockUntilMs:0,lastError:String(result.message||'Provider unavailable').slice(0,700),updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});return;}
  const output=result.result?.output, externalId=String(result.result?.externalJobId||'').trim();
  await pending.ref.set({status:hasOutput(output)?'output':externalId?'processing':'failed',output:hasOutput(output)?output:null,
    externalJobId:hasOutput(output)?'':externalId,providerId:result.providerId,providerState:result.result?.state||'starting',
    lockUntilMs:0,lastError:hasOutput(output)||externalId?'':'Provider returned no artifact.',updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
}

exports.runAurenMovieProductionWorker = onSchedule({
  schedule:'every 2 minutes',timeZone:'UTC',region:'us-central1',timeoutSeconds:120,memory:'512MiB',concurrency:1,
  secrets:[REPLICATE_API_TOKEN],
},async()=>{
  const ref=await claim(); if(!ref)return;
  try{await run(ref);}catch(error){await ref.set({movieProductionStage:'generation',movieWorkerLockUntilMs:0,lastError:String(error?.message||error).slice(0,700),updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});}
});
