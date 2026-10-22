'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const fs = require('node:fs');
const path = require('node:path');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-ai-privacy-emulator';
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

async function seedConversation() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('conversations/ai-privacy-conversation').set({
      memberIds: ['ai-privacy-owner'],
      title: 'AUREN AI',
      isAi: true,
      type: 'ai',
      updatedAt: firebase.firestore.Timestamp.now(),
    });
    await db.doc('conversations/ai-privacy-conversation/messages/ai_seed').set({
      senderId: 'auren-ai',
      text: 'server-authored response',
      createdAt: firebase.firestore.Timestamp.now(),
      isAi: true,
    });
  });
}

test('clients cannot read or write private AI idempotency request records', async () => {
  const db = testEnv.authenticatedContext('ai-privacy-owner').firestore();
  const ref = db.doc('users/ai-privacy-owner/ai_requests/request-1');
  await assertFails(ref.get());
  await assertFails(ref.set({status: 'completed', response: {text: 'forged'}}));
});

test('clients cannot read or forge global AI provider health records', async () => {
  const db = testEnv.authenticatedContext('ai-privacy-owner').firestore();
  const ref = db.doc('ai_provider_health/openrouter');
  await assertFails(ref.get());
  await assertFails(ref.set({lastError: 'forged', cooldownUntilMs: 0}));
});

test('AI conversation members can read server-authored AI messages', async () => {
  await seedConversation();
  const db = testEnv.authenticatedContext('ai-privacy-owner').firestore();
  await assertSucceeds(
    db.doc('conversations/ai-privacy-conversation/messages/ai_seed').get(),
  );
});

test('non-members cannot read AI conversation messages', async () => {
  await seedConversation();
  const db = testEnv.authenticatedContext('ai-privacy-outsider').firestore();
  await assertFails(
    db.doc('conversations/ai-privacy-conversation/messages/ai_seed').get(),
  );
});

test('clients cannot impersonate the server AI sender', async () => {
  await seedConversation();
  const db = testEnv.authenticatedContext('ai-privacy-owner').firestore();
  const ref = db.doc('conversations/ai-privacy-conversation/messages/ai_forged');
  await assertFails(ref.set({
    senderId: 'auren-ai',
    text: 'forged response',
    createdAt: firebase.firestore.Timestamp.now(),
    isAi: true,
  }));
});
