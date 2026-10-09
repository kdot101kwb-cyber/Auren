'use strict';

const admin = require('firebase-admin');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const db = admin.firestore();

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
    return {id:snap.id, type, ...snap.data()};
  }
);

exports.listAurenSupplierRequests = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = requireAuth(request);
    const status = clean(request.data?.status, 40).toLowerCase();
    const limit = Math.min(Math.max(Number(request.data?.limit) || 30, 1), 100);
    const [contacts, rfqs] = await Promise.all([
      db.collection('users').doc(uid).collection('supplier_contact_requests').orderBy('createdAt','desc').limit(limit).get(),
      db.collection('users').doc(uid).collection('supplier_rfqs').orderBy('createdAt','desc').limit(limit).get(),
    ]);
    const items = [
      ...contacts.docs.map(d=>({id:d.id,type:'contact',...d.data()})),
      ...rfqs.docs.map(d=>({id:d.id,type:'rfq',...d.data()})),
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
      if (!fresh.exists) throw new HttpsError('not-found','Supplier request not found.');
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
      tx.set(globalRef, update, {merge:true});
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
    const currentStatus = String(data.status || 'draft').toLowerCase();
    const transitions = {
      draft: new Set(['waiting_response', 'failed', 'cancelled']),
      waiting_response: new Set(['replied', 'completed', 'failed', 'cancelled']),
      replied: new Set(['completed', 'cancelled']),
      failed: new Set(['cancelled']),
      cancelled: new Set(),
      completed: new Set(),
    };
    if (nextStatus !== currentStatus && !transitions[currentStatus]?.has(nextStatus)) {
      throw new HttpsError('failed-precondition', 'Invalid supplier request status transition.');
    }
    if (nextStatus === 'replied' && data.externalDispatch !== true) {
      throw new HttpsError('failed-precondition','A request that was not externally dispatched cannot be marked as replied.');
    }
    const update = {
      status: nextStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(nextStatus === 'replied' ? {repliedAt: admin.firestore.FieldValue.serverTimestamp()} : {}),
      ...(nextStatus === 'completed' ? {completedAt: admin.firestore.FieldValue.serverTimestamp()} : {}),
    };
    await db.runTransaction(async tx => {
      const fresh = await tx.get(ref);
      if (!fresh.exists) throw new HttpsError('not-found','Supplier request not found.');
      const freshData = fresh.data() || {};
      const freshStatus = String(freshData.status || 'draft').toLowerCase();
      if (freshStatus !== currentStatus) {
        throw new HttpsError('aborted','Supplier request changed; refresh and try again.');
      }
      if (nextStatus !== freshStatus && !transitions[freshStatus]?.has(nextStatus)) {
        throw new HttpsError('failed-precondition','Invalid supplier request status transition.');
      }
      if (nextStatus === 'replied' && freshData.externalDispatch !== true) {
        throw new HttpsError('failed-precondition','A request that was not externally dispatched cannot be marked as replied.');
      }
      tx.set(ref, update, {merge:true});
      tx.set(db.collection(collectionFor(type)).doc(requestId), update, {merge:true});
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
      if (!fresh.exists) throw new HttpsError('not-found','Supplier request not found.');
      const data = fresh.data() || {};
      const currentStatus = String(data.status || '').toLowerCase();
      if (!['failed','cancelled'].includes(currentStatus)) {
        throw new HttpsError('failed-precondition','Only failed or cancelled requests can be retried.');
      }
      const retryCount = Number(data.retryCount || 0) + 1;
      if (retryCount > 5) throw new HttpsError('resource-exhausted','Retry limit reached.');
      const update = {
        status:'draft', retryCount, externalDispatch:false,
        lastError:'', retriedAt:admin.firestore.FieldValue.serverTimestamp(), updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      };
      tx.set(ref, update, {merge:true});
      tx.set(globalRef, update, {merge:true});
      return {retryCount, matchFlowId:data.matchFlowId || ''};
    });
    await updateMatchFlow(uid,retry.matchFlowId,'active',{retryCount:retry.retryCount});
    return {ok:true,id:requestId,type,status:'draft',retryCount:retry.retryCount};
  }
);
