'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const db = admin.firestore();

const DEFINITIONS = {
  contact: ['message','channel'],
  rfq: ['product','quantity','unit','currency','notes'],
};

function clean(value, max) {
  return String(value || '').trim().slice(0, max);
}

exports.createAurenMatchAction = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid=request.auth?.uid;
    if(!uid) throw new HttpsError('unauthenticated','Authentication is required.');

    const operation=clean(request.data?.operation, 20).toLowerCase();
    const payload=request.data?.payload && typeof request.data.payload==='object' ? request.data.payload : {};
    if(!DEFINITIONS[operation]) throw new HttpsError('invalid-argument','Unsupported Match Everything action.');

    const supplierId=clean(payload.supplierId,128);
    if(!supplierId) throw new HttpsError('invalid-argument','Supplier is required.');

    const supplierSnap=await db.collection('auren_suppliers').doc(supplierId).get();
    if(!supplierSnap.exists) throw new HttpsError('not-found','Supplier not found.');
    const supplier=supplierSnap.data()||{};

    const actionRef=db.collection('users').doc(uid).collection('actions').doc();
    const actionType='supplier.workflow';
    const actionPayload={
      operation,
      supplierId,
      message:clean(payload.message,5000),
      channel:clean(payload.channel || 'draft',40),
      product:clean(payload.product,300),
      quantity:clean(payload.quantity,80),
      unit:clean(payload.unit,40),
      currency:clean(payload.currency,3).toUpperCase(),
      notes:clean(payload.notes,3000),
    };

    if(operation==='contact' && !actionPayload.message) {
      throw new HttpsError('invalid-argument','Message is required.');
    }
    if(operation==='rfq' && (!actionPayload.product || !actionPayload.quantity)) {
      throw new HttpsError('invalid-argument','Product and quantity are required.');
    }

    await actionRef.set({
      actionType,
      title:operation==='contact'?'التواصل مع المورد':'إنشاء طلب عرض سعر',
      description:operation==='contact'
        ? 'تم تجهيز مسودة تواصل وتحتاج موافقتك قبل التنفيذ.'
        : 'تم تجهيز طلب عرض سعر وتحتاج موافقتك قبل التنفيذ.',
      payload:actionPayload,
      supplierId,
      supplierName:clean(supplier.name || supplier.companyName || supplierId,200),
      permission:'standard',
      riskLevel:'medium',
      approvalLevel:1,
      requiresApproval:true,
      status:'pending',
      source:'match_everything',
      createdAt:admin.firestore.FieldValue.serverTimestamp(),
      expiresAtMs:Date.now()+15*60*1000,
      updatedAt:admin.firestore.FieldValue.serverTimestamp(),
    });

    return {status:'pending',actionId:actionRef.id,actionType,operation,supplierId};
  }
);
