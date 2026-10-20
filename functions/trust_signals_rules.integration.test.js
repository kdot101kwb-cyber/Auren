'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const {
  initializeTestEnvironment,
  assertFails,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-trust-rules';
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
    await context.firestore().doc('users/trust-owner/trust_signals/seeded').set({
      type: 'successful_connection',
      label: 'fixture only',
      createdAt: firebase.firestore.Timestamp.now(),
    });
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test('trust signals cannot be read by the profile owner or another signed-in user', async () => {
  const ownerDb = testEnv.authenticatedContext('trust-owner').firestore();
  const otherDb = testEnv.authenticatedContext('trust-other').firestore();

  await assertFails(ownerDb.doc('users/trust-owner/trust_signals/seeded').get());
  await assertFails(ownerDb.collection('users/trust-owner/trust_signals').get());
  await assertFails(otherDb.doc('users/trust-owner/trust_signals/seeded').get());
});

test('clients cannot create, modify, or delete trust signals, including identity claims', async () => {
  const ownerDb = testEnv.authenticatedContext('trust-owner').firestore();
  const signal = ownerDb.doc('users/trust-owner/trust_signals/client-created');

  await assertFails(signal.set({
    type: 'successful_connection',
    label: 'client supplied',
    createdAt: firebase.firestore.Timestamp.now(),
  }));
  await assertFails(signal.set({
    type: 'identity_verified',
    label: 'self-asserted verification',
    createdAt: firebase.firestore.Timestamp.now(),
  }));
  await assertFails(ownerDb.doc('users/trust-owner/trust_signals/seeded').update({
    label: 'tampered',
  }));
  await assertFails(ownerDb.doc('users/trust-owner/trust_signals/seeded').delete());
});

test('unauthenticated clients cannot read or write trust signals', async () => {
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(db.doc('users/trust-owner/trust_signals/seeded').get());
  await assertFails(db.doc('users/trust-owner/trust_signals/anonymous').set({
    type: 'identity_verified',
    label: 'anonymous claim',
    createdAt: firebase.firestore.Timestamp.now(),
  }));
});
