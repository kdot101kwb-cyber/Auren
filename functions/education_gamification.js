const admin = require('firebase-admin');
const {onCall, HttpsError} = require('firebase-functions/v2/https');

const db = admin.firestore();

const XP = Object.freeze({
  lesson: 10,
  course: 100,
  quiz: 20,
  language: 15,
  voiceTutor: 10,
});

const DAILY_CAPS = Object.freeze({
  voiceTutor: 5,
  language: 20,
});

const WEEKLY_CHALLENGE = Object.freeze({
  targetActivities: 5,
  bonusXp: 50,
});

const BADGES = Object.freeze([
  {id: 'learner-25', threshold: 25, title: '25 Activities'},
  {id: 'learner-100', threshold: 100, title: '100 Activities'},
]);

function weekKey(date = new Date()) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const week = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
  return `${d.getUTCFullYear()}-${String(week).padStart(2, '0')}`;
}

function dayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

function cleanString(value, max = 160) {
  return typeof value === 'string' ? value.trim().slice(0, max) : '';
}

function validateType(type) {
  if (!Object.prototype.hasOwnProperty.call(XP, type)) {
    throw new HttpsError('invalid-argument', 'Unsupported education activity type.');
  }
}

async function getUserDisplay(uid) {
  const snap = await db.collection('users').doc(uid).get();
  const d = snap.data() || {};
  return {
    displayName: cleanString(d.displayName || d.name || 'AUREN Learner', 80) || 'AUREN Learner',
    photoUrl: cleanString(d.photoURL || d.photoUrl, 1000),
  };
}

exports.recordAurenEducationActivity = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');

    const data = request.data || {};
    const type = cleanString(data.type, 40);
    const eventId = cleanString(data.eventId, 120);
    const sourceId = cleanString(data.sourceId, 160);
    const subject = cleanString(data.subject, 120);
    if (!eventId || !sourceId) {
      throw new HttpsError('invalid-argument', 'eventId and sourceId are required.');
    }
    validateType(type);

    const now = new Date();
    const day = dayKey(now);
    const week = weekKey(now);
    const eventRef = db.collection('users').doc(uid).collection('educationXpEvents').doc(eventId);
    const profileRef = db.collection('users').doc(uid).collection('educationGamification').doc('profile');
    const weekRef = db.collection('educationLeaderboards').doc(week).collection('users').doc(uid);
    const dayRef = db.collection('users').doc(uid).collection('educationDailyActivity').doc(day);

    const result = await db.runTransaction(async (tx) => {
      const eventSnap = await tx.get(eventRef);
      const profileSnap = await tx.get(profileRef);
      const weekSnap = await tx.get(weekRef);
      const daySnap = await tx.get(dayRef);

      if (eventSnap.exists) {
        const existing = eventSnap.data() || {};
        return {duplicate: true, xpAwarded: Number(existing.xpAwarded || 0), totalXp: Number(profileSnap.data()?.totalXp || 0)};
      }

      const currentDay = daySnap.data() || {};
      const currentProfile = profileSnap.data() || {};
      const currentWeek = weekSnap.data() || {};
      const currentCount = Number(currentDay[type] || 0);
      const previousTotalActivities = Number(currentProfile.totalActivities || 0);
      const previousWeeklyXp = currentProfile.currentWeek === week
        ? Number(currentProfile.weeklyXp || 0)
        : 0;

      if (DAILY_CAPS[type] && currentCount >= DAILY_CAPS[type]) {
        tx.set(eventRef, {
          type, sourceId, subject, xpAwarded: 0, capped: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {duplicate: false, capped: true, xpAwarded: 0, totalXp: Number(currentProfile.totalXp || 0)};
      }

      const baseAwarded = XP[type];
      const totalActivities = previousTotalActivities + 1;
      const challengeAlreadyCompleted = currentProfile.currentWeek === week && currentProfile.weeklyChallengeCompleted === true;
      const challengeCompletedNow = !challengeAlreadyCompleted
        && totalActivities - Number(currentProfile.weekStartActivities || 0) >= WEEKLY_CHALLENGE.targetActivities;
      const challengeBonus = challengeCompletedNow ? WEEKLY_CHALLENGE.bonusXp : 0;
      const awarded = baseAwarded + challengeBonus;
      const totalXp = Number(currentProfile.totalXp || 0) + awarded;
      const weeklyXp = previousWeeklyXp + awarded;
      const earnedBadges = Array.isArray(currentProfile.badges) ? currentProfile.badges.filter((x) => typeof x === 'string') : [];
      const newlyEarned = BADGES
        .filter((badge) => totalActivities >= badge.threshold && !earnedBadges.includes(badge.id))
        .map((badge) => badge.id);
      const badges = [...new Set([...earnedBadges, ...newlyEarned])];

      tx.set(eventRef, {
        type, sourceId, subject, xpAwarded: awarded, baseXp: baseAwarded,
        challengeBonus, week, day, createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.set(dayRef, {
        [type]: currentCount + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      tx.set(profileRef, {
        totalXp,
        totalActivities,
        weeklyXp,
        currentWeek: week,
        weekStartActivities: currentProfile.currentWeek === week
          ? Number(currentProfile.weekStartActivities || 0)
          : previousTotalActivities,
        weeklyChallengeCompleted: challengeAlreadyCompleted || challengeCompletedNow,
        badges,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      tx.set(weekRef, {
        uid,
        weeklyXp,
        totalActivities: Number(currentWeek.totalActivities || 0) + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      return {
        duplicate: false,
        capped: false,
        xpAwarded: awarded,
        baseXp: baseAwarded,
        challengeBonus,
        challengeCompleted: challengeCompletedNow,
        newlyEarnedBadges: newlyEarned,
        totalXp,
        weeklyXp,
        totalActivities,
        badges,
      };
    });

    return {...result, week};
  },
);

exports.getAurenEducationGamification = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const week = weekKey();
    const [profileSnap, weekSnap] = await Promise.all([
      db.collection('users').doc(uid).collection('educationGamification').doc('profile').get(),
      db.collection('educationLeaderboards').doc(week).collection('users').doc(uid).get(),
    ]);
    return {
      week,
      profile: profileSnap.exists ? profileSnap.data() : {
        totalXp: 0,
        totalActivities: 0,
        weeklyXp: 0,
        weeklyChallengeCompleted: false,
        badges: [],
      },
      weekly: weekSnap.exists ? weekSnap.data() : {weeklyXp: 0, totalActivities: 0},
    };
  },
);

exports.getAurenEducationLeaderboard = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const requestedWeek = cleanString(request.data?.week, 20);
    const week = /^\d{4}-\d{2}$/.test(requestedWeek) ? requestedWeek : weekKey();
    const snap = await db.collection('educationLeaderboards').doc(week).collection('users')
      .orderBy('weeklyXp', 'desc').limit(100).get();

    const sortedDocs = [...snap.docs].sort((a, b) => {
      const ax = Number(a.data()?.weeklyXp || 0);
      const bx = Number(b.data()?.weeklyXp || 0);
      if (bx !== ax) return bx - ax;
      return a.id.localeCompare(b.id);
    });

    const rows = await Promise.all(sortedDocs.map(async (doc, index) => {
      const d = doc.data() || {};
      const profile = await getUserDisplay(doc.id);
      return {
        rank: index + 1,
        uid: doc.id,
        displayName: profile.displayName,
        photoUrl: profile.photoUrl,
        weeklyXp: Number(d.weeklyXp || 0),
        totalActivities: Number(d.totalActivities || 0),
        isMe: doc.id === uid,
      };
    }));

    return {week, entries: rows};
  },
);
