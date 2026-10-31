'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const db = getFirestore();
const REGION = 'us-central1';
const TASK_COLLECTION = 'nova_tasks';
const {normalizeNovaTaskInput} = require('./nova_command_validation');
const {requireNovaOwner} = require('./nova_owner_auth');

exports.submitNovaTask = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const input = normalizeNovaTaskInput(request.data, HttpsError);
    const id = input.idempotencyKey;
    const taskRef = db.collection('users').doc(uid).collection(TASK_COLLECTION).doc(id);
    const queueRef = db.collection('nova_task_queue').doc(uid + '_' + id);
    const auditRef = db.collection('users').doc(uid).collection('nova_audit').doc();
    const result = await db.runTransaction(async (tx) => {
      const existing = await tx.get(taskRef);
      if (existing.exists) return {created:false, taskId:id, task:existing.data()};
      const task = {
        taskId:id,
        ownerUid:uid,
        type:input.type,
        prompt:input.prompt,
        metadata:input.metadata,
        requiresApproval:input.requiresApproval,
        status:input.requiresApproval ? 'awaiting_approval' : 'queued',
        executionMode:'queued_backend_worker_required',
        result:null,
        error:null,
        retryCount:0,
        createdAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
      };
      tx.create(taskRef, task);
      if (task.status === 'queued') {
        tx.create(queueRef, {ownerUid:uid, taskId:id, status:'queued', attempts:0, createdAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
      }
      tx.create(auditRef, {
        action:'nova.task.submitted',
        actorUid:uid,
        taskId:id,
        taskType:input.type,
        status:task.status,
        createdAt:FieldValue.serverTimestamp(),
      });
      return {created:true, taskId:id, task};
    });
    return {
      ok:true,
      created:result.created,
      taskId:id,
      status:result.task.status,
      requiresApproval:result.task.requiresApproval,
      executionMode:result.task.executionMode,
      message:result.task.status === 'queued'
        ? 'Task was queued; a production worker must claim it before execution.'
        : 'Task is awaiting explicit approval before side effects.',
    };
  }
);

exports.getNovaTask = onCall(
  {region:REGION, timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const taskId = String(request.data?.taskId || '').trim();
    if (!/^[A-Za-z0-9_-]{12,128}$/.test(taskId)) throw new HttpsError('invalid-argument', 'Invalid task ID.');
    const snap = await db.collection('users').doc(uid).collection(TASK_COLLECTION).doc(taskId).get();
    if (!snap.exists) throw new HttpsError('not-found', 'NOVA task not found.');
    const task = snap.data() || {};
    return {
      taskId:snap.id,
      type:task.type,
      status:task.status,
      requiresApproval:task.requiresApproval === true,
      executionMode:task.executionMode || 'unknown',
      result:task.result || null,
      error:task.error || null,
      retryCount:Number(task.retryCount) || 0,
      createdAt:task.createdAt?.toDate?.().toISOString() || null,
      updatedAt:task.updatedAt?.toDate?.().toISOString() || null,
    };
  }
);

exports.approveNovaTask = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const taskId = String(request.data?.taskId || '').trim();
    if (!/^[A-Za-z0-9_-]{12,128}$/.test(taskId)) throw new HttpsError('invalid-argument', 'Invalid task ID.');
    const taskRef = db.collection('users').doc(uid).collection(TASK_COLLECTION).doc(taskId);
    const auditRef = db.collection('users').doc(uid).collection('nova_audit').doc();
    return db.runTransaction(async (tx) => {
      const snap = await tx.get(taskRef);
      if (!snap.exists) throw new HttpsError('not-found', 'NOVA task not found.');
      const task = snap.data() || {};
      if (task.status !== 'awaiting_approval' || task.requiresApproval !== true) {
        throw new HttpsError('failed-precondition', 'Task is not awaiting approval.');
      }
      tx.update(taskRef, {
        status:'queued',
        approvedBy:uid,
        approvedAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
      });
      tx.create(db.collection('nova_task_queue').doc(uid + '_' + taskId), {
        ownerUid:uid, taskId, status:'queued', attempts:0,
        createdAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp(),
      });
      tx.create(auditRef, {
        action:'nova.task.approved',
        actorUid:uid,
        taskId,
        taskType:String(task.type || ''),
        createdAt:FieldValue.serverTimestamp(),
      });
      return {ok:true, taskId, status:'queued', executionMode:task.executionMode || 'queued_backend_worker_required'};
    });
  }
);

exports.cancelNovaTask = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const taskId = String(request.data?.taskId || '').trim();
    if (!/^[A-Za-z0-9_-]{12,128}$/.test(taskId)) throw new HttpsError('invalid-argument', 'Invalid task ID.');
    const taskRef = db.collection('users').doc(uid).collection(TASK_COLLECTION).doc(taskId);
    const queueRef = db.collection('nova_task_queue').doc(uid + '_' + taskId);
    const auditRef = db.collection('users').doc(uid).collection('nova_audit').doc();
    return db.runTransaction(async (tx) => {
      const snap = await tx.get(taskRef);
      if (!snap.exists) throw new HttpsError('not-found', 'NOVA task not found.');
      const queueSnap = await tx.get(queueRef);
      const task = snap.data() || {};
      if (!['queued','awaiting_approval'].includes(task.status)) {
        throw new HttpsError('failed-precondition', 'Only queued or approval-pending tasks can be cancelled.');
      }
      tx.update(taskRef, {status:'cancelled', cancelledAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
      if (queueSnap.exists && queueSnap.data()?.status === 'queued') {
        tx.update(queueRef, {status:'cancelled', updatedAt:FieldValue.serverTimestamp()});
      }
      tx.create(auditRef, {
        action:'nova.task.cancelled',
        actorUid:uid,
        taskId,
        taskType:String(task.type || ''),
        createdAt:FieldValue.serverTimestamp(),
      });
      return {ok:true, taskId, status:'cancelled'};
    });
  }
);

exports.listNovaTasks = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireNovaOwner(request);
    const limit = Math.min(50, Math.max(1, Number(request.data?.limit) || 20));
    const snap = await db.collection('users').doc(uid).collection(TASK_COLLECTION)
      .orderBy('createdAt', 'desc').limit(limit).get();
    return {tasks:snap.docs.map((doc) => {
      const task = doc.data() || {};
      return {
        taskId:doc.id,
        type:task.type,
        prompt:task.prompt,
        status:task.status,
        requiresApproval:task.requiresApproval === true,
        executionMode:task.executionMode || 'unknown',
        result:task.result || null,
        error:task.error || null,
        retryCount:Number(task.retryCount) || 0,
        createdAt:task.createdAt?.toDate?.().toISOString() || null,
      };
    })};
  }
);
