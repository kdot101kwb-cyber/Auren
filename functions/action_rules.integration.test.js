'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');

const Timestamp = firebase.firestore.Timestamp;
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
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

async function seedAction(userId, actionId, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const now = Timestamp.now();
    await db.doc(`users/${userId}/actions/${actionId}`).set({
      actionType: 'demo.create_note',
      title: 'Create note',
      description: 'Server-created action draft',
      payload: { text: 'hello' },
      status: 'pending',
      draftVersion: 0,
      requiresApproval: true,
      createdAt: now,
      updatedAt: now,
      ...overrides,
    });
  });
}

function actionRef(userId, actionId) {
  return testEnv.authenticatedContext(userId).firestore()
    .doc(`users/${userId}/actions/${actionId}`);
}

test('owner can read and edit only the pending draft with version +1', async () => {
  await seedAction('rules-user-1', 'draft-allowed');
  const ref = actionRef('rules-user-1', 'draft-allowed');
  await assertSucceeds(ref.get());
  await assertSucceeds(ref.update({
    title: 'Updated title',
    payload: { text: 'updated' },
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
  const snap = await ref.get();
  assert.equal(snap.data().draftVersion, 1);
  assert.deepEqual(snap.data().payload, { text: 'updated' });
});

test('same draftVersion is rejected', async () => {
  await seedAction('rules-user-2', 'same-version');
  await assertFails(actionRef('rules-user-2', 'same-version').update({
    payload: { text: 'tampered' },
    draftVersion: 0,
    updatedAt: Timestamp.now(),
  }));
});

test('version jump greater than +1 is rejected', async () => {
  await seedAction('rules-user-3', 'version-jump');
  await assertFails(actionRef('rules-user-3', 'version-jump').update({
    payload: { text: 'tampered' },
    draftVersion: 2,
    updatedAt: Timestamp.now(),
  }));
});

test('client cannot change status during draft editing', async () => {
  await seedAction('rules-user-4', 'status-change');
  await assertFails(actionRef('rules-user-4', 'status-change').update({
    status: 'approved',
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
});

test('client cannot change actionType', async () => {
  await seedAction('rules-user-5', 'action-type');
  await assertFails(actionRef('rules-user-5', 'action-type').update({
    actionType: 'memory.save',
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
});

test('client cannot change createdAt', async () => {
  await seedAction('rules-user-6', 'created-at');
  await assertFails(actionRef('rules-user-6', 'created-at').update({
    createdAt: Timestamp.fromMillis(Date.now() - 1000),
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
});

test('client cannot write approval fields', async () => {
  await seedAction('rules-user-7', 'approval-fields');
  await assertFails(actionRef('rules-user-7', 'approval-fields').update({
    approvedBy: 'rules-user-7',
    approvedPayloadHash: 'forged-hash',
    approvalExpiresAt: Timestamp.now(),
    idempotencyKey: 'forged-key',
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
});

test('client cannot update an action after it leaves pending', async () => {
  await seedAction('rules-user-8', 'approved-action', {
    status: 'approved',
    approvedBy: 'rules-user-8',
    approvedPayloadHash: 'server-hash',
    approvalExpiresAt: Timestamp.now(),
    idempotencyKey: 'server-key',
  });
  await assertFails(actionRef('rules-user-8', 'approved-action').update({
    payload: { text: 'tampered' },
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
});

test('client cannot delete an action', async () => {
  await seedAction('rules-user-9', 'delete-action');
  await assertFails(actionRef('rules-user-9', 'delete-action').delete());
});

test('another user cannot read or update the action', async () => {
  await seedAction('rules-owner', 'cross-user');
  const ref = testEnv.authenticatedContext('rules-other').firestore()
    .doc('users/rules-owner/actions/cross-user');
  await assertFails(ref.get());
  await assertFails(ref.update({
    payload: { text: 'cross-user tamper' },
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
});

test('unauthenticated client cannot read or update the action', async () => {
  await seedAction('rules-user-10', 'unauth');
  const ref = testEnv.unauthenticatedContext().firestore()
    .doc('users/rules-user-10/actions/unauth');
  await assertFails(ref.get());
  await assertFails(ref.update({
    payload: { text: 'unauth tamper' },
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
});

test('client cannot create action documents directly', async () => {
  const db = testEnv.authenticatedContext('rules-user-11').firestore();
  await assertFails(db.doc('users/rules-user-11/actions/client-create').set({
    actionType: 'demo.create_note',
    title: 'Client-created',
    description: 'Should be server-owned',
    payload: { text: 'hello' },
    status: 'pending',
    draftVersion: 0,
    requiresApproval: true,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  }));
});

test('concurrent execution claims allow exactly one winner', async () => {
  await seedAction('rules-concurrency', 'execution-claim', {
    status: 'approved',
    approvedBy: 'rules-concurrency',
    approvedActionType: 'demo.create_note',
    approvedPayloadHash: 'server-hash',
    idempotencyKey: 'server-key',
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const ref = db.doc('users/rules-concurrency/actions/execution-claim');

    const claim = async () => {
      try {
        await db.runTransaction(async (tx) => {
          const snap = await tx.get(ref);
          assert.equal(snap.data().status, 'approved');
          tx.update(ref, {
            status: 'executing',
            updatedAt: Timestamp.now(),
          });
        });
        return true;
      } catch (_) {
        return false;
      }
    };

    const results = await Promise.all([claim(), claim()]);
    assert.equal(results.filter(Boolean).length, 1);
    const finalSnap = await ref.get();
    assert.equal(finalSnap.data().status, 'executing');
  });
});
