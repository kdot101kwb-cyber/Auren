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

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-profile-privacy-rules';
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

function profileMode(ownerId, overrides = {}) {
  return {
    mode: 'professional',
    headline: 'Builder',
    bio: 'AUREN profile',
    skills: [],
    interests: [],
    links: [],
    goals: [],
    languages: [],
    services: [],
    achievements: [],
    discoverable: true,
    showContact: true,
    updatedAt: firebase.firestore.Timestamp.now(),
    ...overrides,
  };
}

function db(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

async function seed(ownerId, modeId, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore()
      .doc(`users/${ownerId}/profile_modes/${modeId}`)
      .set(data);
  });
}

test('discoverable profile mode with contact sharing enabled is readable by another signed-in user', async () => {
  await seed('profile-owner-a', 'professional', profileMode('profile-owner-a', {
    links: [{ label: 'Portfolio', url: 'https://example.com' }],
    showContact: true,
  }));

  const ref = db('profile-viewer-a')
    .doc('users/profile-owner-a/profile_modes/professional');
  const snap = await assertSucceeds(ref.get());
  assert.equal(snap.data().showContact, true);
});

test('discoverable profile mode with contact sharing disabled and no links remains readable', async () => {
  await seed('profile-owner-b', 'professional', profileMode('profile-owner-b', {
    links: [],
    showContact: false,
  }));

  await assertSucceeds(
    db('profile-viewer-b').doc('users/profile-owner-b/profile_modes/professional').get(),
  );
});

test('recursive profile_modes rule cannot bypass contact privacy for legacy documents with links', async () => {
  await seed('profile-owner-c', 'professional', profileMode('profile-owner-c', {
    links: [{ label: 'Private contact', url: 'https://private.example.com' }],
    showContact: false,
  }));

  await assertFails(
    db('profile-viewer-c').doc('users/profile-owner-c/profile_modes/professional').get(),
  );
});

test('owner can still read a legacy profile mode that violates current contact settings', async () => {
  await seed('profile-owner-d', 'professional', profileMode('profile-owner-d', {
    links: [{ label: 'Private contact', url: 'https://private.example.com' }],
    showContact: false,
  }));

  const snap = await assertSucceeds(
    db('profile-owner-d').doc('users/profile-owner-d/profile_modes/professional').get(),
  );
  assert.equal(snap.data().links.length, 1);
});

test('owner cannot create or update a profile mode with links while contact sharing is disabled', async () => {
  const ref = db('profile-owner-e')
    .doc('users/profile-owner-e/profile_modes/professional');
  const invalid = profileMode('profile-owner-e', {
    links: [{ label: 'Portfolio', url: 'https://example.com' }],
    showContact: false,
  });

  await assertFails(ref.set(invalid));
  await assertSucceeds(ref.set(profileMode('profile-owner-e', {
    links: [],
    showContact: false,
  })));
  await assertFails(ref.update({
    links: [{ label: 'Portfolio', url: 'https://example.com' }],
    updatedAt: firebase.firestore.Timestamp.now(),
  }));
});

test('unauthenticated clients cannot read profile modes', async () => {
  await seed('profile-owner-f', 'professional', profileMode('profile-owner-f'));
  await assertFails(
    testEnv.unauthenticatedContext().firestore()
      .doc('users/profile-owner-f/profile_modes/professional').get(),
  );
});

test('public collection queries cannot enumerate modes without constraining contact visibility', async () => {
  await seed('profile-owner-g', 'professional', profileMode('profile-owner-g', {
    links: [{ label: 'Private contact', url: 'https://private.example.com' }],
    showContact: false,
  }));

  await assertFails(
    db('profile-viewer-g')
      .collection('users/profile-owner-g/profile_modes')
      .where('discoverable', '==', true)
      .get(),
  );
});

test('undiscoverable profile mode is hidden from other users but remains owner-readable', async () => {
  await seed('profile-owner-h', 'professional', profileMode('profile-owner-h', {
    discoverable: false,
    links: [],
    showContact: false,
  }));

  await assertFails(
    db('profile-viewer-h').doc('users/profile-owner-h/profile_modes/professional').get(),
  );
  await assertSucceeds(
    db('profile-owner-h').doc('users/profile-owner-h/profile_modes/professional').get(),
  );
});

test('legacy profile modes missing contact visibility fields fail closed for public readers', async () => {
  const legacy = profileMode('profile-owner-i', {
    links: [{ label: 'Unclassified contact', url: 'https://private.example.com' }],
  });
  delete legacy.showContact;
  await seed('profile-owner-i', 'professional', legacy);

  await assertFails(
    db('profile-viewer-i').doc('users/profile-owner-i/profile_modes/professional').get(),
  );
  await assertSucceeds(
    db('profile-owner-i').doc('users/profile-owner-i/profile_modes/professional').get(),
  );
});

