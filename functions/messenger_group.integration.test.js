'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');

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

async function seedGroupConversation(conversationId, memberIds) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc(`conversations/${conversationId}`).set({
      memberIds,
      title: 'AUREN Random Group',
      isAi: false,
      type: 'group',
      ownerId: memberIds[0],
      updatedAt: firebase.firestore.Timestamp.now(),
      lastMessage: '',
      lastMessageAt: firebase.firestore.Timestamp.now(),
      lastMessageSenderId: memberIds[0],
    });
  });
}

function conversationDb(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

test('group members can read the group conversation while outsiders cannot', async () => {
  await seedGroupConversation('messenger-group-read', ['group-owner', 'group-member', 'group-member-2']);

  await assertSucceeds(conversationDb('group-owner').doc('conversations/messenger-group-read').get());
  await assertSucceeds(conversationDb('group-member').doc('conversations/messenger-group-read').get());
  await assertFails(conversationDb('outsider').doc('conversations/messenger-group-read').get());
  await assertFails(testEnv.unauthenticatedContext().firestore()
    .doc('conversations/messenger-group-read').get());
});

test('only a group member can send and read messages in the group chat', async () => {
  await seedGroupConversation('messenger-group-messages', ['owner-msg', 'member-msg', 'member-msg-2']);
  const ownerMessages = conversationDb('owner-msg')
    .collection('conversations/messenger-group-messages/messages');
  const memberMessages = conversationDb('member-msg')
    .collection('conversations/messenger-group-messages/messages');
  const outsiderMessages = conversationDb('outsider-msg')
    .collection('conversations/messenger-group-messages/messages');
  const message = {
    senderId: 'member-msg',
    text: 'Hello from the group',
    createdAt: firebase.firestore.Timestamp.now(),
    isAi: false,
  };

  await assertSucceeds(memberMessages.doc('valid-message').set(message));
  await assertSucceeds(ownerMessages.doc('valid-message').get());
  await assertFails(outsiderMessages.doc('valid-message').get());
  await assertFails(outsiderMessages.doc('forged-message').set({
    ...message,
    senderId: 'member-msg',
  }));
});

test('group messages cannot spoof sender identity or be edited after send', async () => {
  await seedGroupConversation('messenger-group-integrity', ['owner-integrity', 'member-integrity', 'third-integrity']);
  const messages = conversationDb('member-integrity')
    .collection('conversations/messenger-group-integrity/messages');

  await assertFails(messages.doc('spoofed').set({
    senderId: 'owner-integrity',
    text: 'Forged sender',
    createdAt: firebase.firestore.Timestamp.now(),
    isAi: false,
  }));

  await assertSucceeds(messages.doc('immutable').set({
    senderId: 'member-integrity',
    text: 'Original',
    createdAt: firebase.firestore.Timestamp.now(),
    isAi: false,
  }));
  await assertFails(messages.doc('immutable').update({text: 'Edited after send'}));
  await assertFails(messages.doc('immutable').delete());
});
