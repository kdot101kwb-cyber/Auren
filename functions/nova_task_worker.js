'use strict';

const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const db = getFirestore();
const OPENROUTER_API_KEY = defineSecret('OPENROUTER_API_KEY');
const SAFE_TEXT_TYPES = new Set(['chat', 'plan', 'research', 'content_draft']);
const REGION = 'us-central1';

async function runTextTask(prompt, type, apiKey) {
  if (!apiKey) throw new Error('OPENROUTER_API_KEY is not configured in Firebase Secret Manager.');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 45000);
  try {
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method:'POST',
      headers:{
        'content-type':'application/json',
        authorization:'Bearer ' + apiKey,
        'HTTP-Referer':'https://auren.app',
        'X-Title':'NOVA AI',
      },
      body:JSON.stringify({
        model:'openrouter/free',
        temperature:type === 'plan' ? 0.25 : 0.45,
        messages:[
          {role:'system',content:'You are NOVA AI, the execution assistant inside AUREN. Be accurate, clearly distinguish evidence from assumptions, never claim external actions were completed unless an integrated tool confirms them, and respond in the language of the user.'},
          {role:'user',content:prompt},
        ],
      }),
      signal:controller.signal,
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(String(payload?.error?.message || 'OpenRouter HTTP ' + response.status).slice(0,400));
    const text = payload?.choices?.[0]?.message?.content;
    if (typeof text !== 'string' || !text.trim()) throw new Error('AI provider returned an empty result.');
    return {text:text.trim(), model:payload?.model || 'openrouter/free'};
  } finally {
    clearTimeout(timeout);
  }
}

exports.processNovaTaskQueue = onSchedule(
  {schedule:'every 1 minutes', region:REGION, timeoutSeconds:300, memory:'512MiB', maxInstances:1, secrets:[OPENROUTER_API_KEY]},
  async () => {
    const queue = await db.collection('nova_task_queue')
      .where('status', '==', 'queued')
      .limit(10)
      .get();
    for (const queueDoc of queue.docs) {
      const queueRef = queueDoc.ref;
      const initial = queueDoc.data() || {};
      const uid = String(initial.ownerUid || '');
      const taskId = String(initial.taskId || '');
      if (!uid || !taskId) {
        await queueRef.set({status:'failed', error:'Queue record is missing ownerUid or taskId.', updatedAt:FieldValue.serverTimestamp()}, {merge:true});
        continue;
      }
      const taskRef = db.collection('users').doc(uid).collection('nova_tasks').doc(taskId);
      const auditRef = db.collection('users').doc(uid).collection('nova_audit').doc();
      let claimed = false;
      let task;
      await db.runTransaction(async (tx) => {
        const qs = await tx.get(queueRef);
        const ts = await tx.get(taskRef);
        if (!qs.exists || !ts.exists || qs.data()?.status !== 'queued' || ts.data()?.status !== 'queued') return;
        task = ts.data();
        if (!SAFE_TEXT_TYPES.has(String(task.type || ''))) return;
        const attempts = Number(qs.data()?.attempts || 0);
        tx.update(queueRef, {status:'running', attempts:attempts + 1, claimedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
        tx.update(taskRef, {status:'running', startedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp(), retryCount:attempts});
        tx.create(auditRef, {action:'nova.task.started', actorUid:'nova_worker', taskId, taskType:task.type, createdAt:FieldValue.serverTimestamp()});
        claimed = true;
      });
      if (!claimed) continue;

      try {
        const result = await runTextTask(String(task.prompt || ''), String(task.type), OPENROUTER_API_KEY.value().trim());
        await db.runTransaction(async (tx) => {
          const qs = await tx.get(queueRef);
          const ts = await tx.get(taskRef);
          if (!qs.exists || !ts.exists || qs.data()?.status !== 'running' || ts.data()?.status !== 'running') return;
          tx.update(taskRef, {
            status:'succeeded',
            result:{text:result.text, provider:'openrouter', model:result.model},
            error:null,
            completedAt:FieldValue.serverTimestamp(),
            updatedAt:FieldValue.serverTimestamp(),
          });
          tx.update(queueRef, {status:'succeeded', completedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
          tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
            action:'nova.task.succeeded', actorUid:'nova_worker', taskId, taskType:task.type,
            provider:'openrouter', model:result.model, createdAt:FieldValue.serverTimestamp(),
          });
        });
      } catch (error) {
        const message = String(error?.message || error).slice(0,500);
        const attempts = Number(initial.attempts || 0) + 1;
        const terminal = attempts >= 3 || message.includes('not configured');
        await db.runTransaction(async (tx) => {
          const qs = await tx.get(queueRef);
          const ts = await tx.get(taskRef);
          if (!qs.exists || !ts.exists || qs.data()?.status !== 'running' || ts.data()?.status !== 'running') return;
          tx.update(taskRef, {
            status:terminal ? 'failed' : 'queued',
            error:message,
            retryCount:attempts,
            updatedAt:FieldValue.serverTimestamp(),
          });
          tx.update(queueRef, {
            status:terminal ? 'failed' : 'queued',
            error:message,
            attempts,
            updatedAt:FieldValue.serverTimestamp(),
          });
          tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
            action:terminal ? 'nova.task.failed' : 'nova.task.retry_scheduled',
            actorUid:'nova_worker', taskId, taskType:String(task.type || ''),
            error:message, attempt:attempts, createdAt:FieldValue.serverTimestamp(),
          });
        });
      }
    }
  }
);

exports.__testables = {SAFE_TEXT_TYPES};
