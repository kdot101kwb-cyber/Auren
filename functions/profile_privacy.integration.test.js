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

async function seed(pathName, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(pathName).set(data);
  });
}

function db(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function publishedProfile(mode = 'professional', overrides = {}) {
  return {
    mode,
    headline: 'Public headline',
    bio: 'Public biography',
    skills: ['Dart'],
    interests: ['Music'],
    goals: ['Build'],
    languages: ['Arabic'],
    services: ['Consulting'],
    achievements: ['Demo'],
    discoverable: true,
    showContact: false,
    updatedAt: firebase.firestore.Timestamp.now(),
    ...overrides,
  };
}

test('private source profile modes are owner-only even when marked discoverable', async () => {
  await seed('users/profile-owner/profile_modes/professional', {
    ...publishedProfile(),
    links: ['private-link'],
  });
  await assertSucceeds(db('profile-owner').doc('users/profile-owner/profile_modes/professional').get());
  await assertFails(db('other-viewer').doc('users/profile-owner/profile_modes/professional').get());
});

test('signed-in viewers can read only a published public projection', async () => {
  await seed('users/profile-owner/public_profile_modes/professional', publishedProfile());
  const snap = await assertSucceeds(
    db('other-viewer').doc('users/profile-owner/public_profile_modes/professional').get(),
  );
  assert.equal(snap.data().headline, 'Public headline');
  assert.equal(Object.hasOwn(snap.data(), 'links'), false);
});

test('undiscoverable profiles are not readable from the public projection path', async () => {
  await seed('users/profile-owner/public_profile_modes/professional', publishedProfile('professional', {
    discoverable: false,
  }));
  await assertFails(db('other-viewer').doc('users/profile-owner/public_profile_modes/professional').get());
});

test('owner cannot publish private-only fields into the public projection', async () => {
  const invalid = publishedProfile('professional', { links: ['private-link'] });
  await assertFails(
    db('profile-owner').doc('users/profile-owner/public_profile_modes/professional').set(invalid),
  );
});

test('other users cannot create or alter public profile projections', async () => {
  await assertFails(
    db('attacker').doc('users/profile-owner/public_profile_modes/professional').set(publishedProfile()),
  );
  await seed('users/profile-owner/public_profile_modes/professional', publishedProfile());
  await assertFails(
    db('attacker').doc('users/profile-owner/public_profile_modes/professional').update({
      headline: 'Tampered',
    }),
  );
});

test('public discovery query returns published projections but not private source documents', async () => {
  await seed('users/profile-owner/profile_modes/creator', publishedProfile('creator'));
  await seed('users/profile-owner/public_profile_modes/creator', publishedProfile('creator'));
  const snapshot = await assertSucceeds(
    db('other-viewer').collectionGroup('public_profile_modes')
      .where('discoverable', '==', true).get(),
  );
  assert.ok(snapshot.docs.some((doc) =>
    doc.ref.path === 'users/profile-owner/public_profile_modes/creator'));
  assert.ok(snapshot.docs.every((doc) => doc.ref.path.includes('/public_profile_modes/')));
});


test('public active-mode settings are readable only while discoverable', async () => {
  await seed('users/profile-owner/public_profile_settings/current', {
    activeMode: 'professional',
    discoverable: true,
    updatedAt: firebase.firestore.Timestamp.now(),
  });
  const visible = await assertSucceeds(
    db('other-viewer').doc('users/profile-owner/public_profile_settings/current').get(),
  );
  assert.equal(visible.data().activeMode, 'professional');

  await seed('users/hidden-owner/public_profile_settings/current', {
    activeMode: 'personal',
    discoverable: false,
    updatedAt: firebase.firestore.Timestamp.now(),
  });
  await assertFails(
    db('other-viewer').doc('users/hidden-owner/public_profile_settings/current').get(),
  );
  await assertSucceeds(
    db('hidden-owner').doc('users/hidden-owner/public_profile_settings/current').get(),
  );
});

test('only the profile owner may write public active-mode settings', async () => {
  const settings = {
    activeMode: 'creator',
    discoverable: true,
    updatedAt: firebase.firestore.Timestamp.now(),
  };
  await assertFails(
    db('attacker').doc('users/profile-owner/public_profile_settings/current').set(settings),
  );
  await assertSucceeds(
    db('profile-owner').doc('users/profile-owner/public_profile_settings/current').set(settings),
  );
});
