'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
// rules-unit-testing exposes a Firebase app/context backed by the namespaced
// Firestore API. Load the compat Firestore namespace before calling
// RulesTestContext.firestore() so the test app has a firestore() method.
require('firebase/compat/firestore');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  runTransaction,
  Timestamp,
} = require('firebase/firestore');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-emulator';
let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

async function seedAction(userId, actionId, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, `users/${userId}/actions/${actionId}`), {
      actionType: 'demo.create_note',
      title: 'Create note',
      description: 'Server-created action draft',
      payload: {text: 'hello'},
      status: 'pending',
      draftVersion: 0,
      requiresApproval: true,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
      ...overrides,
    });
  });
}

function actionRef(userId, actionId) {
  return doc(
    testEnv.authenticatedContext(userId).firestore(),
    `users/${userId}/actions/${actionId}`,
  );
}

test('owner can read and edit only the pending draft with version +1', async () => {
  await seedAction('rules-user-1', 'draft-allowed');
  const ref = actionRef('rules-user-1', 'draft-allowed');
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, {
    title: 'Updated title',
    payload: {text: 'updated'},
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
  const snap = await getDoc(ref);
  assert.equal(snap.data().draftVersion, 1);
  assert.deepEqual(snap.data().payload, {text: 'updated'});
});

test('same draftVersion is rejected', async () => {
  await seedAction('rules-user-2', 'same-version');
  await assertFails(updateDoc(actionRef('rules-user-2', 'same-version'), {
    payload: {text: 'tampered'}, draftVersion: 0, updatedAt: Timestamp.now(),
  }));
});

test('version jump greater than +1 is rejected', async () => {
  await seedAction('rules-user-3', 'version-jump');
  await assertFails(updateDoc(actionRef('rules-user-3', 'version-jump'), {
    payload: {text: 'tampered'}, draftVersion: 2, updatedAt: Timestamp.now(),
  }));
});

test('client cannot change status during draft editing', async () => {
  await seedAction('rules-user-4', 'status-change');
  await assertFails(updateDoc(actionRef('rules-user-4', 'status-change'), {
    status: 'approved', draftVersion: 1, updatedAt: Timestamp.now(),
  }));
});

test('client cannot change actionType', async () => {
  await seedAction('rules-user-5', 'action-type');
  await assertFails(updateDoc(actionRef('rules-user-5', 'action-type'), {
    actionType: 'memory.save', draftVersion: 1, updatedAt: Timestamp.now(),
  }));
});

test('client cannot change createdAt', async () => {
  await seedAction('rules-user-6', 'created-at');
  await assertFails(updateDoc(actionRef('rules-user-6', 'created-at'), {
    createdAt: Timestamp.fromMillis(Date.now() - 1000), draftVersion: 1, updatedAt: Timestamp.now(),
  }));
});

test('client cannot write approval fields', async () => {
  await seedAction('rules-user-7', 'approval-fields');
  await assertFails(updateDoc(actionRef('rules-user-7', 'approval-fields'), {
    approvedBy: 'rules-user-7', approvedPayloadHash: 'forged-hash', approvalExpiresAt: Timestamp.now(),
    idempotencyKey: 'forged-key', draftVersion: 1, updatedAt: Timestamp.now(),
  }));
});

test('client cannot update an action after it leaves pending', async () => {
  await seedAction('rules-user-8', 'approved-action', {
    status: 'approved', approvedBy: 'rules-user-8', approvedPayloadHash: 'server-hash',
    approvalExpiresAt: Timestamp.now(), idempotencyKey: 'server-key',
  });
  await assertFails(updateDoc(actionRef('rules-user-8', 'approved-action'), {
    payload: {text: 'tampered'}, draftVersion: 1, updatedAt: Timestamp.now(),
  }));
});

test('client cannot delete an action', async () => {
  await seedAction('rules-user-9', 'delete-action');
  await assertFails(deleteDoc(actionRef('rules-user-9', 'delete-action')));
});

test('another user cannot read or update the action', async () => {
  await seedAction('rules-owner', 'cross-user');
  const otherDb = testEnv.authenticatedContext('rules-other').firestore();
  const ref = doc(otherDb, 'users/rules-owner/actions/cross-user');
  await assertFails(getDoc(ref));
  await assertFails(updateDoc(ref, {
    payload: {text: 'cross-user tamper'}, draftVersion: 1, updatedAt: Timestamp.now(),
  }));
});

test('unauthenticated client cannot read or update the action', async () => {
  await seedAction('rules-user-10', 'unauth');
  const db = testEnv.unauthenticatedContext().firestore();
  const ref = doc(db, 'users/rules-user-10/actions/unauth');
  await assertFails(getDoc(ref));
  await assertFails(updateDoc(ref, {
    payload: {text: 'unauth tamper'}, draftVersion: 1, updatedAt: Timestamp.now(),
  }));
});

test('client cannot create action documents directly', async () => {
  const db = testEnv.authenticatedContext('rules-user-11').firestore();
  const ref = doc(db, 'users/rules-user-11/actions/client-create');
  await assertFails(setDoc(ref, {
    actionType: 'demo.create_note', title: 'Client-created', description: 'Should be server-owned',
    payload: {text: 'hello'}, status: 'pending', draftVersion: 0, requiresApproval: true,
    createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
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
    const ref = doc(db, 'users/rules-concurrency/actions/execution-claim');

    const claim = async () => {
      try {
        await runTransaction(db, async (tx) => {
          const snap = await tx.get(ref);
          assert.equal(snap.data().status, 'approved');
          tx.update(ref, {status: 'executing', updatedAt: Timestamp.now()});
        });
        return true;
      } catch (_) {
        return false;
      }
    };

    const results = await Promise.all([claim(), claim()]);
    assert.equal(results.filter(Boolean).length, 1);
    const finalSnap = await getDoc(ref);
    assert.equal(finalSnap.data().status, 'executing');
  });
});
