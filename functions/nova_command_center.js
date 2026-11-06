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
const {resolveDependencyState} = require('./nova_task_dependency_policy');

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

      const dependencyStatuses = [];
      for (const dependencyId of input.dependsOnTaskIds) {
        const dependencyRef = db.collection('users').doc(uid).collection(TASK_COLLECTION).doc(dependencyId);
        const dependencySnap = await tx.get(dependencyRef);
        if (!dependencySnap.exists) {
          throw new HttpsError('not-found', 'A prerequisite NOVA task was not found: ' + dependencyId);
        }
        dependencyStatuses.push(String(dependencySnap.data()?.status || 'unknown'));
      }
      const dependencyState = resolveDependencyState(dependencyStatuses, input.requiresApproval);
      if (dependencyState.status === 'blocked') {
        throw new HttpsError('failed-precondition', 'A prerequisite task has already failed or been cancelled.');
      }

      const task = {
        taskId:id,
        ownerUid:uid,
        type:input.type,
        prompt:input.prompt,
        metadata:input.metadata,
        requiresApproval:input.requiresApproval,
        dependsOnTaskIds:input.dependsOnTaskIds,
        dependencyPolicy:'all_successful',
        status:dependencyState.status,
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
        dependsOnTaskIds:input.dependsOnTaskIds,
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
      dependsOnTaskIds:result.task.dependsOnTaskIds || [],
      executionMode:result.task.executionMode,
      message:result.task.status === 'queued'
        ? 'Task was queued; a production worker must claim it before execution.'
        : result.task.status === 'waiting_for_dependencies'
          ? 'Task is waiting until every prerequisite succeeds.'
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
      if (!['queued','awaiting_approval','waiting_for_dependencies'].includes(task.status)) {
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
        dependsOnTaskIds:Array.isArray(task.dependsOnTaskIds) ? task.dependsOnTaskIds : [],
        createdAt:task.createdAt?.toDate?.().toISOString() || null,
      };
    })};
  }
);



// Advance dependent tasks after a prerequisite reaches a terminal state.
// Each dependent transition is transactionally idempotent; approval-gated work
// is moved to awaiting_approval and is never inserted into the queue automatically.
exports.advanceNovaTaskDependents = onDocumentUpdated(
  {document:'users/{uid}/nova_tasks/{taskId}', region:REGION, timeoutSeconds:60, memory:'256MiB'},
  async (event) => {
    const before = event.data?.before?.data() || {};
    const after = event.data?.after?.data() || {};
    if (String(before.status || '') === String(after.status || '')) return;

    const uid = String(event.params.uid || '');
    const completedTaskId = String(event.params.taskId || '');
    if (!uid || !completedTaskId) return;

    const userTasks = db.collection('users').doc(uid).collection(TASK_COLLECTION);
    let cursor = null;
    while (true) {
      let dependentQuery = userTasks
        .where('dependsOnTaskIds', 'array-contains', completedTaskId)
        .limit(50);
      if (cursor) dependentQuery = dependentQuery.startAfter(cursor);
      const dependents = await dependentQuery.get();
      if (dependents.empty) break;

      for (const dependentDoc of dependents.docs) {
      const dependentRef = dependentDoc.ref;
      const dependentId = dependentDoc.id;
      const dependencyIds = Array.isArray(dependentDoc.data()?.dependsOnTaskIds)
        ? dependentDoc.data().dependsOnTaskIds
        : [];
      const queueRef = db.collection('nova_task_queue').doc(uid + '_' + dependentId);
      const auditRef = db.collection('users').doc(uid).collection('nova_audit').doc();

      await db.runTransaction(async (tx) => {
        const current = await tx.get(dependentRef);
        if (!current.exists || current.data()?.status !== 'waiting_for_dependencies') return;

        const dependencyStatuses = [];
        for (const dependencyId of dependencyIds) {
          const dependencyRef = userTasks.doc(String(dependencyId));
          const dependencySnap = await tx.get(dependencyRef);
          dependencyStatuses.push(dependencySnap.exists
            ? String(dependencySnap.data()?.status || 'unknown')
            : 'blocked');
        }
        const queueSnap = await tx.get(queueRef);
        const task = current.data() || {};
        const resolution = resolveDependencyState(dependencyStatuses, task.requiresApproval === true);
        if (resolution.status === 'waiting_for_dependencies') return;

        tx.update(dependentRef, {
          status:resolution.status,
          error:resolution.error,
          dependencyResolvedAt:FieldValue.serverTimestamp(),
          updatedAt:FieldValue.serverTimestamp(),
        });
        if (resolution.status === 'queued' && !queueSnap.exists) {
          tx.create(queueRef, {
            ownerUid:uid,
            taskId:dependentId,
            status:'queued',
            attempts:0,
            createdAt:FieldValue.serverTimestamp(),
            updatedAt:FieldValue.serverTimestamp(),
          });
        }
        tx.create(auditRef, {
          action:resolution.status === 'queued'
            ? 'nova.task.dependencies_satisfied'
            : resolution.status === 'awaiting_approval'
              ? 'nova.task.dependencies_satisfied_approval_required'
              : 'nova.task.blocked_dependency_failed',
          actorUid:'nova_dependency_engine',
          taskId:dependentId,
          dependsOnTaskIds:dependencyIds,
          status:resolution.status,
          createdAt:FieldValue.serverTimestamp(),
        });
      });
      }
      cursor = dependents.docs[dependents.docs.length - 1];
      if (dependents.size < 50) break;
    }
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
