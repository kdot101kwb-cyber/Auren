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
      host: process.env.FIRESTORE_EMULATOR_HOST?.split(':')[0] || '127.0.0.1',
      port: Number(process.env.FIRESTORE_EMULATOR_HOST?.split(':')[1] || 8080),
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

test('signed-in user can create a bounded report with their own reporter identity', async () => {
  const db = dbFor('reporter-a');
  await assertSucceeds(db.doc('reports/report-valid').set({
    reporterUid: 'reporter-a',
    reportedUid: 'user-b',
    reason: 'Harassment in a community',
    contentId: 'post-1',
    contentType: 'post',
    status: 'open',
    createdAt: firebase.firestore.Timestamp.now(),
  }));
});

test('report creation rejects forged reporter identity and self-reporting', async () => {
  const db = dbFor('reporter-a');
  const now = firebase.firestore.Timestamp.now();
  await assertFails(db.doc('reports/forged-reporter').set({
    reporterUid: 'user-c',
    reportedUid: 'user-b',
    reason: 'A report',
    status: 'open',
    createdAt: now,
  }));
  await assertFails(db.doc('reports/self-report').set({
    reporterUid: 'reporter-a',
    reportedUid: 'reporter-a',
    reason: 'A report',
    status: 'open',
    createdAt: now,
  }));
});

test('report creation rejects malformed status, extra fields, and oversized reason', async () => {
  const db = dbFor('reporter-a');
  const now = firebase.firestore.Timestamp.now();
  await assertFails(db.doc('reports/wrong-status').set({
    reporterUid: 'reporter-a', reportedUid: 'user-b', reason: 'Reason',
    status: 'resolved', createdAt: now,
  }));
  await assertFails(db.doc('reports/extra-field').set({
    reporterUid: 'reporter-a', reportedUid: 'user-b', reason: 'Reason',
    status: 'open', createdAt: now, moderatedBy: 'reporter-a',
  }));
  await assertFails(db.doc('reports/long-reason').set({
    reporterUid: 'reporter-a', reportedUid: 'user-b', reason: 'x'.repeat(501),
    status: 'open', createdAt: now,
  }));
});

test('users cannot read or update reports and case-event writes remain denied without rules', async () => {
  const db = dbFor('moderator-a');
  const anonymousDb = testEnv.unauthenticatedContext().firestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('reports/seeded-report').set({
      reporterUid: 'reporter-a', reportedUid: 'user-b', reason: 'Reason',
      status: 'open', createdAt: firebase.firestore.Timestamp.now(),
    });
  });
  await assertFails(anonymousDb.doc('reports/seeded-report').get());
  await assertFails(anonymousDb.collection('reports').get());
  await assertFails(db.doc('reports/seeded-report').get());
  await assertFails(db.collection('reports').get());
  await assertFails(db.doc('reports/seeded-report').update({
    status: 'resolved', moderatedBy: 'moderator-a',
    moderatedAt: firebase.firestore.Timestamp.now(), moderationNote: 'Reviewed',
  }));
  await assertFails(db.doc('community_case_events/event-1').set({
    entityType: 'report', entityId: 'seeded-report', actorUid: 'moderator-a',
    fromStatus: 'open', toStatus: 'resolved', note: 'Reviewed',
    createdAt: firebase.firestore.Timestamp.now(),
  }));
});

test('appeal workflows remain denied until explicit owner and moderator rules exist', async () => {
  const appellant = dbFor('appellant-a');
  const moderator = dbFor('moderator-a');
  const now = firebase.firestore.Timestamp.now();

  await assertFails(appellant.doc('community_case_appeals/report-1__appellant-a').set({
    reportId: 'report-1',
    appellantUid: 'appellant-a',
    reason: 'Please review this moderation decision.',
    status: 'pending',
    createdAt: now,
  }));

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().doc('community_case_appeals/report-1__appellant-a').set({
      reportId: 'report-1',
      appellantUid: 'appellant-a',
      reason: 'Please review this moderation decision.',
      status: 'pending',
      createdAt: now,
    });
  });

  await assertFails(appellant.doc('community_case_appeals/report-1__appellant-a').get());
  await assertFails(moderator.collection('community_case_appeals').where('status', '==', 'pending').get());
  await assertFails(moderator.doc('community_case_appeals/report-1__appellant-a').update({
    status: 'accepted',
    reviewedBy: 'moderator-a',
    reviewedAt: now,
    reviewNote: 'Reviewed',
  }));
  await assertFails(moderator.doc('community_case_events/appeal-event-1').set({
    entityType: 'appeal',
    entityId: 'report-1__appellant-a',
    actorUid: 'moderator-a',
    fromStatus: 'pending',
    toStatus: 'accepted',
    note: 'Reviewed',
    createdAt: now,
  }));
});
