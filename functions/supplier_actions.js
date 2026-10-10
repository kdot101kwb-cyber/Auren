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
    status, supplierWorkflowStatus: status,
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

  const collections = [
    'auren_suppliers', 'auren_exporters', 'auren_importers', 'auren_manufacturers',
    'auren_wholesalers', 'auren_distributors', 'auren_retailers', 'auren_farmers',
    'auren_logistics_providers', 'auren_customs_brokers', 'auren_raw_material_suppliers',
    'auren_inspection_providers', 'auren_institutional_buyers', 'auren_authorized_dealers',
    'auren_trade_finance_partners', 'auren_trade_insurers', 'auren_commercial_agents',
    'auren_sourcing_agents', 'auren_packaging_providers', 'auren_warehouses',
    'auren_maintenance_providers', 'auren_cooperatives', 'auren_chambers_of_commerce',
    'auren_recyclers',
  ];
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
    if ((await ref.get()).exists) return {type:'supplier_contact_draft_created', requestId:ref.id, supplierId, status:'draft', externalDispatch:false, matchFlowId};
    const userRef = db.collection('users').doc(uid).collection('supplier_contact_requests').doc(ref.id);
    const data = {
      ...common, message,
      channel: clean(payload?.channel || 'draft', 40),
      contactEmail: supplier.email || supplier.contactEmail || null,
      contactPhone: supplier.phone || supplier.contactPhone || null,
    };
    const batch=db.batch();
    batch.set(ref,data); batch.set(userRef,data);
    await batch.commit();
    await updateMatchFlow(uid,matchFlowId,'waiting_response',{supplierRequestId:ref.id,supplierRequestType:'contact'});
    return {type:'supplier_contact_draft_created', requestId:ref.id, supplierId, status:'draft', externalDispatch:false, matchFlowId};
  }

  if (operation === 'rfq') {
    const product = clean(payload?.product, 300);
    const quantity = clean(payload?.quantity, 80);
    if (!product || !quantity) { const error = new Error('Product and quantity are required.'); error.code = 'validation'; throw error; }
    const ref = db.collection('supplier_rfqs').doc(stableKey);
    if ((await ref.get()).exists) return {type:'supplier_rfq_created', rfqId:ref.id, supplierId, status:'draft', externalDispatch:false, matchFlowId};
    const userRef = db.collection('users').doc(uid).collection('supplier_rfqs').doc(ref.id);
    const data = {
      ...common, product, quantity,
      unit: clean(payload?.unit, 40),
      currency: clean(payload?.currency, 3).toUpperCase(),
      notes: clean(payload?.notes, 3000),
    };
    const batch=db.batch();
    batch.set(ref,data); batch.set(userRef,data);
    await batch.commit();
    await updateMatchFlow(uid,matchFlowId,'waiting_response',{supplierRequestId:ref.id,supplierRequestType:'rfq'});
    return {type:'supplier_rfq_created', rfqId:ref.id, supplierId, status:'draft', externalDispatch:false, matchFlowId};
  }

  { const error = new Error('Unsupported supplier operation.'); error.code = 'validation'; throw error; }
}

module.exports = {createSupplierWorkflow};
