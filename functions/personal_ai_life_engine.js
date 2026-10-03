'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getApps, initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

if (getApps().length === 0) initializeApp();
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

function nowIso() {
  return new Date().toISOString();
}

function goalRef(uid, goalId) {
  return db.collection('users').doc(uid).collection('goals').doc(goalId);
}

exports.createAurenGoal = onCall(async (request) => {
  const uid = requireAuth(request);
  const title = cleanText(request.data?.title, 200);
  const description = request.data?.description == null ? null : cleanText(request.data.description, 2000);
  const timestamp = nowIso();
  const ref = db.collection('users').doc(uid).collection('goals').doc();
  await ref.set({
    title,
    description,
    status: 'active',
    progress: 0,
    createdAt: timestamp,
    updatedAt: timestamp,
  });
  return {goalId: ref.id, status: 'active', progress: 0};
});

exports.updateAurenGoalProgress = onCall(async (request) => {
  const uid = requireAuth(request);
  const goalId = cleanText(request.data?.goalId, 120);
  const progress = assertProgress(request.data?.progress);
  const ref = goalRef(uid, goalId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Goal not found.');
  const current = snap.data() || {};
  const status = progress >= 100 ? 'completed' : (current.status === 'paused' ? 'paused' : 'active');
  await ref.update({progress, status, updatedAt: nowIso()});
  return {goalId, status, progress};
});

exports.createAurenDailyPlan = onCall(async (request) => {
  const uid = requireAuth(request);
  const rawDate = cleanText(request.data?.date, 10);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(rawDate)) {
    throw new HttpsError('invalid-argument', 'Date must use YYYY-MM-DD.');
  }
  const goalId = request.data?.goalId ? cleanText(request.data.goalId, 120) : '';
  const goalTitle = cleanText(request.data?.goalTitle || 'خطة اليوم', 200);
  const focus = cleanText(request.data?.focus || 'اختر خطوة واحدة قابلة للتنفيذ اليوم.', 500);
  const rawSteps = Array.isArray(request.data?.steps) ? request.data.steps : [];
  if (rawSteps.length > 10) throw new HttpsError('invalid-argument', 'A daily plan can contain at most 10 steps.');
  const steps = rawSteps.map((step) => cleanText(step, 300));
  const ref = db.collection('users').doc(uid).collection('daily_plans').doc('current');
  await ref.set({
    goalId,
    goalTitle,
    focus,
    steps,
    generatedAt: FieldValue.serverTimestamp(),
    planDate: rawDate,
  }, {merge: true});
  const tasks = ref.collection('tasks');
  const old = await tasks.get();
  const batch = db.batch();
  for (const doc of old.docs) batch.delete(doc.ref);
  steps.forEach((title, index) => {
    batch.set(tasks.doc(), {
      title,
      order: index,
      completed: false,
      completedAt: null,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  await batch.commit();
  return {date: rawDate, goalId, taskCount: steps.length, status: steps.length ? 'active' : 'empty'};
});

exports.completeAurenDailyPlanTask = onCall(async (request) => {
  const uid = requireAuth(request);
  const taskId = cleanText(request.data?.taskId, 120);
  const completed = request.data?.completed !== false;
  const ref = db.collection('users').doc(uid).collection('daily_plans').doc('current').collection('tasks').doc(taskId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Daily plan task not found.');
  await ref.update({
    completed,
    completedAt: completed ? FieldValue.serverTimestamp() : null,
  });
  const all = await ref.parent.get();
  const done = all.docs.filter((doc) => doc.data()?.completed === true).length;
  const total = all.size;
  await ref.parent.parent.update({
    status: total === 0 ? 'empty' : (done === total ? 'completed' : 'active'),
    completedTasks: done,
    taskCount: total,
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {taskId, completed, completedTasks: done, taskCount: total, status: total === 0 ? 'empty' : (done === total ? 'completed' : 'active')};
});

exports.saveAurenMemory = onCall(async (request) => {
  const uid = requireAuth(request);
  const key = cleanText(request.data?.key, 120);
  const value = cleanText(request.data?.value, 4000);
  const id = request.data?.memoryId ? cleanText(request.data.memoryId, 120) : null;
  const ref = id
    ? db.collection('users').doc(uid).collection('memory').doc(id)
    : db.collection('users').doc(uid).collection('memory').doc();
  const timestamp = nowIso();
  await ref.set({
    key,
    value,
    enabled: request.data?.enabled !== false,
    updatedAt: timestamp,
  }, {merge: true});
  return {memoryId: ref.id};
});

exports.setAurenMemoryEnabled = onCall(async (request) => {
  const uid = requireAuth(request);
  const memoryId = cleanText(request.data?.memoryId, 120);
  if (typeof request.data?.enabled !== 'boolean') throw new HttpsError('invalid-argument', 'enabled must be boolean.');
  const ref = db.collection('users').doc(uid).collection('memory').doc(memoryId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Memory not found.');
  await ref.update({enabled: request.data.enabled, updatedAt: nowIso()});
  return {memoryId, enabled: request.data.enabled};
});

exports.deleteAurenMemory = onCall(async (request) => {
  const uid = requireAuth(request);
  const memoryId = cleanText(request.data?.memoryId, 120);
  const ref = db.collection('users').doc(uid).collection('memory').doc(memoryId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Memory not found.');
  await ref.delete();
  return {memoryId, deleted: true};
});
