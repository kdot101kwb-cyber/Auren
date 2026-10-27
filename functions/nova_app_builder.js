'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {randomUUID, createHash} = require('node:crypto');

const db = getFirestore();
const REGION = 'us-central1';
const TASKS = 'nova_build_jobs';
const {validateBuildRequest} = require('./nova_app_builder_validation');
const {buildRunnerPlan} = require('./nova_build_runner_policy');

exports.submitNovaBuildJob = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to create a build job.');
    const input = validateBuildRequest(request.data);
    const id = randomUUID().replace(/-/g, '');
    const ref = db.collection('users').doc(uid).collection(TASKS).doc(id);
    const audit = db.collection('users').doc(uid).collection('nova_audit').doc();
    const executionPlan = buildRunnerPlan(input.stack);
    const planHash = createHash('sha256').update(JSON.stringify(executionPlan)).digest('hex');
    const job = {
      jobId:id, ownerUid:uid, ...input, executionPlan, planHash, status:'queued',
      stage:'waiting_for_runner', attempts:0, maxAttempts:3,
      acceptanceCriteria: Array.isArray(request.data?.acceptanceCriteria)
        ? request.data.acceptanceCriteria.filter(x => typeof x === 'string').slice(0,20).map(x => x.slice(0,300))
        : [],
      approvalRequiredFor:['deploy','publish','merge','production_secret_change'],
      createdAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp(),
    };
    await db.runTransaction(async tx => {
      tx.create(ref, job);
      tx.create(db.collection('nova_build_queue').doc(id), {
        jobId:id, ownerUid:uid, status:'queued', attempts:0,
        createdAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp(),
      });
      tx.create(audit, {
        action:'nova.build_job.submitted', actorUid:uid, jobId:id, taskType:input.type,
        stack:input.stack, createdAt:FieldValue.serverTimestamp(),
      });
    });
    return {
      jobId:id, status:'queued', stage:'waiting_for_runner',
      executionPlan, planHash,
      message:'تم تسجيل المهمة. لن يبدأ بناء الكود حتى يتصل عامل بناء معزول بالطابور.',
    };
  }
);

exports.getNovaBuildJob = onCall(
  {region:REGION, timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true},
  async request => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to inspect build jobs.');
    const jobId = String(request.data?.jobId || '');
    if (!/^[a-f0-9]{32}$/.test(jobId)) throw new HttpsError('invalid-argument', 'Invalid build job ID.');
    const snap = await db.collection('users').doc(uid).collection(TASKS).doc(jobId).get();
    if (!snap.exists) throw new HttpsError('not-found', 'Build job not found.');
    const job = snap.data();
    return {
      jobId:snap.id, type:job.type, stack:job.stack, status:job.status, stage:job.stage,
      attempts:job.attempts, maxAttempts:job.maxAttempts, summary:job.summary || null,
      executionPlan:job.executionPlan || null, planHash:job.planHash || null,
      executionApproval:job.executionApproval || null,
      checks:job.checks || [], artifacts:job.artifacts || [], error:job.error || null,
      createdAt:job.createdAt?.toDate?.().toISOString() || null,
      updatedAt:job.updatedAt?.toDate?.().toISOString() || null,
    };
  }
);


exports.approveNovaBuildPlan = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async request => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to approve a build plan.');
    const jobId = String(request.data?.jobId || '');
    const suppliedPlanHash = String(request.data?.planHash || '');
    if (!/^[a-f0-9]{32}$/.test(jobId)) throw new HttpsError('invalid-argument', 'Invalid build job ID.');
    if (!/^[a-f0-9]{64}$/.test(suppliedPlanHash)) throw new HttpsError('invalid-argument', 'Invalid plan fingerprint.');

    const jobRef = db.collection('users').doc(uid).collection(TASKS).doc(jobId);
    const queueRef = db.collection('nova_build_queue').doc(jobId);
    const auditRef = db.collection('users').doc(uid).collection('nova_audit').doc();
    const approvedAt = new Date().toISOString();

    await db.runTransaction(async tx => {
      const snap = await tx.get(jobRef);
      if (!snap.exists) throw new HttpsError('not-found', 'Build job not found.');
      const job = snap.data();
      if (job.ownerUid !== uid) throw new HttpsError('permission-denied', 'Only the job owner can approve this plan.');
      if (job.status !== 'queued' || job.stage !== 'waiting_for_runner') {
        throw new HttpsError('failed-precondition', 'This build job is not waiting for approval.');
      }
      if (!job.executionPlan || job.executionPlan.executable !== false ||
          job.executionPlan.status !== 'waiting_for_isolated_runner') {
        throw new HttpsError('failed-precondition', 'There is no supported isolated-runner plan to approve.');
      }
      const actualHash = createHash('sha256').update(JSON.stringify(job.executionPlan)).digest('hex');
      if (job.planHash !== actualHash || suppliedPlanHash !== actualHash) {
        throw new HttpsError('failed-precondition', 'The plan changed. Refresh and review it again before approval.');
      }
      if (job.executionApproval?.approved === true) {
        if (job.executionApproval.planHash !== actualHash || job.executionApproval.approvedBy !== uid) {
          throw new HttpsError('failed-precondition', 'Existing approval does not match this plan.');
        }
        return;
      }
      const approval = {approved:true, approvedBy:uid, planHash:actualHash, approvedAt};
      tx.update(jobRef, {executionApproval:approval, updatedAt:FieldValue.serverTimestamp()});
      tx.set(queueRef, {executionApproval:approval, planHash:actualHash, updatedAt:FieldValue.serverTimestamp()}, {merge:true});
      tx.create(auditRef, {
        action:'nova.build_plan.approved', actorUid:uid, jobId,
        planHash:actualHash, createdAt:FieldValue.serverTimestamp(),
      });
    });

    return {
      jobId, approved:true, planHash:suppliedPlanHash,
      message:'تمت الموافقة على بصمة الخطة المحددة فقط. لن يبدأ التنفيذ حتى يتصل عامل معزول موثوق.',
    };
  }
);

exports.__testables = {validateBuildRequest};
