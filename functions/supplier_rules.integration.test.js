'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { Timestamp, doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');

const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-supplier-rules';
let testEnv;

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
  return testEnv.authenticatedContext(uid).firestore();
}

async function seed(pathname, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), pathname), data);
  });
}

test('comparison owner can create, read, update, and delete the active draft', async () => {
  const ref = doc(userDb('supplier-owner'), 'users/supplier-owner/supplier_offer_comparisons/active_draft');
  await assertSucceeds(setDoc(ref, comparison('supplier-owner', [validOffer()])));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, {
    offers: [validOffer('offer-2')],
    updatedAt: Timestamp.now(),
  }));
  await assertSucceeds(deleteDoc(ref));
});

test('another user cannot read, create, modify, or delete a supplier comparison', async () => {
  const pathName = 'users/supplier-owner/supplier_offer_comparisons/active_draft';
  await seed(pathName, comparison('supplier-owner', [validOffer()]));
  const otherRef = doc(userDb('supplier-attacker'), pathName);

  await assertFails(getDoc(otherRef));
  await assertFails(setDoc(otherRef, comparison('supplier-attacker', [validOffer()])));
  await assertFails(updateDoc(otherRef, {
    offers: [validOffer('tampered')],
    updatedAt: Timestamp.now(),
  }));
  await assertFails(deleteDoc(otherRef));
});

test('comparison rejects forged ownerId and malformed payloads', async () => {
  const db = userDb('comparison-user');
  const pathName = 'users/comparison-user/supplier_offer_comparisons/active_draft';

  await assertFails(setDoc(doc(db, pathName), comparison('forged-user', [validOffer()])));
  await assertFails(setDoc(doc(db, pathName), {
    ...comparison('comparison-user', [validOffer()]),
    unexpected: 'not allowed',
  }));
  await assertFails(setDoc(doc(db, pathName), comparison('comparison-user', [{
    ...validOffer(),
    price: '-12',
  }])));
  await assertFails(setDoc(doc(db, pathName), {
    ...comparison('comparison-user', [validOffer()]),
    updatedAt: 'not-a-timestamp',
  }));
});

test('RFQ owner can create, read, modify, and delete the active draft', async () => {
  const ref = doc(userDb('rfq-owner'), 'users/rfq-owner/supplier_rfq_drafts/active_draft');
  await assertSucceeds(setDoc(ref, rfqDraft('rfq-owner')));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, {
    product: 'Organic cotton T-shirts',
    updatedAt: Timestamp.now(),
  }));
  await assertSucceeds(deleteDoc(ref));
});

test('another user cannot read, create, modify, or delete an RFQ draft', async () => {
  const pathName = 'users/rfq-owner/supplier_rfq_drafts/active_draft';
  await seed(pathName, rfqDraft('rfq-owner'));
  const otherRef = doc(userDb('rfq-attacker'), pathName);

  await assertFails(getDoc(otherRef));
  await assertFails(setDoc(otherRef, rfqDraft('rfq-attacker')));
  await assertFails(updateDoc(otherRef, {
    product: 'Tampered product',
    updatedAt: Timestamp.now(),
  }));
  await assertFails(deleteDoc(otherRef));
});

test('RFQ draft rejects forged ownerId and malformed payloads', async () => {
  const db = userDb('rfq-user');
  const pathName = 'users/rfq-user/supplier_rfq_drafts/active_draft';

  await assertFails(setDoc(doc(db, pathName), rfqDraft('somebody-else')));
  await assertFails(setDoc(doc(db, pathName), {
    ...rfqDraft('rfq-user'),
    unknownField: true,
  }));
  await assertFails(setDoc(doc(db, pathName), {
    ...rfqDraft('rfq-user'),
    product: '',
  }));
  await assertFails(setDoc(doc(db, pathName), {
    ...rfqDraft('rfq-user'),
    currency: 'XYZ',
  }));
  await assertFails(setDoc(doc(db, pathName), {
    ...rfqDraft('rfq-user'),
    updatedAt: 'not-a-timestamp',
  }));
});
