'use strict';

const admin = require('firebase-admin');
const db = admin.firestore();

function clean(value, max) {
  return String(value || '').trim().slice(0, max);
}

async function createSupplierWorkflow({uid, operation, payload}) {
  const supplierId = clean(payload?.supplierId, 128);
  if (!supplierId) throw new Error('Supplier is required.');

  const supplierSnap = await db.collection('auren_suppliers').doc(supplierId).get();
  if (!supplierSnap.exists) throw new Error('Supplier not found.');
  const supplier = supplierSnap.data() || {};
  const supplierName = clean(supplier.name || supplier.companyName || supplierId, 200);

  if (operation === 'contact') {
    const message = clean(payload?.message, 5000);
    if (!message) throw new Error('Message is required.');
    const ref = db.collection('supplier_contact_requests').doc();
    await ref.set({
      supplierId, supplierName, requesterUid: uid, message,
      channel: clean(payload?.channel || 'draft', 40),
      status: 'draft',
      externalDispatch: false,
      contactEmail: supplier.email || supplier.contactEmail || null,
      contactPhone: supplier.phone || supplier.contactPhone || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {type:'supplier_contact_draft_created', requestId:ref.id, supplierId, status:'draft', externalDispatch:false};
  }

  if (operation === 'rfq') {
    const product = clean(payload?.product, 300);
    const quantity = clean(payload?.quantity, 80);
    if (!product || !quantity) throw new Error('Product and quantity are required.');
    const ref = db.collection('supplier_rfqs').doc();
    await ref.set({
      supplierId, supplierName, requesterUid: uid, product, quantity,
      unit: clean(payload?.unit, 40),
      currency: clean(payload?.currency, 3).toUpperCase(),
      notes: clean(payload?.notes, 3000),
      status: 'draft',
      externalDispatch: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return {type:'supplier_rfq_created', rfqId:ref.id, supplierId, status:'draft', externalDispatch:false};
  }

  throw new Error('Unsupported supplier operation.');
}

module.exports = {createSupplierWorkflow};
