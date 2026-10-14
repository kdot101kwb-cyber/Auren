'use strict';

const admin = require('firebase-admin');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const db = admin.firestore();
const lifecycle = require('./supplier_request_lifecycle');

const clean = (v, max) => String(v ?? '').trim().slice(0, max);

function requireAuth(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
  return uid;
}

function collectionFor(type) {
  return type === 'rfq' ? 'supplier_rfqs' : 'supplier_contact_requests';
}

function matchFlowRef(uid, flowId) {
  const id = clean(flowId, 180);
  if (!id) return null;
  return db.collection('users').doc(uid).collection('match_action_flows').doc(id);
}

async function updateMatchFlow(uid, flowId, status, extra = {}) {
  const ref = matchFlowRef(uid, flowId);
  if (!ref) return;
  const snap = await ref.get();
  if (!snap.exists) return;
  await ref.set({
    status,
    supplierWorkflowStatus: status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    ...extra,
  }, {merge:true});
}

exports.getAurenSupplierRequest = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireAuth(request);
    const requestId = clean(request.data?.requestId, 128);
    const type = clean(request.data?.type, 20).toLowerCase();
    if (!requestId || !['contact','rfq'].includes(type)) throw new HttpsError('invalid-argument','requestId and type are required.');
    const snap = await db.collection('users').doc(uid).collection(collectionFor(type)).doc(requestId).get();
    if (!snap.exists) throw new HttpsError('not-found','Supplier request not found.');
    return {...snap.data(), id:snap.id, type};
  }
);

exports.listAurenSupplierRequests = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireAuth(request);
    const status = clean(request.data?.status, 40).toLowerCase();
    const requestedLimit = Number(request.data?.limit);
    const limit = Number.isFinite(requestedLimit)
      ? Math.min(Math.max(Math.floor(requestedLimit), 1), 100)
      : 30;
    const [contacts, rfqs] = await Promise.all([
      db.collection('users').doc(uid).collection('supplier_contact_requests').orderBy('createdAt','desc').limit(limit).get(),
      db.collection('users').doc(uid).collection('supplier_rfqs').orderBy('createdAt','desc').limit(limit).get(),
    ]);
    const items = [
      ...contacts.docs.map(d=>({...d.data(),id:d.id,type:'contact'})),
      ...rfqs.docs.map(d=>({...d.data(),id:d.id,type:'rfq'})),
    ].filter(x=>!status || String(x.status||'').toLowerCase()===status)
      .sort((a,b)=>((b.createdAt?.toMillis?.()||0)-(a.createdAt?.toMillis?.()||0)))
      .slice(0,limit);
    return {requests:items,count:items.length};
  }
);

exports.cancelAurenSupplierRequest = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireAuth(request);
    const requestId = clean(request.data?.requestId, 128);
    const type = clean(request.data?.type, 20).toLowerCase();
    if (!requestId || !['contact','rfq'].includes(type)) throw new HttpsError('invalid-argument','requestId and type are required.');
    const ref = db.collection('users').doc(uid).collection(collectionFor(type)).doc(requestId);
    const globalRef = db.collection(collectionFor(type)).doc(requestId);
    const cancelled = await db.runTransaction(async tx => {
      const fresh = await tx.get(ref);
      const globalFresh = await tx.get(globalRef);
      if (!fresh.exists) throw new HttpsError('not-found','Supplier request not found.');
      if (globalFresh.exists && globalFresh.data()?.requesterUid !== uid) throw new HttpsError('permission-denied','Supplier request mirror belongs to another account.');
      const data = fresh.data() || {};
      const currentStatus = String(data.status || 'draft').toLowerCase();
      if (['completed','cancelled'].includes(currentStatus)) {
        throw new HttpsError('failed-precondition','Request cannot be cancelled in its current state.');
      }
      const update = {
        status:'cancelled',
        cancelledAt:admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      };
      tx.set(ref, update, {merge:true});
      if (globalFresh.exists) tx.set(globalRef, update, {merge:true});
      return {matchFlowId:data.matchFlowId || ''};
    });
    await updateMatchFlow(uid,cancelled.matchFlowId,'cancelled',{completionReason:'cancelled'});
    return {ok:true,id:requestId,type,status:'cancelled'};
  }
);


exports.updateAurenSupplierRequestStatus = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireAuth(request);
    const requestId = clean(request.data?.requestId, 128);
    const type = clean(request.data?.type, 20).toLowerCase();
    const nextStatus = clean(request.data?.status, 40).toLowerCase();
    const allowed = new Set(['draft','waiting_response','replied','completed','failed','cancelled']);
    if (!requestId || !['contact','rfq'].includes(type) || !allowed.has(nextStatus)) {
      throw new HttpsError('invalid-argument','requestId, type and a valid status are required.');
    }
    const ref = db.collection('users').doc(uid).collection(collectionFor(type)).doc(requestId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError('not-found','Supplier request not found.');
    const data = snap.data() || {};
    const currentStatus = lifecycle.normalizeStatus(data.status);
    if (!lifecycle.isAllowedTransition(currentStatus, nextStatus)) {
      throw new HttpsError('failed-precondition', 'Invalid supplier request status transition.');
    }
    if (lifecycle.requiresExternalDispatch(nextStatus, data.externalDispatch)) {
      throw new HttpsError('failed-precondition','A request that was not externally dispatched cannot be marked as awaiting or receiving a supplier response.');
    }
    const update = {
      status: nextStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(nextStatus === 'replied' ? {repliedAt: admin.firestore.FieldValue.serverTimestamp()} : {}),
      ...(nextStatus === 'completed' ? {completedAt: admin.firestore.FieldValue.serverTimestamp()} : {}),
    };
    await db.runTransaction(async tx => {
      const fresh = await tx.get(ref);
      const globalFresh = await tx.get(db.collection(collectionFor(type)).doc(requestId));
      if (!fresh.exists) throw new HttpsError('not-found','Supplier request not found.');
      if (globalFresh.exists && globalFresh.data()?.requesterUid !== uid) throw new HttpsError('permission-denied','Supplier request mirror belongs to another account.');
      const freshData = fresh.data() || {};
      const freshStatus = String(freshData.status || 'draft').toLowerCase();
      if (freshStatus !== currentStatus) {
        throw new HttpsError('aborted','Supplier request changed; refresh and try again.');
      }
      if (!lifecycle.isAllowedTransition(freshStatus, nextStatus)) {
        throw new HttpsError('failed-precondition','Invalid supplier request status transition.');
      }
      if (lifecycle.requiresExternalDispatch(nextStatus, freshData.externalDispatch)) {
        throw new HttpsError('failed-precondition','A request that was not externally dispatched cannot be marked as awaiting or receiving a supplier response.');
      }
      tx.set(ref, update, {merge:true});
      if (globalFresh.exists) tx.set(db.collection(collectionFor(type)).doc(requestId), update, {merge:true});
    });
    await updateMatchFlow(uid, data.matchFlowId, nextStatus, {
      supplierRequestId: requestId,
      supplierRequestType: type,
    });
    return {ok:true,id:requestId,type,status:nextStatus};
  }
);

exports.retryAurenSupplierRequest = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireAuth(request);
    const requestId = clean(request.data?.requestId, 128);
    const type = clean(request.data?.type, 20).toLowerCase();
    if (!requestId || !['contact','rfq'].includes(type)) throw new HttpsError('invalid-argument','requestId and type are required.');
    const ref = db.collection('users').doc(uid).collection(collectionFor(type)).doc(requestId);
    const globalRef = db.collection(collectionFor(type)).doc(requestId);
    const retry = await db.runTransaction(async tx => {
      const fresh = await tx.get(ref);
      const globalFresh = await tx.get(globalRef);
      if (!fresh.exists) throw new HttpsError('not-found','Supplier request not found.');
      if (globalFresh.exists && globalFresh.data()?.requesterUid !== uid) throw new HttpsError('permission-denied','Supplier request mirror belongs to another account.');
      const data = fresh.data() || {};
      const currentStatus = String(data.status || '').toLowerCase();
      if (!['failed','cancelled'].includes(currentStatus)) {
        throw new HttpsError('failed-precondition','Only failed or cancelled requests can be retried.');
      }
      const retry = lifecycle.nextRetryCount(data.retryCount);
      if (!retry.ok && retry.reason === 'invalid-count') {
        throw new HttpsError('failed-precondition','Stored retry count is invalid.');
      }
      if (!retry.ok && retry.reason === 'limit-reached') {
        throw new HttpsError('resource-exhausted','Retry limit reached.');
      }
      const retryCount = retry.count;
      const update = {
        status:'draft', retryCount, externalDispatch:false,
        lastError:'', retriedAt:admin.firestore.FieldValue.serverTimestamp(), updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      };
      tx.set(ref, update, {merge:true});
      if (globalFresh.exists) tx.set(globalRef, update, {merge:true});
      return {retryCount, matchFlowId:data.matchFlowId || ''};
    });
    await updateMatchFlow(uid,retry.matchFlowId,'active',{retryCount:retry.retryCount});
    return {ok:true,id:requestId,type,status:'draft',retryCount:retry.retryCount};
  }
);
