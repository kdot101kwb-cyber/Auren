const admin = require('firebase-admin');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {
  applyEducationActivitiesInTransaction,
  weekKey,
  cleanString,
} = require('./education_gamification_core');

const db = admin.firestore();

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
    const activity = {
      type: cleanString(data.type, 40),
      eventId: cleanString(data.eventId, 120),
      sourceId: cleanString(data.sourceId, 160),
      subject: cleanString(data.subject, 120),
    };
    try {
      return await db.runTransaction((tx) => applyEducationActivitiesInTransaction(tx, uid, [activity]));
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw new HttpsError('invalid-argument', error.message || 'Invalid education activity.');
    }
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
    const storedProfile = profileSnap.exists ? (profileSnap.data() || {}) : {};
    const isCurrentWeek = storedProfile.currentWeek === week;
    const normalizedProfile = {
      ...storedProfile,
      totalXp: Number(storedProfile.totalXp || 0),
      totalActivities: Number(storedProfile.totalActivities || 0),
      weeklyXp: isCurrentWeek ? Number(storedProfile.weeklyXp || 0) : 0,
      weeklyChallengeCompleted: isCurrentWeek && storedProfile.weeklyChallengeCompleted === true,
      badges: Array.isArray(storedProfile.badges) ? storedProfile.badges.filter((x) => typeof x === 'string') : [],
    };
    const weekly = weekSnap.exists
      ? {...weekSnap.data(), weeklyXp: Number(weekSnap.data()?.weeklyXp || 0), totalActivities: Number(weekSnap.data()?.totalActivities || 0)}
      : {weeklyXp: 0, totalActivities: 0};
    return {week, profile: normalizedProfile, weekly};
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
      return bx !== ax ? bx - ax : a.id.localeCompare(b.id);
    });
    const entries = await Promise.all(sortedDocs.map(async (doc, index) => {
      const d = doc.data() || {};
      const profile = await getUserDisplay(doc.id);
      return {
        rank: index + 1, uid: doc.id, displayName: profile.displayName, photoUrl: profile.photoUrl,
        weeklyXp: Number(d.weeklyXp || 0), totalActivities: Number(d.totalActivities || 0), isMe: doc.id === uid,
      };
    }));
    return {week, entries};
  },
);
