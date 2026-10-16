'use strict';

const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

function isConfirmedCancellation(before, after) {
  return before?.status === 'going' && after?.status === 'cancelled';
}

function timestampMillis(value) {
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return Number.NaN;
}

/**
 * Promote one FIFO waitlisted attendee after a confirmed RSVP is cancelled.
 * The transaction marker makes retries of the same Firestore event idempotent.
 */
async function promoteNextWaitlisted({db, eventId, triggerId, now = Date.now(), serverTimestamp}) {
  if (!db || !eventId || !triggerId || typeof serverTimestamp !== 'function') {
    throw new TypeError('db, eventId, triggerId and serverTimestamp are required.');
  }

  const eventRef = db.collection('events').doc(eventId);
  const markerRef = eventRef.collection('promotionRuns').doc(triggerId);
  return db.runTransaction(async (transaction) => {
    const eventSnapshot = await transaction.get(eventRef);
    if (!eventSnapshot.exists) return {status: 'event_missing'};
    const event = eventSnapshot.data() || {};
    const startsAtMillis = timestampMillis(event.startsAt);
    if (!Number.isFinite(startsAtMillis) || startsAtMillis <= now) {
      return {status: 'event_started'};
    }
    const count = Number.isInteger(event.confirmedCount) ? event.confirmedCount : -1;
    if (count < 0) return {status: 'invalid_count'};
    if (event.capacity != null &&
        (!Number.isInteger(event.capacity) || count >= event.capacity)) {
      return {status: 'no_capacity'};
    }

    const markerSnapshot = await transaction.get(markerRef);
    if (markerSnapshot.exists) return {status: 'already_processed'};

    const waitingQuery = eventRef.collection('attendees')
      .where('status', '==', 'waitlisted')
      .orderBy('updatedAt', 'asc')
      .limit(1);
    const waitingSnapshot = await transaction.get(waitingQuery);
    if (waitingSnapshot.empty) return {status: 'no_waitlisted_attendee'};

    const candidate = waitingSnapshot.docs[0];
    const attendee = candidate.data() || {};
    if (attendee.status !== 'waitlisted' || attendee.userId !== candidate.id) {
      return {status: 'candidate_invalid'};
    }

    const stamp = serverTimestamp();
    transaction.update(candidate.ref, {status: 'going', updatedAt: stamp});
    transaction.update(eventRef, {
      confirmedCount: count + 1,
      updatedAt: stamp,
    });
    transaction.create(markerRef, {
      triggerId,
      promotedUserId: candidate.id,
      createdAt: stamp,
    });
    return {status: 'promoted', userId: candidate.id};
  });
}

exports.promoteAurenEventWaitlist = onDocumentUpdated(
  {
    document: 'events/{eventId}/attendees/{userId}',
    region: 'us-central1',
    retry: true,
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!isConfirmedCancellation(before, after)) return;
    await promoteNextWaitlisted({
      db: getFirestore(),
      eventId: String(event.params.eventId || ''),
      triggerId: String(event.id || ''),
      serverTimestamp: () => FieldValue.serverTimestamp(),
    });
  },
);

Object.defineProperty(exports, '_test', {
  value: {isConfirmedCancellation, timestampMillis, promoteNextWaitlisted},
  enumerable: false,
});
