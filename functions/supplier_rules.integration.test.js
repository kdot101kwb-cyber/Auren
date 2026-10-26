'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { getFirestore, doc, getDoc, setDoc, updateDoc, deleteDoc, runTransaction, Timestamp } = require('firebase/firestore');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-supplier-rules';
let testEnv;

/** Use the modular Firestore SDK with the app supplied by a rules test context. */
function firestoreFor(context) {
  const db = getFirestore(context.getApp());
  const wrapRef = (path) => {
    const ref = doc(db, path);
    return {
      _ref: ref,
      get: () => getDoc(ref),
      set: (data) => setDoc(ref, data),
      update: (data) => updateDoc(ref, data),
      delete: () => deleteDoc(ref),
    };
  };
  return {
    doc: wrapRef,
    runTransaction: (updateFunction) => runTransaction(db, (transaction) =>
      updateFunction({
        get: (ref) => transaction.get(ref._ref),
        update: (ref, data) => transaction.update(ref._ref, data),
      }),
    ),
  };
}


test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
    },
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

function comparison(ownerId, offers = []) {
  return {
    ownerId,
    offers,
    updatedAt: Timestamp.now(),
  };
}

function validOffer(id = 'offer-1') {
  return {
    id,
    supplier: 'Supplier Example',
    price: '125.50',
    currency: 'USD',
    shipping: '10',
    moq: '500 pieces',
    leadTime: '14 days',
    payment: 'Net 30',
    validity: '2026-12-31',
    notes: '',
    status: 'received',
    receivedAt: '2026-10-11T00:00:00.000Z',
  };
}

function rfqDraft(ownerId) {
  return {
    ownerId,
    target: 'Supplier Example',
    product: 'Cotton T-shirts',
    quantity: '500 pieces',
    destination: 'Khartoum, Sudan',
    specifications: 'Cotton, assorted sizes',
    budget: '1000',
    currency: 'USD',
    delivery: 'يُحدّد لاحقاً',
    contact: '',
    draft: 'Please provide a quotation.',
    updatedAt: Timestamp.now(),
  };
}

function userDb(uid) {
  return firestoreFor(testEnv.authenticatedContext(uid));
}

async function seed(pathname, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await firestoreFor(context).doc(pathname).set(data);
  });
}

test('comparison owner can create, read, update, and delete the active draft', async () => {
  const ref = userDb('supplier-owner')
      .doc('users/supplier-owner/supplier_offer_comparisons/active_draft');
  await assertSucceeds(ref.set(comparison('supplier-owner', [validOffer()])));
  await assertSucceeds(ref.get());
  await assertSucceeds(ref.update({
    offers: [validOffer('offer-2')],
    updatedAt: Timestamp.now(),
  }));
  await assertSucceeds(ref.delete());
});

test('another user cannot read, create, modify, or delete a supplier comparison', async () => {
  const pathName = 'users/supplier-owner/supplier_offer_comparisons/active_draft';
  await seed(pathName, comparison('supplier-owner', [validOffer()]));
  const otherRef = userDb('supplier-attacker').doc(pathName);

  await assertFails(otherRef.get());
  await assertFails(otherRef.set(comparison('supplier-attacker', [validOffer()])));
  await assertFails(otherRef.update({
    offers: [validOffer('tampered')],
    updatedAt: Timestamp.now(),
  }));
  await assertFails(otherRef.delete());
});

test('comparison rejects forged ownerId and malformed payloads', async () => {
  const db = userDb('comparison-user');
  const pathName = 'users/comparison-user/supplier_offer_comparisons/active_draft';

  await assertFails(db.doc(pathName).set(comparison('forged-user', [validOffer()])));
  await assertFails(db.doc(pathName).set({
    ...comparison('comparison-user', [validOffer()]),
    unexpected: 'not allowed',
  }));
  await assertFails(db.doc(pathName).set(comparison('comparison-user', [{
    ...validOffer(),
    price: '-12',
  }])));
  await assertFails(db.doc(pathName).set({
    ...comparison('comparison-user', [validOffer()]),
    updatedAt: 'not-a-timestamp',
  }));
});

test('RFQ owner can create, read, modify, and delete the active draft', async () => {
  const ref = userDb('rfq-owner')
      .doc('users/rfq-owner/supplier_rfq_drafts/active_draft');
  await assertSucceeds(ref.set(rfqDraft('rfq-owner')));
  await assertSucceeds(ref.get());
  await assertSucceeds(ref.update({
    product: 'Organic cotton T-shirts',
    updatedAt: Timestamp.now(),
  }));
  await assertSucceeds(ref.delete());
});

test('another user cannot read, create, modify, or delete an RFQ draft', async () => {
  const pathName = 'users/rfq-owner/supplier_rfq_drafts/active_draft';
  await seed(pathName, rfqDraft('rfq-owner'));
  const otherRef = userDb('rfq-attacker').doc(pathName);

  await assertFails(otherRef.get());
  await assertFails(otherRef.set(rfqDraft('rfq-attacker')));
  await assertFails(otherRef.update({
    product: 'Tampered product',
    updatedAt: Timestamp.now(),
  }));
  await assertFails(otherRef.delete());
});

test('RFQ draft rejects forged ownerId and malformed payloads', async () => {
  const db = userDb('rfq-user');
  const pathName = 'users/rfq-user/supplier_rfq_drafts/active_draft';

  await assertFails(db.doc(pathName).set(rfqDraft('somebody-else')));
  await assertFails(db.doc(pathName).set({
    ...rfqDraft('rfq-user'),
    unknownField: true,
  }));
  await assertFails(db.doc(pathName).set({
    ...rfqDraft('rfq-user'),
    product: '',
  }));
  await assertFails(db.doc(pathName).set({
    ...rfqDraft('rfq-user'),
    currency: 'XYZ',
  }));
  await assertFails(db.doc(pathName).set({
    ...rfqDraft('rfq-user'),
    updatedAt: 'not-a-timestamp',
  }));
});
