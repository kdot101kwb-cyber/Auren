'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');

const db = getFirestore();
const auth = getAuth();
const MAX_LOOKUPS = 50;
const RATE_LIMIT = 20;
const WINDOW_MS = 60 * 60 * 1000;

function normalizeE164(value) {
  const phone = String(value || '').trim().replace(/[()\s.-]/g, '');
  return /^\+[1-9]\d{7,14}$/.test(phone) ? phone : null;
}

async function consumeRateLimit(uid) {
  const ref = db.collection('phone_discovery_limits').doc(uid);
  const now = Date.now();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() : {};
    const start = Number(data.windowStartedAtMs || 0);
    const count = start > 0 && now - start < WINDOW_MS ? Number(data.count || 0) : 0;
    if (count >= RATE_LIMIT) {
      throw new HttpsError('resource-exhausted', 'Too many phone lookups. Try again later.');
    }
    tx.set(ref, {
      windowStartedAtMs: count === 0 ? now : start,
      count: count + 1,
      updatedAt: FieldValue.serverTimestamp(),
      expiresAt: Timestamp.fromMillis(now + 24 * WINDOW_MS),
    }, {merge: true});
  });
}

exports.lookupAurenPhoneContacts = onCall({
  region: 'us-central1',
  enforceAppCheck: true,
}, async (request) => {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in to use phone discovery.');
  const caller = await auth.getUser(request.auth.uid);
  if (!caller.phoneNumber) {
    throw new HttpsError('failed-precondition', 'Verify your phone number before searching contacts.');
  }
  const raw = request.data?.phoneNumbers;
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > MAX_LOOKUPS) {
    throw new HttpsError('invalid-argument', 'Provide between 1 and 50 phone numbers.');
  }
  const numbers = [...new Set(raw.map(normalizeE164).filter(Boolean))];
  if (numbers.length === 0) throw new HttpsError('invalid-argument', 'No valid international phone numbers were provided.');
  await consumeRateLimit(request.auth.uid);

  const users = [];
  for (let i = 0; i < numbers.length; i += 5) {
    const batch = numbers.slice(i, i + 5);
    const results = await Promise.all(batch.map(async (phoneNumber) => {
      try {
        const user = await auth.getUserByPhoneNumber(phoneNumber);
        if (user.uid === request.auth.uid) return null;
        const profile = await db.collection('users').doc(user.uid).get();
        const profileData = profile.exists ? profile.data() : {};
        return {
          uid: user.uid,
          displayName: String(profileData?.displayName || user.displayName || 'AUREN User').slice(0, 80),
          photoUrl: typeof profileData?.photoUrl === 'string' ? profileData.photoUrl : (user.photoURL || null),
        };
      } catch (error) {
        if (error?.code === 'auth/user-not-found') return null;
        throw error;
      }
    }));
    users.push(...results.filter(Boolean));
  }
  return {users};
});
