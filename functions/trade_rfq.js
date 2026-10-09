'use strict';

const admin = require('firebase-admin');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const db = admin.firestore();

const clean = (value, max = 300) => String(value ?? '').trim().slice(0, max);
const validCurrency = value => /^[A-Z]{3}$/.test(clean(value, 3).toUpperCase());
const validCountry = value => /^[A-Z]{2,3}$/.test(clean(value, 3).toUpperCase());

function normalizeQuoteForComparison(quote) {
  const currency = clean(quote?.currency, 3).toUpperCase();
  const totalPrice = Number(quote?.totalPrice);
  const shippingCost = quote?.shippingCost === null || quote?.shippingCost === undefined || quote?.shippingCost === ''
    ? null : Number(quote.shippingCost);
  return {
    currency,
    totalPrice: Number.isFinite(totalPrice) && totalPrice >= 0 ? totalPrice : null,
    shippingCost: shippingCost !== null && Number.isFinite(shippingCost) && shippingCost >= 0 ? shippingCost : null,
    deliveryDays: Number.isInteger(Number(quote?.deliveryDays)) && Number(quote.deliveryDays) > 0
      ? Number(quote.deliveryDays) : null,
    paymentTerms: clean(quote?.paymentTerms, 500),
    notes: clean(quote?.notes, 1000),
  };
}

function requireTradeAuth(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
  return uid;
}

exports.createAurenTradeRFQ = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async request => {
    const uid = requireTradeAuth(request);
    const product = clean(request.data?.product, 300);
    const quantity = Number(request.data?.quantity);
    const unit = clean(request.data?.unit, 40);
    const currency = clean(request.data?.currency, 3).toUpperCase();
    const destinationCountry = clean(request.data?.destinationCountry, 3).toUpperCase();
    const destinationCity = clean(request.data?.destinationCity, 120);
    const targetDate = clean(request.data?.targetDate, 30);
    const notes = clean(request.data?.notes, 3000);
    if (!product || !Number.isFinite(quantity) || quantity <= 0 || !unit ||
        !validCurrency(currency) || !validCountry(destinationCountry)) {
      throw new HttpsError('invalid-argument', 'Product, positive quantity, unit, currency and destination country are required.');
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    const ref = db.collection('auren_trade_rfqs').doc();
    const data = {
      buyerUid: uid, product, quantity, unit, currency, destinationCountry,
      destinationCity, targetDate, notes, status:'draft',
      quoteCount:0, createdAt:now, updatedAt:now,
      dataDisclosure:'Buyer-provided request; not independently verified.',
    };
    const userRef = db.collection('users').doc(uid).collection('trade_rfqs').doc(ref.id);
    const batch = db.batch();
    batch.set(ref, data);
    batch.set(userRef, data);
    await batch.commit();
    return {id:ref.id, status:'draft', published:false, externalDispatch:false};
  }
);

exports.publishAurenTradeRFQ = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async request => {
    const uid = requireTradeAuth(request);
    const rfqId = clean(request.data?.rfqId, 128);
    if (!rfqId) throw new HttpsError('invalid-argument', 'rfqId is required.');
    const globalRef = db.collection('auren_trade_rfqs').doc(rfqId);
    const userRef = db.collection('users').doc(uid).collection('trade_rfqs').doc(rfqId);
    await db.runTransaction(async tx => {
      const snap = await tx.get(userRef);
      if (!snap.exists) throw new HttpsError('not-found', 'RFQ not found.');
      const data = snap.data() || {};
      if (data.buyerUid !== uid) throw new HttpsError('permission-denied', 'Only the buyer can publish this RFQ.');
      if (data.status !== 'draft') throw new HttpsError('failed-precondition', 'Only draft RFQs can be published.');
      const update = {status:'open', publishedAt:admin.firestore.FieldValue.serverTimestamp(), updatedAt:admin.firestore.FieldValue.serverTimestamp()};
      tx.set(userRef, update, {merge:true});
      tx.set(globalRef, update, {merge:true});
    });
    return {id:rfqId, status:'open', visibleToTradeNetwork:true, externalDispatch:false};
  }
);

exports.listAurenOpenTradeRFQs = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async request => {
    requireTradeAuth(request);
    const destinationCountry = clean(request.data?.destinationCountry, 3).toUpperCase();
    if (destinationCountry && !validCountry(destinationCountry)) {
      throw new HttpsError('invalid-argument', 'destinationCountry must be a valid 2-3 letter code.');
    }
    const limit = Math.min(Math.max(Number(request.data?.limit) || 30, 1), 50);
    const snap = await db.collection('auren_trade_rfqs').where('status', '==', 'open').limit(100).get();
    const items = snap.docs.map(doc => {
      const d = doc.data() || {};
      return {
        id:doc.id, product:clean(d.product,300), quantity:d.quantity, unit:clean(d.unit,40),
        currency:clean(d.currency,3), destinationCountry:clean(d.destinationCountry,3),
        destinationCity:clean(d.destinationCity,120), targetDate:clean(d.targetDate,30),
        notes:clean(d.notes,1000), quoteCount:Number(d.quoteCount || 0), createdAt:d.createdAt || null,
      };
    }).filter(item => !destinationCountry || item.destinationCountry === destinationCountry)
      .sort((a,b) => (b.createdAt?.toMillis?.() || 0) - (a.createdAt?.toMillis?.() || 0))
      .slice(0, limit);
    return {items, count:items.length};
  }
);

exports.submitAurenTradeQuote = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async request => {
    const uid = requireTradeAuth(request);
    const rfqId = clean(request.data?.rfqId, 128);
    const supplierId = clean(request.data?.supplierId, 128);
    const totalPrice = Number(request.data?.totalPrice);
    const currency = clean(request.data?.currency, 3).toUpperCase();
    const shippingCost = request.data?.shippingCost === '' || request.data?.shippingCost == null ? null : Number(request.data.shippingCost);
    const deliveryDays = request.data?.deliveryDays === '' || request.data?.deliveryDays == null ? null : Number(request.data.deliveryDays);
    const paymentTerms = clean(request.data?.paymentTerms, 500);
    const notes = clean(request.data?.notes, 1000);
    if (!rfqId || !supplierId || !Number.isFinite(totalPrice) || totalPrice < 0 || !validCurrency(currency) ||
        (shippingCost !== null && (!Number.isFinite(shippingCost) || shippingCost < 0)) ||
        (deliveryDays !== null && (!Number.isInteger(deliveryDays) || deliveryDays < 1))) {
      throw new HttpsError('invalid-argument', 'RFQ, supplier, non-negative total price and valid currency are required.');
    }
    const rfqRef = db.collection('auren_trade_rfqs').doc(rfqId);
    const supplierCollections = ['auren_suppliers','auren_exporters','auren_importers','auren_manufacturers',
      'auren_wholesalers','auren_distributors','auren_retailers','auren_farmers','auren_logistics_providers',
      'auren_customs_brokers','auren_raw_material_suppliers','auren_inspection_providers','auren_institutional_buyers',
      'auren_authorized_dealers','auren_trade_finance_partners','auren_trade_insurers','auren_commercial_agents',
      'auren_sourcing_agents','auren_packaging_providers','auren_warehouses','auren_maintenance_providers',
      'auren_cooperatives','auren_chambers_of_commerce','auren_recyclers'];
    let supplierFound = false;
    let supplierOwnerUid = '';
    for (const collection of supplierCollections) {
      const snap = await db.collection(collection).doc(supplierId).get();
      if (snap.exists) { const record = snap.data() || {}; supplierOwnerUid = clean(record.ownerUid || record.ownerUserId || record.createdByUid || record.createdBy, 128); supplierFound = true; break; }
    }
    if (!supplierFound) throw new HttpsError('not-found', 'Trade-network actor not found.');
    if (!supplierOwnerUid || supplierOwnerUid !== uid) throw new HttpsError('permission-denied', 'Supplier ownership must be established before quoting.');
    const quoteRef = rfqRef.collection('quotes').doc();
    const data = {
      supplierId, supplierUid:uid, totalPrice, currency, shippingCost, deliveryDays,
      paymentTerms, notes, status:'submitted',
      verificationStatus:'not_assessed',
      createdAt:admin.firestore.FieldValue.serverTimestamp(),
      updatedAt:admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.runTransaction(async tx => {
      const rfqSnap = await tx.get(rfqRef);
      if (!rfqSnap.exists) throw new HttpsError('not-found', 'RFQ not found.');
      const rfq = rfqSnap.data() || {};
      if (rfq.status !== 'open') throw new HttpsError('failed-precondition', 'RFQ is not open for quotes.');
      if (rfq.buyerUid === uid) throw new HttpsError('permission-denied', 'The buyer cannot quote on their own RFQ.');
      tx.create(quoteRef, data);
      tx.set(rfqRef, {quoteCount:admin.firestore.FieldValue.increment(1), updatedAt:admin.firestore.FieldValue.serverTimestamp()}, {merge:true});
    });
    return {id:quoteRef.id, rfqId, status:'submitted', verificationStatus:'not_assessed', externalDispatch:false};
  }
);

exports.listAurenTradeRFQQuotes = onCall(
  {region:'us-central1', timeoutSeconds:20, memory:'256MiB', enforceAppCheck:true},
  async request => {
    const uid = requireTradeAuth(request);
    const rfqId = clean(request.data?.rfqId, 128);
    if (!rfqId) throw new HttpsError('invalid-argument', 'rfqId is required.');
    const ownerRef = db.collection('users').doc(uid).collection('trade_rfqs').doc(rfqId);
    const ownerSnap = await ownerRef.get();
    if (!ownerSnap.exists || ownerSnap.data()?.buyerUid !== uid) {
      throw new HttpsError('permission-denied', 'Only the RFQ owner can compare quotes.');
    }
    const snap = await db.collection('auren_trade_rfqs').doc(rfqId).collection('quotes').get();
    const quotes = snap.docs.map(doc => ({id:doc.id, ...doc.data()}));
    const groups = {};
    for (const quote of quotes) {
      const normalized = normalizeQuoteForComparison(quote);
      const key = normalized.currency || 'UNKNOWN';
      if (!groups[key]) groups[key] = [];
      groups[key].push({
        id:quote.id, supplierId:clean(quote.supplierId, 128), currency:key,
        totalPrice:normalized.totalPrice, shippingCost:normalized.shippingCost,
        deliveryDays:normalized.deliveryDays, paymentTerms:normalized.paymentTerms,
        notes:normalized.notes, verificationStatus:clean(quote.verificationStatus, 40) || 'not_assessed',
      });
    }
    for (const list of Object.values(groups)) {
      list.sort((a,b) => {
        if (a.totalPrice === null) return b.totalPrice === null ? 0 : 1;
        if (b.totalPrice === null) return -1;
        return a.totalPrice - b.totalPrice;
      });
    }
    return {rfqId, quoteCount:quotes.length, comparisonGroups:groups,
      note:'Quotes are grouped by currency; no FX conversion, landed-cost estimate, supplier verification, or delivery guarantee is implied.'};
  }
);

module.exports.normalizeQuoteForComparison = normalizeQuoteForComparison;
