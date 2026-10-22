'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-emulator';
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
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const now = firebase.firestore.Timestamp.now();
    await db.doc('users/family-wallet-owner/familyWallet/current').set({
      ownerUid: 'family-wallet-owner',
      currency: 'USD',
      balancesMinor: { USD: 0 },
      createdAt: now,
      updatedAt: now,
    });
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test('family wallet ledger allows owner appends but forbids edits and deletes', async () => {
  const db = testEnv.authenticatedContext('family-wallet-owner').firestore();
  const entry = db.doc('users/family-wallet-owner/familyWallet/current/entries/entry-1');
  await assertSucceeds(entry.set({
    ownerUid: 'family-wallet-owner',
    title: 'Groceries',
    amountMinor: 1200,
    currency: 'USD',
    kind: 'expense',
    createdAt: firebase.firestore.Timestamp.now(),
  }));
  await assertFails(entry.update({ title: 'Changed' }));
  await assertFails(entry.delete());

  const other = testEnv.authenticatedContext('another-user').firestore();
  await assertFails(other.doc(
    'users/family-wallet-owner/familyWallet/current/entries/entry-1',
  ).get());
});

test('family monthly budgets reject malformed periods and restrict updates', async () => {
  const db = testEnv.authenticatedContext('family-wallet-owner').firestore();
  const now = firebase.firestore.Timestamp.now();
  const budget = db.doc(
    'users/family-wallet-owner/familyWallet/current/budgets/2026-10_USD',
  );
  await assertSucceeds(budget.set({
    ownerUid: 'family-wallet-owner',
    periodKey: '2026-10',
    currency: 'USD',
    limitMinor: 25000,
    createdAt: now,
    updatedAt: now,
  }));
  await assertSucceeds(budget.update({
    limitMinor: 30000,
    updatedAt: firebase.firestore.Timestamp.now(),
  }));
  await assertFails(budget.update({
    currency: 'EUR',
    updatedAt: firebase.firestore.Timestamp.now(),
  }));

  await assertFails(db.doc(
    'users/family-wallet-owner/familyWallet/current/budgets/2026-13_USD',
  ).set({
    ownerUid: 'family-wallet-owner',
    periodKey: '2026-13',
    currency: 'USD',
    limitMinor: 1000,
    createdAt: now,
    updatedAt: now,
  }));
});

test('family planning subcollections cannot be written under a non-current wallet id', async () => {
  const db = testEnv.authenticatedContext('family-wallet-owner').firestore();
  const now = firebase.firestore.Timestamp.now();
  await assertFails(db.doc(
    'users/family-wallet-owner/familyWallet/alternate/budgets/2026-10_USD',
  ).set({
    ownerUid: 'family-wallet-owner',
    periodKey: '2026-10',
    currency: 'USD',
    limitMinor: 1000,
    createdAt: now,
    updatedAt: now,
  }));
});

test('family savings goals permit progress only up to target', async () => {
  const db = testEnv.authenticatedContext('family-wallet-owner').firestore();
  const now = firebase.firestore.Timestamp.now();
  const goal = db.doc(
    'users/family-wallet-owner/familyWallet/current/goals/school',
  );
  await assertSucceeds(goal.set({
    ownerUid: 'family-wallet-owner',
    title: 'School costs',
    targetMinor: 10000,
    savedMinor: 0,
    currency: 'USD',
    createdAt: now,
    updatedAt: now,
  }));
  await assertSucceeds(goal.update({
    savedMinor: 3000,
    updatedAt: firebase.firestore.Timestamp.now(),
  }));
  await assertFails(goal.update({
    targetMinor: 50000,
    savedMinor: 4000,
    updatedAt: firebase.firestore.Timestamp.now(),
  }));
  await assertFails(goal.update({
    savedMinor: 12000,
    updatedAt: firebase.firestore.Timestamp.now(),
  }));
});
