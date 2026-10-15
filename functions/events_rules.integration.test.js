'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const fs = require('node:fs');
const path = require('node:path');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-emulator';
let env;

test.before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
    },
  });
});

test.after(async () => {
  if (env) await env.cleanup();
});

async function seedEvent(eventId, attendees) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const startsAt = firebase.firestore.Timestamp.fromMillis(Date.now() + 86400000);
    const endsAt = firebase.firestore.Timestamp.fromMillis(Date.now() + 90000000);
    await db.doc(`events/${eventId}`).set({
      ownerId: 'event-host',
      title: 'Rules test event',
      description: '',
      startsAt,
      endsAt,
      capacity: 2,
      confirmedCount: attendees.filter((a) => a.status === 'going').length,
      visibility: 'public',
      createdAt: firebase.firestore.Timestamp.now(),
      updatedAt: firebase.firestore.Timestamp.now(),
    });
    for (const attendee of attendees) {
      await db.doc(`events/${eventId}/attendees/${attendee.userId}`).set({
        userId: attendee.userId,
        status: attendee.status,
        updatedAt: firebase.firestore.Timestamp.now(),
      });
    }
  });
}

function dbFor(uid) {
  return env.authenticatedContext(uid).firestore();
}

test('confirmed attendee can cancel only with the matching count decrement', async () => {
  await seedEvent('cancel-atomic', [{userId: 'attendee-a', status: 'going'}]);
  const db = dbFor('attendee-a');
  const event = db.doc('events/cancel-atomic');
  const attendee = db.doc('events/cancel-atomic/attendees/attendee-a');
  await assertSucceeds(db.runTransaction(async (tx) => {
    tx.update(event, {
      confirmedCount: 0,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(attendee, {
      status: 'cancelled',
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    });
  }));
});

test('confirmed count cannot be decremented without cancelling the attendee', async () => {
  await seedEvent('count-only', [{userId: 'attendee-b', status: 'going'}]);
  const db = dbFor('attendee-b');
  await assertFails(db.doc('events/count-only').update({
    confirmedCount: 0,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
  }));
});

test('waitlisted attendee can cancel without changing confirmed count', async () => {
  await seedEvent('waitlist-cancel', [
    {userId: 'attendee-c', status: 'going'},
    {userId: 'attendee-d', status: 'waitlisted'},
  ]);
  const db = dbFor('attendee-d');
  await assertSucceeds(db.doc('events/waitlist-cancel/attendees/attendee-d').update({
    status: 'cancelled',
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
  }));
});

test('cancelled attendee can re-register when the count is incremented atomically', async () => {
  await seedEvent('reregister-atomic', [{userId: 'attendee-r', status: 'cancelled'}]);
  const db = dbFor('attendee-r');
  const event = db.doc('events/reregister-atomic');
  const attendee = db.doc('events/reregister-atomic/attendees/attendee-r');
  await assertSucceeds(db.runTransaction(async (tx) => {
    tx.update(event, {
      confirmedCount: 1,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    });
    tx.update(attendee, {
      status: 'going',
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
    });
  }));
});

test('cancelled attendee cannot re-register without a matching count increment', async () => {
  await seedEvent('reregister-count-only', [{userId: 'attendee-s', status: 'cancelled'}]);
  const db = dbFor('attendee-s');
  await assertFails(db.doc('events/reregister-count-only/attendees/attendee-s').update({
    status: 'going',
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
  }));
});

test('attendee cannot promote themselves by changing RSVP to going', async () => {
  await seedEvent('self-promote', [
    {userId: 'attendee-e', status: 'going'},
    {userId: 'attendee-f', status: 'waitlisted'},
  ]);
  const db = dbFor('attendee-f');
  await assertFails(db.doc('events/self-promote/attendees/attendee-f').update({
    status: 'going',
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
  }));
});

test('attendee cannot cancel another user RSVP', async () => {
  await seedEvent('other-cancel', [{userId: 'attendee-g', status: 'going'}]);
  const db = dbFor('attacker');
  await assertFails(db.doc('events/other-cancel/attendees/attendee-g').update({
    status: 'cancelled',
    updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
  }));
});
