'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {
  Timestamp, doc, setDoc, getDoc, updateDoc, deleteDoc, runTransaction,
} = require('firebase/firestore');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');

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

function dbFor(context) {
  // rules-unit-testing v3 exposes the modular Firestore API, not compat methods.
  return context.firestore();
}

function actionRef(context, userId, actionId) {
  return doc(dbFor(context), `users/${userId}/actions/${actionId}`);
}

async function seedAction(userId, actionId, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const now = Timestamp.now();
    await setDoc(doc(dbFor(context), `users/${userId}/actions/${actionId}`), {
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

test('owner can read and edit only the pending draft with version +1', async () => {
  await seedAction('rules-user-1', 'draft-allowed');
  const ref = actionRef(testEnv.authenticatedContext('rules-user-1'), 'rules-user-1', 'draft-allowed');
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, {
    title: 'Updated title', payload: { text: 'updated' },
    draftVersion: 1, updatedAt: Timestamp.now(),
  }));
  const snap = await getDoc(ref);
  assert.equal(snap.data().draftVersion, 1);
  assert.deepEqual(snap.data().payload, { text: 'updated' });
});

test('same draftVersion is rejected', async () => {
  await seedAction('rules-user-2', 'same-version');
  await assertFails(updateDoc(actionRef(testEnv.authenticatedContext('rules-user-2'), 'rules-user-2', 'same-version'), {
    payload: { text: 'tampered' }, draftVersion: 0, updatedAt: Timestamp.now(),
  }));
});

test('version jump greater than +1 is rejected', async () => {
  await seedAction('rules-user-3', 'version-jump');
  await assertFails(updateDoc(actionRef(testEnv.authenticatedContext('rules-user-3'), 'rules-user-3', 'version-jump'), {
    payload: { text: 'tampered' }, draftVersion: 2, updatedAt: Timestamp.now(),
  }));
});

test('client cannot change status or actionType during draft editing', async () => {
  await seedAction('rules-user-4', 'status-change');
  const ref = actionRef(testEnv.authenticatedContext('rules-user-4'), 'rules-user-4', 'status-change');
  await assertFails(updateDoc(ref, { status: 'approved', draftVersion: 1, updatedAt: Timestamp.now() }));
  await assertFails(updateDoc(ref, { actionType: 'memory.save', draftVersion: 1, updatedAt: Timestamp.now() }));
});

test('client cannot change createdAt or write approval fields', async () => {
  await seedAction('rules-user-5', 'protected-fields');
  const ref = actionRef(testEnv.authenticatedContext('rules-user-5'), 'rules-user-5', 'protected-fields');
  await assertFails(updateDoc(ref, {
    createdAt: Timestamp.fromMillis(Date.now() - 1000), draftVersion: 1, updatedAt: Timestamp.now(),
  }));
  await assertFails(updateDoc(ref, {
    approvedBy: 'rules-user-5', approvedPayloadHash: 'forged-hash',
    approvalExpiresAt: Timestamp.now(), idempotencyKey: 'forged-key',
    draftVersion: 1, updatedAt: Timestamp.now(),
  }));
});

test('client cannot update an action after it leaves pending or delete an action', async () => {
  await seedAction('rules-user-6', 'approved-action', {
    status: 'approved', approvedBy: 'rules-user-6',
    approvedPayloadHash: 'server-hash', approvalExpiresAt: Timestamp.now(), idempotencyKey: 'server-key',
  });
  const ref = actionRef(testEnv.authenticatedContext('rules-user-6'), 'rules-user-6', 'approved-action');
  await assertFails(updateDoc(ref, { payload: { text: 'tampered' }, draftVersion: 1, updatedAt: Timestamp.now() }));
  await assertFails(deleteDoc(ref));
});

test('another user and unauthenticated clients cannot read or update an action', async () => {
  await seedAction('rules-owner', 'cross-user');
  const otherRef = actionRef(testEnv.authenticatedContext('rules-other'), 'rules-owner', 'cross-user');
  await assertFails(getDoc(otherRef));
  await assertFails(updateDoc(otherRef, { payload: { text: 'cross-user tamper' }, draftVersion: 1, updatedAt: Timestamp.now() }));

  await seedAction('rules-user-7', 'unauth');
  const anonymousRef = actionRef(testEnv.unauthenticatedContext(), 'rules-user-7', 'unauth');
  await assertFails(getDoc(anonymousRef));
  await assertFails(updateDoc(anonymousRef, { payload: { text: 'unauth tamper' }, draftVersion: 1, updatedAt: Timestamp.now() }));
});

test('client cannot create action documents directly', async () => {
  const db = dbFor(testEnv.authenticatedContext('rules-user-8'));
  await assertFails(setDoc(doc(db, 'users/rules-user-8/actions/client-create'), {
    actionType: 'demo.create_note', title: 'Client-created', description: 'Should be server-owned',
    payload: { text: 'hello' }, status: 'pending', draftVersion: 0, requiresApproval: true,
    createdAt: Timestamp.now(), updatedAt: Timestamp.now(),
  }));
});

test('concurrent execution claims allow exactly one winner', async () => {
  await seedAction('rules-concurrency', 'execution-claim', {
    status: 'approved', approvedBy: 'rules-concurrency', approvedActionType: 'demo.create_note',
    approvedPayloadHash: 'server-hash', idempotencyKey: 'server-key',
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = dbFor(context);
    const ref = doc(db, 'users/rules-concurrency/actions/execution-claim');
    const claim = async () => {
      try {
        await runTransaction(db, async (tx) => {
          const snap = await tx.get(ref);
          assert.equal(snap.data().status, 'approved');
          tx.update(ref, { status: 'executing', updatedAt: Timestamp.now() });
        });
        return true;
      } catch (_) {
        return false;
      }
    };
    const results = await Promise.all([claim(), claim()]);
    assert.equal(results.filter(Boolean).length, 1);
    assert.equal((await getDoc(ref)).data().status, 'executing');
  });
});

async function seedRequest(collection, id, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(dbFor(context), `${collection}/${id}`), data);
  });
}

test('random connect requests: waiting requests or involved users are readable', async () => {
  await seedRequest('random_connect', 'waiting-public', { uid: 'social-owner', status: 'waiting', displayName: 'Discoverable' });
  await seedRequest('random_connect', 'matched-private', { uid: 'social-owner', status: 'matched', matchedWith: 'social-peer', displayName: 'Matched profile' });
  await assertSucceeds(getDoc(doc(dbFor(testEnv.authenticatedContext('social-stranger')), 'random_connect/waiting-public')));
  await assertFails(getDoc(doc(dbFor(testEnv.authenticatedContext('social-stranger')), 'random_connect/matched-private')));
  await assertSucceeds(getDoc(doc(dbFor(testEnv.authenticatedContext('social-owner')), 'random_connect/matched-private')));
  await assertSucceeds(getDoc(doc(dbFor(testEnv.authenticatedContext('social-peer')), 'random_connect/matched-private')));
});

test('random group requests: waiting requests or the owner are readable', async () => {
  await seedRequest('random_group_connect', 'group-waiting', { uid: 'group-owner', status: 'waiting', groupSize: 4 });
  await seedRequest('random_group_connect', 'grouped-private', { uid: 'group-owner', status: 'grouped', groupSize: 4 });
  await assertSucceeds(getDoc(doc(dbFor(testEnv.authenticatedContext('group-stranger')), 'random_group_connect/group-waiting')));
  await assertFails(getDoc(doc(dbFor(testEnv.authenticatedContext('group-stranger')), 'random_group_connect/grouped-private')));
  await assertSucceeds(getDoc(doc(dbFor(testEnv.authenticatedContext('group-owner')), 'random_group_connect/grouped-private')));
});

test('NOVA debate history is readable only by its owner and remains server-write-only', async () => {
  const debatePath = 'users/nova-owner/novaDebates/debate123456789012';
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(dbFor(context), debatePath), {
      status: 'awaiting_user_agreement', executionStarted: false, createdAt: Timestamp.now(),
    });
  });
  const ownerRef = doc(dbFor(testEnv.authenticatedContext('nova-owner')), debatePath);
  const otherRef = doc(dbFor(testEnv.authenticatedContext('nova-other')), debatePath);
  await assertSucceeds(getDoc(ownerRef));
  await assertFails(getDoc(otherRef));
  await assertFails(setDoc(ownerRef, { status: 'plan_approved', executionStarted: true }));
});
