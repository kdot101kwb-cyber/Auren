'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
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

async function seedPost(postId, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(`posts/${postId}`).set({
      authorId: 'moment-owner',
      text: 'A living moment',
      contentType: 'moment',
      contextLabel: 'Living Moment • updates welcome',
      createdAt: firebase.firestore.Timestamp.now(),
      ...overrides,
    });
  });
}

function updateRef(uid, postId, updateId = 'update-1') {
  return testEnv.authenticatedContext(uid).firestore()
    .doc(`posts/${postId}/moment_updates/${updateId}`);
}

function updateData(uid, overrides = {}) {
  return {
    authorId: uid,
    text: 'Reached the next milestone',
    createdAt: firebase.firestore.Timestamp.now(),
    ...overrides,
  };
}

test('Living Moment owner can add a valid update', async () => {
  await seedPost('living-owner');
  const ref = updateRef('moment-owner', 'living-owner');
  await assertSucceeds(ref.set(updateData('moment-owner')));
  const saved = await ref.get();
  assert.equal(saved.data().text, 'Reached the next milestone');
});

test('another user cannot add an update to someone else’s moment', async () => {
  await seedPost('living-other');
  await assertFails(updateRef('intruder', 'living-other').set(updateData('intruder')));
});

test('updates cannot be added to a regular moment', async () => {
  await seedPost('regular-moment', {
    contextLabel: 'Shared with AUREN',
  });
  await assertFails(updateRef('moment-owner', 'regular-moment').set(updateData('moment-owner')));
});

test('empty and oversized updates are rejected', async () => {
  await seedPost('living-invalid');
  await assertFails(updateRef('moment-owner', 'living-invalid').set(
    updateData('moment-owner', { text: '' }),
  ));
  await assertFails(updateRef('moment-owner', 'living-invalid', 'too-long').set(
    updateData('moment-owner', { text: 'x'.repeat(1201) }),
  ));
});

test('signed-in users can read updates, but unauthenticated users cannot', async () => {
  await seedPost('living-read');
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('posts/living-read/moment_updates/seeded').set(
      updateData('moment-owner'),
    );
  });
  await assertSucceeds(updateRef('viewer', 'living-read', 'seeded').get());
  await assertFails(testEnv.unauthenticatedContext().firestore()
    .doc('posts/living-read/moment_updates/seeded').get());
});
