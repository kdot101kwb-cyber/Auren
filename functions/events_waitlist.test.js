'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { _test } = require('./events_waitlist');

test('only confirmed-to-cancelled transitions trigger promotion', () => {
  assert.equal(_test.isConfirmedCancellation({status: 'going'}, {status: 'cancelled'}), true);
  assert.equal(_test.isConfirmedCancellation({status: 'waitlisted'}, {status: 'cancelled'}), false);
  assert.equal(_test.isConfirmedCancellation({status: 'going'}, {status: 'going'}), false);
  assert.equal(_test.isConfirmedCancellation(null, {status: 'cancelled'}), false);
});

test('timestampMillis handles Firestore-like timestamps and Date values', () => {
  assert.equal(_test.timestampMillis({toMillis: () => 1234}), 1234);
  assert.equal(_test.timestampMillis(new Date(5678)), 5678);
  assert.equal(Number.isNaN(_test.timestampMillis(null)), true);
});

test('promotion rejects missing dependencies', async () => {
  await assert.rejects(
    _test.promoteNextWaitlisted({eventId: 'event-1'}),
    /required/,
  );
});
