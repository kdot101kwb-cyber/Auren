'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const { initializeTestEnvironment, assertFails } = require('@firebase/rules-unit-testing');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-emulator';
const collections = [
  'knowledgeInbox',
  'evidenceVault',
  'sourceProfiles',
  'researchReadingQueue',
  'languageGlossary',
];
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

test('Knowledge & Information records cannot be accessed directly by Firestore clients', async (t) => {
  for (const collection of collections) {
    await t.test(collection, async () => {
      const pathForOwner = `users/knowledge-owner/${collection}/record-1`;
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc(pathForOwner).set({
          title: 'Seeded server-side record',
          updatedAt: firebase.firestore.Timestamp.now(),
        });
      });

      const ownerDb = testEnv.authenticatedContext('knowledge-owner').firestore();
      const otherDb = testEnv.authenticatedContext('knowledge-other').firestore();
      const anonymousDb = testEnv.unauthenticatedContext().firestore();

      // These collections are deliberately callable-only: Admin SDK callables
      // enforce UID scoping, while clients must not bypass that API via Firestore.
      await assertFails(ownerDb.doc(pathForOwner).get());
      await assertFails(otherDb.doc(pathForOwner).get());
      await assertFails(anonymousDb.doc(pathForOwner).get());
      await assertFails(ownerDb.doc(`users/knowledge-owner/${collection}/client-write`).set({
        title: 'Direct client write',
        updatedAt: firebase.firestore.Timestamp.now(),
      }));
    });
  }
});
