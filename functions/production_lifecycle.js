'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const db = admin.firestore();
const TERMINAL = new Set(['output','completed','failed','cancelled']);
const ACTIVE = new Set(['generation','provider_pending','processing','waiting_provider']);

function ownerTaskRef(uid, taskPath) {
  const raw = String(taskPath || '').replace(/^\/+|\/+$/g, '');
  const parts = raw.split('/');
  if (parts.length < 4 || parts[0] !== 'users' || parts[1] !== uid || parts[parts.length - 2] !== 'productionTasks') {
    throw new HttpsError('permission-denied', 'Invalid production task path.');
  }
  return db.doc(raw);
}

function historyRef(uid) {
  return db.collection('users').doc(uid).collection('productionHistory');
}

function outputRef(uid) {
  return db.collection('users').doc(uid).collection('outputLibrary');
}

async function writeHistory(tx, uid, taskRef, task, event, extra = {}) {
  const ref = historyRef(uid).doc();
  tx.set(ref, {
    taskId: taskRef.id,
    taskPath: taskRef.path,
    event,
    status: String(extra.status || task.status || ''),
    type: String(task.type || task.kind || task.mediaType || 'production'),
    title: String(task.title || task.name || extra.title || 'Untitled production').slice(0, 200),
    attempt: Number(task.generationAttempts || 0),
    retryCount: Number(task.retryCount || 0),
    error: String(extra.error || task.lastError || '').slice(0, 700),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    ...extra,
  });
}

exports.cancelAurenProduction = onCall(
  {region:'us-central1', timeoutSeconds:30, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const ref = ownerTaskRef(uid, request.data?.taskPath);
    const result = await db.runTransaction(async tx => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Production task not found.');
      const task = snap.data() || {};
      const status = String(task.status || '');
      if (status === 'cancelled') return {status:'cancelled'};
      if (!ACTIVE.has(status)) throw new HttpsError('failed-precondition', 'Only active production tasks can be cancelled.');
      tx.update(ref, {
        status:'cancelled',
        cancelRequested:true,
        providerLockUntilMs:0,
        cancelledAt:admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      });
      await writeHistory(tx, uid, ref, task, 'cancelled', {status:'cancelled'});
      return {status:'cancelled'};
    });
    return {taskPath:ref.path, ...result};
  }
);

exports.retryAurenProduction = onCall(
  {region:'us-central1', timeoutSeconds:30, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const ref = ownerTaskRef(uid, request.data?.taskPath);
    const result = await db.runTransaction(async tx => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Production task not found.');
      const task = snap.data() || {};
      const status = String(task.status || '');
      if (!['failed','cancelled','waiting_provider'].includes(status)) {
        throw new HttpsError('failed-precondition', 'Only failed, cancelled, or waiting tasks can be retried.');
      }
      const retries = Number(task.retryCount || 0) + 1;
      if (retries > 5) throw new HttpsError('resource-exhausted', 'Retry limit reached.');
      tx.update(ref, {
        status:'generation',
        retryCount:retries,
        generationAttempts:0,
        externalJobId:'',
        providerState:'',
        providerLockUntilMs:0,
        cancelRequested:false,
        lastError:'',
        retriedAt:admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:admin.firestore.FieldValue.serverTimestamp(),
      });
      await writeHistory(tx, uid, ref, task, 'retry', {status:'generation', retryCount:retries});
      return {status:'generation', retryCount:retries};
    });
    return {taskPath:ref.path, ...result};
  }
);

exports.recordAurenProductionOutput = onCall(
  {region:'us-central1', timeoutSeconds:30, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const ref = ownerTaskRef(uid, request.data?.taskPath);
    const output = request.data?.output;
    if (!output || typeof output !== 'object') throw new HttpsError('invalid-argument', 'Output metadata is required.');
    const url = String(output.url || '').trim();
    const storagePath = String(output.storagePath || '').trim();
    const externalId = String(output.externalId || '').trim();
    if (!url && !storagePath && !externalId) throw new HttpsError('invalid-argument', 'A real output reference is required.');
    const result = await db.runTransaction(async tx => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Production task not found.');
      const task = snap.data() || {};
      const item = outputRef(uid).doc();
      tx.set(item, {
        taskId:ref.id,
        taskPath:ref.path,
        type:String(task.type || task.kind || task.mediaType || 'production'),
        title:String(task.title || task.name || 'Untitled production').slice(0,200),
        output:{url: url || null, storagePath: storagePath || null, externalId: externalId || null},
        createdAt:admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(ref, {status:'output', output:{url:url || null, storagePath:storagePath || null, externalId:externalId || null}, updatedAt:admin.firestore.FieldValue.serverTimestamp()});
      await writeHistory(tx, uid, ref, task, 'output', {status:'output', outputLibraryId:item.id});
      return {outputLibraryId:item.id};
    });
    return result;
  }
);
