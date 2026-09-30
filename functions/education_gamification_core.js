const admin = require('firebase-admin');

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
  {id: 'learner-25', threshold: 25},
  {id: 'learner-100', threshold: 100},
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

function validateActivity(activity) {
  if (!activity || !Object.prototype.hasOwnProperty.call(XP, activity.type)) {
    throw new Error('Unsupported education activity type.');
  }
  if (!cleanString(activity.eventId, 120) || !cleanString(activity.sourceId, 160)) {
    throw new Error('eventId and sourceId are required.');
  }
}

async function applyEducationActivitiesInTransaction(tx, uid, activities, now = new Date()) {
  activities.forEach(validateActivity);
  const db = admin.firestore();
  const day = dayKey(now);
  const week = weekKey(now);
  const base = db.collection('users').doc(uid);
  const profileRef = base.collection('educationGamification').doc('profile');
  const weekRef = db.collection('educationLeaderboards').doc(week).collection('users').doc(uid);
  const dayRef = base.collection('educationDailyActivity').doc(day);

  const eventRefs = activities.map((a) => base.collection('educationXpEvents').doc(cleanString(a.eventId, 120)));
  const [profileSnap, weekSnap, daySnap, ...eventSnaps] = await Promise.all([
    tx.get(profileRef),
    tx.get(weekRef),
    tx.get(dayRef),
    ...eventRefs.map((ref) => tx.get(ref)),
  ]);

  const profile = profileSnap.data() || {};
  const weekData = weekSnap.data() || {};
  const dayData = daySnap.data() || {};
  const currentWeek = profile.currentWeek === week;
  let totalXp = Number(profile.totalXp || 0);
  let totalActivities = Number(profile.totalActivities || 0);
  let weeklyXp = currentWeek ? Number(profile.weeklyXp || 0) : 0;
  const weekStartActivities = currentWeek ? Number(profile.weekStartActivities || 0) : totalActivities;
  let challengeCompleted = currentWeek && profile.weeklyChallengeCompleted === true;
  const badges = new Set(Array.isArray(profile.badges) ? profile.badges.filter((x) => typeof x === 'string') : []);
  const counts = {...dayData};
  const results = [];

  for (let i = 0; i < activities.length; i++) {
    const activity = activities[i];
    const eventSnap = eventSnaps[i];
    if (eventSnap.exists) {
      results.push({duplicate: true, xpAwarded: Number(eventSnap.data()?.xpAwarded || 0)});
      continue;
    }

    const type = activity.type;
    const currentCount = Number(counts[type] || 0);
    if (DAILY_CAPS[type] && currentCount >= DAILY_CAPS[type]) {
      tx.set(eventRefs[i], {
        type, sourceId: cleanString(activity.sourceId, 160),
        subject: cleanString(activity.subject, 120),
        xpAwarded: 0, capped: true, week, day,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      results.push({duplicate: false, capped: true, xpAwarded: 0});
      continue;
    }

    const baseXp = XP[type];
    totalActivities += 1;
    const challengeBonus = !challengeCompleted && totalActivities - weekStartActivities >= WEEKLY_CHALLENGE.targetActivities
      ? WEEKLY_CHALLENGE.bonusXp : 0;
    if (challengeBonus) challengeCompleted = true;
    const awarded = baseXp + challengeBonus;
    totalXp += awarded;
    weeklyXp += awarded;
    counts[type] = currentCount + 1;

    for (const badge of BADGES) {
      if (totalActivities >= badge.threshold) badges.add(badge.id);
    }

    tx.set(eventRefs[i], {
      type, sourceId: cleanString(activity.sourceId, 160),
      subject: cleanString(activity.subject, 120),
      xpAwarded: awarded, baseXp, challengeBonus, week, day,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    results.push({
      duplicate: false, capped: false, xpAwarded: awarded, baseXp, challengeBonus,
      challengeCompleted: challengeBonus > 0,
    });
  }

  const processed = results.some((r) => !r.duplicate && !r.capped);
  if (processed) {
    tx.set(dayRef, {...Object.fromEntries(Object.entries(counts).filter(([k]) => k !== 'updatedAt')), updatedAt: admin.firestore.FieldValue.serverTimestamp()}, {merge: true});
    tx.set(profileRef, {
      totalXp, totalActivities, weeklyXp, currentWeek: week,
      weekStartActivities, weeklyChallengeCompleted: challengeCompleted,
      badges: [...badges],
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
    tx.set(weekRef, {
      uid, weeklyXp,
      totalActivities: Number(weekData.totalActivities || 0) + results.filter((r) => !r.duplicate && !r.capped).length,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  }

  return {week, results, totalXp, weeklyXp, totalActivities, badges: [...badges]};
}

module.exports = {
  XP, DAILY_CAPS, WEEKLY_CHALLENGE, BADGES, weekKey, dayKey,
  cleanString, applyEducationActivitiesInTransaction,
};
