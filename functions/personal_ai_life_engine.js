'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

function requireAuth(request) {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
  return request.auth.uid;
}

function cleanText(value, max) {
  const text = String(value ?? '').trim();
  if (!text || text.length > max) throw new HttpsError('invalid-argument', 'Invalid text value.');
  return text;
}

function assertProgress(value) {
  if (!Number.isInteger(value) || value < 0 || value > 100) {
    throw new HttpsError('invalid-argument', 'Progress must be an integer from 0 to 100.');
  }
  return value;
}

exports.createAurenGoal = onCall(async (request) => {
  const uid = requireAuth(request);
  const title = cleanText(request.data?.title, 300);
  const ref = db.collection('users').doc(uid).collection('goals').doc();
  await ref.set({
    title,
    status: 'active',
    progress: 0,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {goalId: ref.id, status: 'active', progress: 0};
});

exports.updateAurenGoalProgress = onCall(async (request) => {
  const uid = requireAuth(request);
  const goalId = cleanText(request.data?.goalId, 120);
  const progress = assertProgress(request.data?.progress);
  const ref = db.collection('users').doc(uid).collection('goals').doc(goalId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Goal not found.');
  const status = progress >= 100 ? 'completed' : 'active';
  await ref.update({progress, status, updatedAt: FieldValue.serverTimestamp()});
  return {goalId, status, progress};
});

exports.createAurenDailyPlan = onCall(async (request) => {
  const uid = requireAuth(request);
  const date = cleanText(request.data?.date, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    throw new HttpsError('invalid-argument', 'Date must use YYYY-MM-DD.');
  }
  const rawTasks = Array.isArray(request.data?.tasks) ? request.data.tasks : [];
  if (rawTasks.length > 20) throw new HttpsError('invalid-argument', 'A plan can contain at most 20 tasks.');
  const tasks = rawTasks.map((task, index) => {
    const title = cleanText(task?.title, 200);
    const minutes = Number(task?.minutes ?? 30);
    if (!Number.isInteger(minutes) || minutes < 5 || minutes > 180) {
      throw new HttpsError('invalid-argument', 'Task minutes must be an integer from 5 to 180.');
    }
    return {title, minutes, order: index, completed: false};
  });
  const ref = db.collection('users').doc(uid).collection('dailyPlans').doc(date);
  await ref.set({
    date,
    tasks,
    status: tasks.length ? 'active' : 'empty',
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {date, status: tasks.length ? 'active' : 'empty', taskCount: tasks.length};
});

exports.saveAurenMemory = onCall(async (request) => {
  const uid = requireAuth(request);
  const key = cleanText(request.data?.key, 120);
  const value = cleanText(request.data?.value, 4000);
  const ref = db.collection('users').doc(uid).collection('memories').doc();
  await ref.set({
    key,
    value,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {memoryId: ref.id};
});
