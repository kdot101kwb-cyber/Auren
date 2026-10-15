'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { _test } = require('./events_waitlist');

function makeFakeDb({event, attendees = []}) {
  const attendeeMap = new Map(attendees.map((item) => [item.userId, {...item}]));
  const markerMap = new Map();
  const eventData = {...event};
  const eventRef = {
    kind: 'event',
    id: 'event-1',
    collection(name) {
      return {
        doc(id) {
          return {kind: name === 'attendees' ? 'attendee' : 'marker', id, parent: this};
        },
        where(field, op, value) {
          return {
            where: this.where,
            orderBy(orderField, order) {
              return {
                limit(n) {
                  return {kind: 'query', field, op, value, orderField, order, n};
                },
              };
            },
          };
        },
      };
    },
  };
  const db = {
    collection(name) {
      assert.equal(name, 'events');
      return {doc(id) { assert.equal(id, 'event-1'); return eventRef; }};
    },
    async runTransaction(callback) {
      const tx = {
        async get(ref) {
          if (ref.kind === 'event') {
            return {exists: true, data: () => eventData};
          }
          if (ref.kind === 'marker') {
            return {exists: markerMap.has(ref.id), data: () => markerMap.get(ref.id)};
          }
          if (ref.kind === 'query') {
            const docs = [...attendeeMap.entries()]
              .filter(([, item]) => item.status === ref.value)
              .sort((a, b) => {
                const av = a[1].updatedAt?.toMillis?.() ?? 0;
                const bv = b[1].updatedAt?.toMillis?.() ?? 0;
                return ref.order === 'asc' ? av - bv : bv - av;
              })
              .slice(0, ref.n)
              .map(([id, item]) => ({
                id,
                ref: {kind: 'attendee', id},
                data: () => item,
              }));
            return {empty: docs.length === 0, docs};
          }
          throw new Error('Unexpected fake reference');
        },
        update(ref, patch) {
          if (ref.kind === 'event') Object.assign(eventData, patch);
          else if (ref.kind === 'attendee') Object.assign(attendeeMap.get(ref.id), patch);
          else throw new Error('Unexpected update target');
        },
        create(ref, value) {
          assert.equal(ref.kind, 'marker');
          if (markerMap.has(ref.id)) throw new Error('marker already exists');
          markerMap.set(ref.id, value);
        },
      };
      return callback(tx);
    },
  };
  return {db, eventData, attendeeMap, markerMap};
}

const stamp = (ms) => ({toMillis: () => ms});

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

test('promotes the oldest waitlisted attendee and increments the count', async () => {
  const {db, eventData, attendeeMap, markerMap} = makeFakeDb({
    event: {startsAt: stamp(5000), confirmedCount: 1, capacity: 2},
    attendees: [
      {userId: 'later', status: 'waitlisted', updatedAt: stamp(200)},
      {userId: 'earlier', status: 'waitlisted', updatedAt: stamp(100)},
    ],
  });
  const result = await _test.promoteNextWaitlisted({
    db, eventId: 'event-1', triggerId: 'trigger-1', now: 1000,
    serverTimestamp: () => stamp(300),
  });
  assert.deepEqual(result, {status: 'promoted', userId: 'earlier'});
  assert.equal(attendeeMap.get('earlier').status, 'going');
  assert.equal(attendeeMap.get('later').status, 'waitlisted');
  assert.equal(eventData.confirmedCount, 2);
  assert.equal(markerMap.has('trigger-1'), true);
});

test('the same trigger retry cannot promote a second attendee', async () => {
  const {db, eventData, attendeeMap} = makeFakeDb({
    event: {startsAt: stamp(5000), confirmedCount: 0, capacity: 3},
    attendees: [
      {userId: 'first', status: 'waitlisted', updatedAt: stamp(100)},
      {userId: 'second', status: 'waitlisted', updatedAt: stamp(200)},
    ],
  });
  const args = {db, eventId: 'event-1', triggerId: 'trigger-1', now: 1000,
    serverTimestamp: () => stamp(300)};
  assert.equal((await _test.promoteNextWaitlisted(args)).userId, 'first');
  assert.deepEqual(await _test.promoteNextWaitlisted(args), {status: 'already_processed'});
  assert.equal(eventData.confirmedCount, 1);
  assert.equal(attendeeMap.get('second').status, 'waitlisted');
});

test('does not promote when the event started or has no free capacity', async () => {
  const attendees = [{userId: 'next', status: 'waitlisted', updatedAt: stamp(100)}];
  const started = makeFakeDb({
    event: {startsAt: stamp(900), confirmedCount: 0, capacity: 1}, attendees,
  });
  assert.deepEqual(await _test.promoteNextWaitlisted({
    db: started.db, eventId: 'event-1', triggerId: 't1', now: 1000,
    serverTimestamp: () => stamp(300),
  }), {status: 'event_started'});
  const full = makeFakeDb({
    event: {startsAt: stamp(5000), confirmedCount: 1, capacity: 1}, attendees,
  });
  assert.deepEqual(await _test.promoteNextWaitlisted({
    db: full.db, eventId: 'event-1', triggerId: 't2', now: 1000,
    serverTimestamp: () => stamp(300),
  }), {status: 'no_capacity'});
});
