'use strict';

const admin = require('firebase-admin');
const db = admin.firestore();

function clean(value, max) {
  return String(value || '').trim().slice(0, max);
}

async function updateMatchFlow(uid, flowId, status, extra = {}) {
  const id = clean(flowId, 180);
  if (!id) return;
  const ref = db.collection('users').doc(uid).collection('match_action_flows').doc(id);
  const snap = await ref.get();
  if (!snap.exists) return;
  await ref.set({
    supplierWorkflowStatus: status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    ...extra,
  }, {merge:true});
}

async function createSupplierWorkflow({uid, operation, payload, idempotencyKey}) {
  const supplierId = clean(payload?.supplierId, 128);
  const matchFlowId = clean(payload?.matchFlowId, 180);
  if (!supplierId) { const error = new Error('Supplier is required.'); error.code = 'validation'; throw error; }
  const stableKey = clean(idempotencyKey, 128);
  if (!stableKey) { const error = new Error('Idempotency key is required.'); error.code = 'validation'; throw error; }

  const collections = ['auren_suppliers', 'auren_exporters', 'auren_importers', 'auren_manufacturers'];
  let supplier;
  for (const collection of collections) {
    const snapshot = await db.collection(collection).doc(supplierId).get();
    if (snapshot.exists) { supplier = snapshot.data() || {}; break; }
  }
  if (!supplier) { const error = new Error('Supplier not found.'); error.code = 'validation'; throw error; }
  const supplierName = clean(supplier.name || supplier.companyName || supplierId, 200);
  const common = {
    supplierId, supplierName, requesterUid: uid, matchFlowId,
    status:'draft', externalDispatch:false,
    createdAt:admin.firestore.FieldValue.serverTimestamp(),
    updatedAt:admin.firestore.FieldValue.serverTimestamp(),
  };

  if (operation === 'contact') {
    const message = clean(payload?.message, 5000);
    if (!message) { const error = new Error('Message is required.'); error.code = 'validation'; throw error; }
    const ref = db.collection('supplier_contact_requests').doc(stableKey);
    const userRef = db.collection('users').doc(uid).collection('supplier_contact_requests').doc(ref.id);
    const data = {
      ...common, message,
      channel: clean(payload?.channel || 'draft', 40),
      contactEmail: supplier.email || supplier.contactEmail || null,
      contactPhone: supplier.phone || supplier.contactPhone || null,
    };
    const outcome = await db.runTransaction(async tx => {
      const existing = await tx.get(ref);
      const existingUser = await tx.get(userRef);
      if (existing.exists) {
        const previous = existing.data() || {};
        if (previous.requesterUid !== uid) {
          const error = new Error('Idempotency key is already used by another account.'); error.code = 'permission-denied'; throw error;
        }
        if (!existingUser.exists) tx.set(userRef, previous);
        return {created:false, status:previous.status || 'draft', supplierId:previous.supplierId || supplierId, externalDispatch:previous.externalDispatch === true, matchFlowId:previous.matchFlowId || matchFlowId};
      }
      tx.create(ref,data);
      tx.create(userRef,data);
      return {created:true,status:'draft',supplierId,externalDispatch:false,matchFlowId};
    });
    if (!outcome.created) return {type:'supplier_contact_draft_created', requestId:ref.id, ...outcome};
    // Creating a local draft is not evidence that the supplier was contacted.
    await updateMatchFlow(uid,matchFlowId,'active',{supplierRequestId:ref.id,supplierRequestType:'contact',supplierWorkflowStatus:'draft'});
    return {type:'supplier_contact_draft_created', requestId:ref.id, supplierId, status:'draft', externalDispatch:false, matchFlowId};
  }

  if (operation === 'rfq') {
    const product = clean(payload?.product, 300);
    const quantity = clean(payload?.quantity, 80);
    if (!product || !quantity) { const error = new Error('Product and quantity are required.'); error.code = 'validation'; throw error; }
    const ref = db.collection('supplier_rfqs').doc(stableKey);
    const userRef = db.collection('users').doc(uid).collection('supplier_rfqs').doc(ref.id);
    const data = {
      ...common, product, quantity,
      unit: clean(payload?.unit, 40),
      currency: clean(payload?.currency, 3).toUpperCase(),
      notes: clean(payload?.notes, 3000),
    };
    const outcome = await db.runTransaction(async tx => {
      const existing = await tx.get(ref);
      const existingUser = await tx.get(userRef);
      if (existing.exists) {
        const previous = existing.data() || {};
        if (previous.requesterUid !== uid) {
          const error = new Error('Idempotency key is already used by another account.'); error.code = 'permission-denied'; throw error;
        }
        if (!existingUser.exists) tx.set(userRef, previous);
        return {created:false,status:previous.status || 'draft',supplierId:previous.supplierId || supplierId,externalDispatch:previous.externalDispatch === true,matchFlowId:previous.matchFlowId || matchFlowId};
      }
      tx.create(ref,data);
      tx.create(userRef,data);
      return {created:true,status:'draft',supplierId,externalDispatch:false,matchFlowId};
    });
    if (!outcome.created) return {type:'supplier_rfq_created', rfqId:ref.id, ...outcome};
    // A saved RFQ draft is not sent to the supplier; keep the flow active.
    await updateMatchFlow(uid,matchFlowId,'active',{supplierRequestId:ref.id,supplierRequestType:'rfq',supplierWorkflowStatus:'draft'});
    return {type:'supplier_rfq_created', rfqId:ref.id, supplierId, status:'draft', externalDispatch:false, matchFlowId};
  }

  { const error = new Error('Unsupported supplier operation.'); error.code = 'validation'; throw error; }
}

module.exports = {createSupplierWorkflow};
