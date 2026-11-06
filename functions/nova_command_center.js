'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {onDocumentCreated, onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {createHash} = require('node:crypto');
const {buildNovaMilestoneNotification, buildNovaPushData, shouldNotifyNovaCreation, shouldNotifyNovaTransition} = require('./nova_notification_policy');

const db = getFirestore();
const REGION = 'us-central1';
const TASK_COLLECTION = 'nova_tasks';
const {normalizeNovaTaskInput} = require('./nova_command_validation');

exports.submitNovaTask = onCall(
  {region:REGION, timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to submit NOVA tasks.');
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
        workflowSteps:input.metadata.workflowSteps || [],
        workflowProgress:0,
        workflowResults:[],
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
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to view NOVA tasks.');
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
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to approve NOVA tasks.');
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
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to cancel NOVA tasks.');
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
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to view NOVA tasks.');
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
        workflowProgress:Number(task.workflowProgress) || 0,
        workflowTotal:1 + (Array.isArray(task.workflowSteps) ? task.workflowSteps.length : 0),
        createdAt:task.createdAt?.toDate?.().toISOString() || null,
      };
    })};
  }
);


// Device tokens are private server-owned records; clients can only register or
// remove their own current FCM token through these App Check protected callables.
function novaDeviceTokenId(token) {
  return createHash('sha256').update(token).digest('hex');
}

exports.registerNovaDeviceToken = onCall(
  {region:REGION, timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to register NOVA notifications.');
    const token = String(request.data?.token || '').trim();
    const platform = String(request.data?.platform || '').trim().toLowerCase();
    if (token.length < 20 || token.length > 4096) {
      throw new HttpsError('invalid-argument', 'Invalid FCM registration token.');
    }
    if (!['android', 'ios'].includes(platform)) {
      throw new HttpsError('invalid-argument', 'Unsupported notification platform.');
    }
    const ref = db.collection('users').doc(uid).collection('nova_devices').doc(novaDeviceTokenId(token));
    await ref.set({
      token,
      platform,
      enabled: true,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    }, {merge:true});
    return {ok:true, registered:true};
  }
);

exports.unregisterNovaDeviceToken = onCall(
  {region:REGION, timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to unregister NOVA notifications.');
    const token = String(request.data?.token || '').trim();
    if (token.length < 20 || token.length > 4096) {
      throw new HttpsError('invalid-argument', 'Invalid FCM registration token.');
    }
    await db.collection('users').doc(uid).collection('nova_devices')
      .doc(novaDeviceTokenId(token)).delete();
    return {ok:true, registered:false};
  }
);

// Send a push notification only when a task enters a meaningful milestone.
// No task prompt or private result is included in the push payload.
exports.notifyNovaTaskMilestone = onDocumentUpdated(
  {document:'users/{uid}/nova_tasks/{taskId}', region:REGION, timeoutSeconds:30, memory:'256MiB'},
  async (event) => {
    const before = event.data?.before?.data() || {};
    const after = event.data?.after?.data() || {};
    const previousStatus = String(before.status || '');
    const status = String(after.status || '');
    if (!shouldNotifyNovaTransition(previousStatus, status)) return;

    const notification = buildNovaMilestoneNotification(status, after.type);
    if (!notification) return;

    const devices = await db.collection('users').doc(String(event.params.uid))
      .collection('nova_devices').where('enabled', '==', true).limit(100).get();
    const tokens = devices.docs
      .map((doc) => ({doc, token:String(doc.data()?.token || '').trim()}))
      .filter((item) => item.token.length >= 20);
    if (tokens.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens:tokens.map((item) => item.token),
      notification,
      data:buildNovaPushData(event.params.taskId, status, after.type),
      android:{
        priority:'high',
        notification:{sound:'default'},
      },
    });

    const staleRefs = [];
    response.responses.forEach((result, index) => {
      const code = result.error?.code || '';
      if (code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token') {
        staleRefs.push(tokens[index].doc.ref);
      }
    });
    for (let index = 0; index < staleRefs.length; index += 450) {
      const batch = db.batch();
      staleRefs.slice(index, index + 450).forEach((ref) => batch.delete(ref));
      await batch.commit();
    }
  }
);


// A task created in the approval queue has no update event yet. Notify the
// owner on creation so a sensitive action never waits silently for approval.
exports.notifyNovaApprovalRequired = onDocumentCreated(
  {document:'users/{uid}/nova_tasks/{taskId}', region:REGION, timeoutSeconds:30, memory:'256MiB'},
  async (event) => {
    const task = event.data?.data() || {};
    if (!shouldNotifyNovaCreation(String(task.status || ''))) return;
    const notification = buildNovaMilestoneNotification('awaiting_approval', task.type);
    if (!notification) return;
    const devices = await db.collection('users').doc(String(event.params.uid))
      .collection('nova_devices').where('enabled', '==', true).limit(100).get();
    const tokens = devices.docs
      .map((doc) => ({doc, token:String(doc.data()?.token || '').trim()}))
      .filter((item) => item.token.length >= 20);
    if (tokens.length === 0) return;
    const response = await getMessaging().sendEachForMulticast({
      tokens:tokens.map((item) => item.token),
      notification,
      data:buildNovaPushData(event.params.taskId, 'awaiting_approval', task.type),
      android:{priority:'high', notification:{sound:'default'}},
    });
    const staleRefs = [];
    response.responses.forEach((result, index) => {
      const code = result.error?.code || '';
      if (code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token') staleRefs.push(tokens[index].doc.ref);
    });
    for (let index = 0; index < staleRefs.length; index += 450) {
      const batch = db.batch();
      staleRefs.slice(index, index + 450).forEach((ref) => batch.delete(ref));
      await batch.commit();
    }
  }
);
