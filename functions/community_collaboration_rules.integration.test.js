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

function dbFor(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

async function seed(pathname, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc(pathname).set(data);
  });
}

test('club creator can create a public club with only themselves as initial member', async () => {
  const db = dbFor('club-owner');
  const now = firebase.firestore.Timestamp.now();
  await assertSucceeds(db.doc('community_clubs/club-1').set({
    ownerId: 'club-owner',
    name: 'Readers',
    description: 'Read together',
    category: 'Books',
    visibility: 'public',
    memberIds: ['club-owner'],
    memberCount: 1,
    createdAt: now,
  }));

  await assertFails(db.doc('community_clubs/forged-owner').set({
    ownerId: 'someone-else',
    name: 'Readers',
    description: '',
    category: 'Books',
    visibility: 'public',
    memberIds: ['club-owner'],
    memberCount: 1,
    createdAt: now,
  }));
});

test('club member can join, but cannot remove another member or leave as owner', async () => {
  const now = firebase.firestore.Timestamp.now();
  await seed('community_clubs/club-membership', {
    ownerId: 'club-owner',
    name: 'Chess',
    description: '',
    category: 'Games',
    visibility: 'public',
    memberIds: ['club-owner', 'member-a'],
    memberCount: 2,
    createdAt: now,
  });

  await assertSucceeds(dbFor('member-b').doc('community_clubs/club-membership').update({
    memberIds: ['club-owner', 'member-a', 'member-b'],
    memberCount: 3,
  }));

  await assertFails(dbFor('member-b').doc('community_clubs/club-membership').update({
    memberIds: ['club-owner', 'member-b'],
    memberCount: 2,
  }));

  await assertFails(dbFor('club-owner').doc('community_clubs/club-membership').update({
    memberIds: ['member-a'],
    memberCount: 1,
  }));

  await seed('community_clubs/private-club', {
    ownerId: 'private-owner',
    name: 'Private group',
    description: '',
    category: 'Private',
    visibility: 'private',
    memberIds: ['private-owner'],
    memberCount: 1,
    createdAt: now,
  });
  await assertFails(dbFor('outsider').doc('community_clubs/private-club').update({
    memberIds: ['private-owner', 'outsider'],
    memberCount: 2,
  }));

  await seed('community_clubs/legacy-duplicate-members', {
    ownerId: 'legacy-owner',
    name: 'Legacy club',
    description: '',
    category: 'Books',
    visibility: 'public',
    memberIds: ['legacy-owner', 'legacy-member', 'legacy-member'],
    memberCount: 3,
    createdAt: now,
  });
  await assertFails(dbFor('new-member').doc('community_clubs/legacy-duplicate-members').update({
    memberIds: ['legacy-owner', 'legacy-member', 'legacy-member', 'new-member'],
    memberCount: 4,
  }));
});

test('only the collaboration-space owner can add a member', async () => {
  const now = firebase.firestore.Timestamp.now();
  await seed('collaboration_spaces/space-1', {
    ownerId: 'space-owner',
    title: 'Garden team',
    description: 'Plan together',
    memberIds: ['space-owner'],
    createdAt: now,
  });

  await assertSucceeds(dbFor('space-owner').doc('collaboration_spaces/space-1').update({
    memberIds: ['space-owner', 'invitee'],
  }));

  await assertFails(dbFor('invitee').doc('collaboration_spaces/space-1').update({
    memberIds: ['space-owner', 'invitee', 'another-user'],
  }));

  await assertFails(dbFor('space-owner').doc('collaboration_spaces/space-1').update({
    memberIds: ['space-owner', 'space-owner'],
  }));

  await assertFails(dbFor('space-owner').doc('collaboration_spaces/space-1').update({
    title: 'Hijacked title',
    memberIds: ['space-owner', 'new-member'],
  }));
  await assertFails(dbFor('space-owner').doc('collaboration_spaces/space-1').update({
    ownerId: 'attacker',
    memberIds: ['space-owner', 'invitee', 'new-member'],
  }));
  await assertFails(dbFor('space-owner').doc('collaboration_spaces/space-1').update({
    description: 'Changed without authorization',
    memberIds: ['space-owner', 'invitee', 'new-member'],
  }));
  await assertFails(dbFor('space-owner').doc('collaboration_spaces/space-1').update({
    memberIds: ['space-owner', 'invitee', 'invitee'],
  }));

  // Space membership is owner-managed and additive in this contract: the
  // owner cannot silently remove existing members, and an invitee cannot
  // self-promote or modify another member's access.
  await assertFails(dbFor('space-owner').doc('collaboration_spaces/space-1').update({
    memberIds: ['space-owner'],
  }));
  await assertFails(dbFor('invitee').doc('collaboration_spaces/space-1').update({
    memberIds: ['space-owner', 'invitee'],
  }));
  // Owners may add one new member per update while preserving all existing members.
  await assertSucceeds(dbFor('space-owner').doc('collaboration_spaces/space-1').update({
    memberIds: ['space-owner', 'invitee', 'third-user'],
  }));

  // A single update cannot add multiple members at once.
  await assertFails(dbFor('space-owner').doc('collaboration_spaces/space-1').update({
    memberIds: ['space-owner', 'invitee', 'third-user', 'fourth-user', 'fifth-user'],
  }));
});

test('volunteer can add only their own identity and cannot change cause metadata', async () => {
  const now = firebase.firestore.Timestamp.now();
  await seed('volunteer_causes/cause-1', {
    ownerId: 'cause-owner',
    title: 'Park cleanup',
    description: 'Clean the park',
    category: 'Environment',
    status: 'open',
    volunteerIds: ['cause-owner'],
    createdAt: now,
  });

  await assertSucceeds(dbFor('volunteer-a').doc('volunteer_causes/cause-1').update({
    volunteerIds: ['cause-owner', 'volunteer-a'],
  }));

  await assertFails(dbFor('volunteer-b').doc('volunteer_causes/cause-1').update({
    volunteerIds: ['cause-owner', 'volunteer-a', 'someone-else'],
  }));

  await assertFails(dbFor('volunteer-b').doc('volunteer_causes/cause-1').update({
    title: 'Hijacked cause',
    volunteerIds: ['cause-owner', 'volunteer-a', 'volunteer-b'],
  }));

  await seed('volunteer_causes/legacy-duplicate-volunteers', {
    ownerId: 'legacy-cause-owner',
    title: 'Legacy cause',
    description: 'Existing legacy record',
    category: 'Community',
    status: 'open',
    volunteerIds: ['legacy-cause-owner', 'legacy-volunteer', 'legacy-volunteer'],
    createdAt: now,
  });
  await assertFails(dbFor('new-volunteer').doc('volunteer_causes/legacy-duplicate-volunteers').update({
    volunteerIds: ['legacy-cause-owner', 'legacy-volunteer', 'legacy-volunteer', 'new-volunteer'],
  }));
});

test('reads require authentication and collaboration spaces require membership', async () => {
  const now = firebase.firestore.Timestamp.now();
  await seed('community_clubs/read-club', {
    ownerId: 'read-owner',
    name: 'Public club',
    description: '',
    category: 'Books',
    visibility: 'public',
    memberIds: ['read-owner'],
    memberCount: 1,
    createdAt: now,
  });
  await seed('collaboration_spaces/private-space', {
    ownerId: 'space-owner',
    title: 'Private space',
    description: '',
    memberIds: ['space-owner'],
    createdAt: now,
  });
  await seed('volunteer_causes/closed-cause', {
    ownerId: 'cause-owner',
    title: 'Closed cause',
    description: 'No longer accepting volunteers',
    category: 'Community',
    status: 'closed',
    volunteerIds: ['cause-owner'],
    createdAt: now,
  });

  await assertSucceeds(dbFor('signed-user').doc('community_clubs/read-club').get());
  await assertFails(testEnv.unauthenticatedContext().firestore().doc('community_clubs/read-club').get());
  await assertFails(dbFor('outsider').doc('collaboration_spaces/private-space').get());
  await assertSucceeds(dbFor('space-owner').doc('collaboration_spaces/private-space').get());
  await assertFails(dbFor('signed-user').doc('volunteer_causes/closed-cause').get());
});

test('community members can join public communities but cannot join private legacy communities', async () => {
  const now = firebase.firestore.Timestamp.now();
  await seed('communities/public-community-join', {
    ownerId: 'community-owner',
    name: 'Public community',
    description: '',
    topic: 'Books',
    visibility: 'public',
    memberIds: ['community-owner'],
    memberCount: 1,
    createdAt: now,
  });
  await seed('communities/private-community-join', {
    ownerId: 'private-community-owner',
    name: 'Private community',
    description: '',
    topic: 'Private',
    visibility: 'private',
    memberIds: ['private-community-owner'],
    memberCount: 1,
    createdAt: now,
  });

  await assertSucceeds(dbFor('new-member').doc('communities/public-community-join').update({
    memberIds: ['community-owner', 'new-member'],
    memberCount: 2,
  }));
  await assertFails(dbFor('outsider').doc('communities/private-community-join').update({
    memberIds: ['private-community-owner', 'outsider'],
    memberCount: 2,
  }));
});


test('community poll votes can only add one member vote and increment exactly one counter', async () => {
  const now = firebase.firestore.Timestamp.now();
  await seed('communities/poll-community', {
    ownerId: 'poll-owner',
    name: 'Poll community',
    description: '',
    topic: 'Governance',
    visibility: 'public',
    memberIds: ['poll-owner', 'poll-member', 'second-member'],
    memberCount: 3,
    createdAt: now,
  });
  await seed('community_polls/poll-guarded', {
    ownerId: 'poll-owner',
    communityId: 'poll-community',
    question: 'Which option?',
    options: ['A', 'B'],
    votes: { '0': 0, '1': 0 },
    voters: {},
    createdAt: now,
  });

  const poll = dbFor('poll-member').doc('community_polls/poll-guarded');
  await assertSucceeds(poll.update({
    votes: { '0': 1, '1': 0 },
    voters: { 'poll-member': '0' },
  }));

  await seed('community_polls/poll-forged-count', {
    ownerId: 'poll-owner', communityId: 'poll-community', question: 'Which option?',
    options: ['A', 'B'], votes: { '0': 0, '1': 0 }, voters: {}, createdAt: now,
  });
  await assertFails(dbFor('poll-member').doc('community_polls/poll-forged-count').update({
    votes: { '0': 9, '1': 4 }, voters: { 'poll-member': '0' },
  }));

  await seed('community_polls/poll-forged-choice', {
    ownerId: 'poll-owner', communityId: 'poll-community', question: 'Which option?',
    options: ['A', 'B'], votes: { '0': 0, '1': 0 }, voters: {}, createdAt: now,
  });
  await assertFails(dbFor('poll-member').doc('community_polls/poll-forged-choice').update({
    votes: { '0': 0, '1': 1 }, voters: { 'poll-member': '0' },
  }));

  await seed('community_polls/poll-metadata-tamper', {
    ownerId: 'poll-owner', communityId: 'poll-community', question: 'Which option?',
    options: ['A', 'B'], votes: { '0': 0, '1': 0 }, voters: {}, createdAt: now,
  });
  await assertFails(dbFor('poll-member').doc('community_polls/poll-metadata-tamper').update({
    question: 'Changed question', votes: { '0': 1, '1': 0 }, voters: { 'poll-member': '0' },
  }));

  await assertFails(dbFor('poll-member').doc('community_polls/poll-guarded').update({
    votes: { '0': 2, '1': 0 },
    voters: { 'poll-member': '0', 'second-member': '0' },
  }));
  await assertFails(dbFor('outsider').doc('community_polls/poll-guarded').get());
});


test('community poll creation cannot seed forged vote totals', async () => {
  const now = firebase.firestore.Timestamp.now();
  await seed('communities/poll-create-community', {
    ownerId: 'poll-owner',
    name: 'Poll creation community',
    description: '',
    topic: 'Governance',
    visibility: 'public',
    memberIds: ['poll-owner', 'poll-member'],
    memberCount: 2,
    createdAt: now,
  });

  await assertSucceeds(dbFor('poll-member').doc('community_polls/poll-valid-create').set({
    ownerId: 'poll-member',
    communityId: 'poll-create-community',
    question: 'Choose one',
    options: ['A', 'B'],
    votes: { '0': 0, '1': 0 },
    voters: {},
    createdAt: now,
  }));

  await assertFails(dbFor('poll-member').doc('community_polls/poll-forged-create').set({
    ownerId: 'poll-member',
    communityId: 'poll-create-community',
    question: 'Choose one',
    options: ['A', 'B'],
    votes: { '0': 50, '1': 12 },
    voters: {},
    createdAt: now,
  }));

  await assertFails(dbFor('poll-member').doc('community_polls/poll-non-string-option').set({
    ownerId: 'poll-member', communityId: 'poll-create-community', question: 'Choose one',
    options: ['A', 42], votes: { '0': 0, '1': 0 }, voters: {}, createdAt: now,
  }));

  await assertFails(dbFor('poll-member').doc('community_polls/poll-oversized-option').set({
    ownerId: 'poll-member', communityId: 'poll-create-community', question: 'Choose one',
    options: ['A', 'x'.repeat(101)], votes: { '0': 0, '1': 0 }, voters: {}, createdAt: now,
  }));

  await assertFails(dbFor('poll-member').doc('community_polls/poll-empty-option').set({
    ownerId: 'poll-member', communityId: 'poll-create-community', question: 'Choose one',
    options: ['A', ''], votes: { '0': 0, '1': 0 }, voters: {}, createdAt: now,
  }));
});
