'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { getFirestore, doc, getDoc, setDoc, updateDoc, deleteDoc, runTransaction, Timestamp } = require('firebase/firestore');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-emulator';
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

async function seedAction(userId, actionId, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = firestoreFor(context);
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
  return firestoreFor(testEnv.authenticatedContext(userId)).doc(`users/${userId}/actions/${actionId}`);
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
  const ref = firestoreFor(testEnv.authenticatedContext('rules-other')).doc('users/rules-owner/actions/cross-user');
  await assertFails(ref.get());
  await assertFails(ref.update({
    payload: { text: 'cross-user tamper' },
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
});

test('unauthenticated client cannot read or update the action', async () => {
  await seedAction('rules-user-10', 'unauth');
  const ref = firestoreFor(testEnv.unauthenticatedContext()).doc('users/rules-user-10/actions/unauth');
  await assertFails(ref.get());
  await assertFails(ref.update({
    payload: { text: 'unauth tamper' },
    draftVersion: 1,
    updatedAt: Timestamp.now(),
  }));
});

test('client cannot create action documents directly', async () => {
  const db = firestoreFor(testEnv.authenticatedContext('rules-user-11'));
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
    const db = firestoreFor(context);
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


async function seedSocialRequest(collection, id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await firestoreFor(context).doc(`${collection}/${id}`).set(data);
  });
}

test('random connect requests: only waiting requests or involved users are readable', async () => {
  await seedSocialRequest('random_connect', 'waiting-public', {
    uid: 'social-owner', status: 'waiting', displayName: 'Discoverable',
  });
  await seedSocialRequest('random_connect', 'matched-private', {
    uid: 'social-owner', status: 'matched', matchedWith: 'social-peer',
    displayName: 'Matched profile',
  });
  const stranger = firestoreFor(testEnv.authenticatedContext('social-stranger'));
  const owner = firestoreFor(testEnv.authenticatedContext('social-owner'));
  const peer = firestoreFor(testEnv.authenticatedContext('social-peer'));

  await assertSucceeds(stranger.doc('random_connect/waiting-public').get());
  await assertFails(stranger.doc('random_connect/matched-private').get());
  await assertSucceeds(owner.doc('random_connect/matched-private').get());
  await assertSucceeds(peer.doc('random_connect/matched-private').get());
});

test('random group requests: only waiting requests or the owner are readable', async () => {
  await seedSocialRequest('random_group_connect', 'group-waiting', {
    uid: 'group-owner', status: 'waiting', groupSize: 4,
  });
  await seedSocialRequest('random_group_connect', 'grouped-private', {
    uid: 'group-owner', status: 'grouped', groupSize: 4,
  });
  const stranger = firestoreFor(testEnv.authenticatedContext('group-stranger'));
  const owner = firestoreFor(testEnv.authenticatedContext('group-owner'));

  await assertSucceeds(stranger.doc('random_group_connect/group-waiting').get());
  await assertFails(stranger.doc('random_group_connect/grouped-private').get());
  await assertSucceeds(owner.doc('random_group_connect/grouped-private').get());
});
