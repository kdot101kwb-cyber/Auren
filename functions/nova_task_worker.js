'use strict';

const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const db = getFirestore();
const OPENROUTER_API_KEY = defineSecret('OPENROUTER_API_KEY');
const HIGGSFIELD_API_KEY_ID = defineSecret('HIGGSFIELD_API_KEY_ID');
const HIGGSFIELD_API_KEY_SECRET = defineSecret('HIGGSFIELD_API_KEY_SECRET');
const NOVA_GITHUB_TOKEN = defineSecret('NOVA_GITHUB_TOKEN');
const CIRCLECI_TOKEN = defineSecret('CIRCLECI_TOKEN');
const {submitVideoGeneration, getVideoGenerationStatus} = require('./nova_higgsfield_adapter');
const {isTaskExecutable} = require('./nova_task_worker_policy');
const {checkGithubActionsRun} = require('./nova_github_ci_adapter');
const {diagnoseGithubActionsRun} = require('./nova_github_ci_diagnostics');
const {checkCircleCiJob} = require('./nova_circleci_adapter');
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
  {schedule:'every 1 minutes', region:REGION, timeoutSeconds:300, memory:'512MiB', maxInstances:1, secrets:[OPENROUTER_API_KEY, HIGGSFIELD_API_KEY_ID, HIGGSFIELD_API_KEY_SECRET, NOVA_GITHUB_TOKEN, CIRCLECI_TOKEN]},
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
        if (!isTaskExecutable(task, uid)) {
          const reason = 'No execution adapter is configured or approval is missing for task type: ' + String(task.type || 'unknown');
          tx.update(taskRef, {status:'failed', error:reason, updatedAt:FieldValue.serverTimestamp()});
          tx.update(queueRef, {status:'failed', error:reason, updatedAt:FieldValue.serverTimestamp()});
          tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
            action:'nova.task.blocked_no_adapter', actorUid:'nova_worker', taskId,
            taskType:String(task.type || 'unknown'), error:reason, createdAt:FieldValue.serverTimestamp(),
          });
          return;
        }
        const attempts = Number(qs.data()?.attempts || 0);
        tx.update(queueRef, {status:'running', attempts:attempts + 1, claimedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
        tx.update(taskRef, {status:'running', startedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp(), retryCount:attempts});
        tx.create(auditRef, {action:'nova.task.started', actorUid:'nova_worker', taskId, taskType:task.type, createdAt:FieldValue.serverTimestamp()});
        claimed = true;
      });
      if (!claimed) continue;

      try {
        if (task.type === 'circleci_check') {
          const result = await checkCircleCiJob(String(task.prompt || ''), {token:CIRCLECI_TOKEN.value().trim()});
          const finalStatus = result.state === 'succeeded' ? 'succeeded' :
            result.state === 'failed' ? 'failed' :
            result.state === 'unknown' ? 'verification_incomplete' : 'provider_processing';
          await db.runTransaction(async (tx) => {
            const qs = await tx.get(queueRef);
            const ts = await tx.get(taskRef);
            if (!qs.exists || !ts.exists || qs.data()?.status !== 'running' || ts.data()?.status !== 'running') return;
            tx.update(taskRef, {
              status:finalStatus,
              result:{
                text:result.text,
                provider:'circleci',
                evidenceUrl:result.jobUrl,
                jobNumber:result.jobNumber,
                runStatus:result.status,
                branch:result.branch,
                commit:result.commit,
                diagnostics:result.diagnostics,
              },
              error:finalStatus === 'failed' ? 'CircleCI job completed with a failure status.' :
                finalStatus === 'verification_incomplete' ? 'CircleCI job status could not be verified.' : null,
              completedAt:finalStatus === 'provider_processing' ? null : FieldValue.serverTimestamp(),
              updatedAt:FieldValue.serverTimestamp(),
            });
            tx.update(queueRef, {
              status:finalStatus,
              provider:finalStatus === 'provider_processing' ? 'circleci' : FieldValue.delete(),
              runUrl:result.jobUrl,
              jobNumber:result.jobNumber,
              completedAt:finalStatus === 'provider_processing' ? null : FieldValue.serverTimestamp(),
              updatedAt:FieldValue.serverTimestamp(),
            });
            tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
              action:result.state === 'failed' ? 'nova.circleci.failed_diagnosed' : 'nova.circleci.checked',
              actorUid:'nova_worker', taskId, taskType:task.type,
              jobNumber:result.jobNumber, status:result.status, evidenceUrl:result.jobUrl,
              diagnosticsStatus:result.diagnostics?.status || 'unknown',
              createdAt:FieldValue.serverTimestamp(),
            });
          });
        } else if (task.type === 'github_ci_check') {
          const result = await checkGithubActionsRun(String(task.prompt || ''), {token:NOVA_GITHUB_TOKEN.value().trim()});
          const diagnostics = result.state === 'failed'
            ? await diagnoseGithubActionsRun(result, NOVA_GITHUB_TOKEN.value().trim())
            : {status:'not_needed', failedJobs:[]};
          const finalStatus = result.state === 'succeeded' ? 'succeeded' :
            result.state === 'failed' ? 'failed' :
            result.state === 'unknown' ? 'verification_incomplete' : 'provider_processing';
          await db.runTransaction(async (tx) => {
            const qs = await tx.get(queueRef);
            const ts = await tx.get(taskRef);
            if (!qs.exists || !ts.exists || qs.data()?.status !== 'running' || ts.data()?.status !== 'running') return;
            tx.update(taskRef, {
              status:finalStatus,
              result:{
                text:result.text,
                provider:'github_actions',
                evidenceUrl:result.runUrl,
                runId:result.runId,
                runStatus:result.status,
                conclusion:result.conclusion,
                verifiedSuccess:result.verifiedSuccess,
                branch:result.branch,
                commit:result.commit,
                totalJobs:result.totalJobs,
                paginationComplete:result.paginationComplete,
                verificationError:result.verificationError,
                jobs:result.jobs,
                diagnostics,
              },
              error:finalStatus === 'failed' ? 'GitHub Actions run completed with a failure conclusion.' :
                finalStatus === 'verification_incomplete' ? (result.verificationError || 'GitHub job results could not be fully verified.') : null,
              completedAt:finalStatus === 'provider_processing' ? null : FieldValue.serverTimestamp(),
              updatedAt:FieldValue.serverTimestamp(),
            });
            tx.update(queueRef, {
              status:finalStatus,
              provider:finalStatus === 'provider_processing' ? 'github_actions' : FieldValue.delete(),
              runId:result.runId,
              runUrl:result.runUrl,
              completedAt:finalStatus === 'provider_processing' ? null : FieldValue.serverTimestamp(),
              updatedAt:FieldValue.serverTimestamp(),
            });
            tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
              action:result.verifiedSuccess ? 'nova.github_ci.verified_success' : 'nova.github_ci.checked',
              actorUid:'nova_worker', taskId, taskType:task.type,
              runId:result.runId, runStatus:result.status, conclusion:result.conclusion,
              verifiedSuccess:result.verifiedSuccess, evidenceUrl:result.runUrl,
              totalJobs:result.totalJobs, paginationComplete:result.paginationComplete,
              createdAt:FieldValue.serverTimestamp(),
            });
          });
        } else if (task.type === 'video_generation') {
          const endpoint = String(process.env.HIGGSFIELD_VIDEO_ENDPOINT || '').trim();
          const submitted = await submitVideoGeneration({
            endpoint,
            prompt:String(task.prompt || ''),
            keyId:HIGGSFIELD_API_KEY_ID.value().trim(),
            keySecret:HIGGSFIELD_API_KEY_SECRET.value().trim(),
          });
          await db.runTransaction(async (tx) => {
            const qs = await tx.get(queueRef);
            const ts = await tx.get(taskRef);
            if (!qs.exists || !ts.exists || qs.data()?.status !== 'running' || ts.data()?.status !== 'running') return;
            if (submitted.status.status === 'succeeded') {
              tx.update(taskRef, {status:'succeeded', provider:'higgsfield', providerRequestId:submitted.requestId,
                result:{provider:'higgsfield', requestId:submitted.requestId, videoUrl:submitted.status.outputUrl},
                error:null, completedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
              tx.update(queueRef, {status:'succeeded', providerRequestId:submitted.requestId, completedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
            } else if (submitted.status.status === 'failed') {
              tx.update(taskRef, {status:'failed', provider:'higgsfield', providerRequestId:submitted.requestId,
                error:submitted.status.error || 'Higgsfield generation failed', updatedAt:FieldValue.serverTimestamp()});
              tx.update(queueRef, {status:'failed', providerRequestId:submitted.requestId, error:submitted.status.error || 'Higgsfield generation failed', updatedAt:FieldValue.serverTimestamp()});
            } else {
              tx.update(taskRef, {status:'provider_processing', provider:'higgsfield', providerRequestId:submitted.requestId,
                providerStatusUrl:submitted.statusUrl, updatedAt:FieldValue.serverTimestamp()});
              tx.update(queueRef, {status:'provider_processing', providerRequestId:submitted.requestId, updatedAt:FieldValue.serverTimestamp()});
            }
            tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
              action:'nova.task.higgsfield_submitted', actorUid:'nova_worker', taskId, taskType:task.type,
              provider:'higgsfield', providerRequestId:submitted.requestId, createdAt:FieldValue.serverTimestamp(),
            });
          });
        } else {
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
        }
      } catch (error) {
        const message = String(error?.message || error).slice(0,500);
        const attempts = Number(initial.attempts || 0) + 1;
        const terminal = task?.type === 'video_generation' || task?.type === 'github_ci_check' || attempts >= 3 || message.includes('not configured');
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


exports.pollHiggsfieldVideoTasks = onSchedule(
  {schedule:'every 1 minutes', region:REGION, timeoutSeconds:180, memory:'512MiB', maxInstances:1, secrets:[HIGGSFIELD_API_KEY_ID, HIGGSFIELD_API_KEY_SECRET]},
  async () => {
    const queue = await db.collection('nova_task_queue').where('status','==','provider_processing').limit(10).get();
    for (const queueDoc of queue.docs) {
      const row = queueDoc.data() || {};
      const uid = String(row.ownerUid || '');
      const taskId = String(row.taskId || '');
      const requestId = String(row.providerRequestId || '');
      if (!uid || !taskId || !requestId) continue;
      const taskRef = db.collection('users').doc(uid).collection('nova_tasks').doc(taskId);
      try {
        const result = await getVideoGenerationStatus({
          requestId,
          keyId:HIGGSFIELD_API_KEY_ID.value().trim(),
          keySecret:HIGGSFIELD_API_KEY_SECRET.value().trim(),
        });
        if (result.status === 'processing') continue;
        const queueRef = queueDoc.ref;
        await db.runTransaction(async (tx) => {
          const qs = await tx.get(queueRef);
          const ts = await tx.get(taskRef);
          if (!qs.exists || !ts.exists || qs.data()?.status !== 'provider_processing' || ts.data()?.status !== 'provider_processing') return;
          const succeeded = result.status === 'succeeded';
          tx.update(taskRef, {
            status:succeeded ? 'succeeded' : 'failed',
            result:succeeded ? {provider:'higgsfield', requestId, videoUrl:result.outputUrl} : (ts.data()?.result || null),
            error:succeeded ? null : (result.error || 'Higgsfield generation failed'),
            completedAt:FieldValue.serverTimestamp(),
            updatedAt:FieldValue.serverTimestamp(),
          });
          tx.update(queueRef, {status:succeeded ? 'succeeded' : 'failed', error:succeeded ? null : (result.error || 'Higgsfield generation failed'),
            completedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
          tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
            action:succeeded ? 'nova.task.higgsfield_succeeded' : 'nova.task.higgsfield_failed',
            actorUid:'nova_worker', taskId, taskType:'video_generation', provider:'higgsfield',
            providerRequestId:requestId, createdAt:FieldValue.serverTimestamp(),
          });
        });
      } catch (error) {
        const message = String(error?.message || error).slice(0,500);
        await db.collection('users').doc(uid).collection('nova_audit').add({
          action:'nova.task.higgsfield_poll_error', actorUid:'nova_worker', taskId,
          taskType:'video_generation', provider:'higgsfield', providerRequestId:requestId,
          error:message, createdAt:FieldValue.serverTimestamp(),
        });
      }
    }
  }
);


// GitHub Actions runs may still be active on first inspection. Poll those
// tasks separately so provider_processing is a live state, not a dead end.
exports.pollCircleCiTasks = onSchedule(
  {schedule:'every 1 minutes', region:REGION, timeoutSeconds:180, memory:'512MiB', maxInstances:1, secrets:[CIRCLECI_TOKEN]},
  async () => {
    const queue = await db.collection('nova_task_queue')
      .where('provider', '==', 'circleci')
      .limit(20)
      .get();
    for (const queueDoc of queue.docs) {
      const row = queueDoc.data() || {};
      const uid = String(row.ownerUid || '');
      const taskId = String(row.taskId || '');
      const jobUrl = String(row.runUrl || '');
      if (!uid || !taskId || !jobUrl) continue;
      const queueRef = queueDoc.ref;
      const taskRef = db.collection('users').doc(uid).collection('nova_tasks').doc(taskId);
      let claimed = false;
      await db.runTransaction(async (tx) => {
        const qs = await tx.get(queueRef);
        const ts = await tx.get(taskRef);
        if (!qs.exists || !ts.exists ||
            qs.data()?.status !== 'provider_processing' ||
            ts.data()?.status !== 'provider_processing') return;
        const leaseUntil = qs.data()?.pollLeaseUntil?.toMillis?.() || 0;
        if (leaseUntil > Date.now()) return;
        tx.update(queueRef, {pollLeaseUntil:new Date(Date.now() + 120000), updatedAt:FieldValue.serverTimestamp()});
        claimed = true;
      });
      if (!claimed) continue;
      try {
        const result = await checkCircleCiJob(jobUrl, {token:CIRCLECI_TOKEN.value().trim()});
        const finalStatus = result.state === 'succeeded' ? 'succeeded' :
          result.state === 'failed' ? 'failed' :
          result.state === 'unknown' ? 'verification_incomplete' : 'provider_processing';
        await db.runTransaction(async (tx) => {
          const qs = await tx.get(queueRef);
          const ts = await tx.get(taskRef);
          if (!qs.exists || !ts.exists || qs.data()?.status !== 'provider_processing' ||
              qs.data()?.provider !== 'circleci' || ts.data()?.status !== 'provider_processing') return;
          tx.update(taskRef, {
            status:finalStatus,
            result:{
              text:result.text, provider:'circleci', evidenceUrl:result.jobUrl,
              jobNumber:result.jobNumber, runStatus:result.status, branch:result.branch,
              commit:result.commit, diagnostics:result.diagnostics,
            },
            error:finalStatus === 'failed' ? 'CircleCI job completed with a failure status.' :
              finalStatus === 'verification_incomplete' ? 'CircleCI job status could not be verified.' : null,
            completedAt:finalStatus === 'provider_processing' ? null : FieldValue.serverTimestamp(),
            updatedAt:FieldValue.serverTimestamp(),
          });
          tx.update(queueRef, {
            status:finalStatus, provider:finalStatus === 'provider_processing' ? 'circleci' : FieldValue.delete(),
            pollLeaseUntil:FieldValue.delete(), completedAt:finalStatus === 'provider_processing' ? null : FieldValue.serverTimestamp(),
            updatedAt:FieldValue.serverTimestamp(),
          });
          tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
            action:result.state === 'failed' ? 'nova.circleci.failed_diagnosed' : 'nova.circleci.polled',
            actorUid:'nova_worker', taskId, taskType:'circleci_check', jobNumber:result.jobNumber,
            status:result.status, evidenceUrl:result.jobUrl, diagnosticsStatus:result.diagnostics?.status || 'unknown',
            createdAt:FieldValue.serverTimestamp(),
          });
        });
      } catch (error) {
        const message = String(error?.message || error).slice(0,500);
        await db.runTransaction(async (tx) => {
          const qs = await tx.get(queueRef);
          const ts = await tx.get(taskRef);
          if (!qs.exists || !ts.exists || qs.data()?.status !== 'provider_processing' ||
              ts.data()?.status !== 'provider_processing') return;
          tx.update(queueRef, {pollLeaseUntil:FieldValue.delete(), lastPollError:message, updatedAt:FieldValue.serverTimestamp()});
          tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
            action:'nova.circleci.poll_error', actorUid:'nova_worker', taskId, taskType:'circleci_check',
            error:message, evidenceUrl:jobUrl, createdAt:FieldValue.serverTimestamp(),
          });
        });
      }
    }
  }
);

exports.pollGithubActionsTasks = onSchedule(
  {schedule:'every 1 minutes', region:REGION, timeoutSeconds:180, memory:'512MiB', maxInstances:1, secrets:[NOVA_GITHUB_TOKEN]},
  async () => {
    const queue = await db.collection('nova_task_queue')
      .where('provider', '==', 'github_actions')
      .limit(20)
      .get();
    for (const queueDoc of queue.docs) {
      const row = queueDoc.data() || {};
      if (row.provider !== 'github_actions') continue;
      const uid = String(row.ownerUid || '');
      const taskId = String(row.taskId || '');
      const runUrl = String(row.runUrl || '');
      if (!uid || !taskId || !runUrl) continue;
      const queueRef = queueDoc.ref;
      const taskRef = db.collection('users').doc(uid).collection('nova_tasks').doc(taskId);
      let claimed = false;
      await db.runTransaction(async (tx) => {
        const qs = await tx.get(queueRef);
        const ts = await tx.get(taskRef);
        if (!qs.exists || !ts.exists ||
            qs.data()?.status !== 'provider_processing' ||
            ts.data()?.status !== 'provider_processing') return;
        const leaseUntil = qs.data()?.pollLeaseUntil?.toMillis?.() || 0;
        if (leaseUntil > Date.now()) return;
        tx.update(queueRef, {
          pollLeaseUntil: new Date(Date.now() + 120000),
          updatedAt:FieldValue.serverTimestamp(),
        });
        claimed = true;
      });
      if (!claimed) continue;
      try {
        const result = await checkGithubActionsRun(runUrl, {token:NOVA_GITHUB_TOKEN.value().trim()});
        const diagnostics = result.state === 'failed'
          ? await diagnoseGithubActionsRun(result, NOVA_GITHUB_TOKEN.value().trim())
          : {status:'not_needed', failedJobs:[]};
        const finalStatus = result.state === 'succeeded' ? 'succeeded' :
          result.state === 'failed' ? 'failed' :
          result.state === 'unknown' ? 'verification_incomplete' : 'provider_processing';
        await db.runTransaction(async (tx) => {
          const qs = await tx.get(queueRef);
          const ts = await tx.get(taskRef);
          if (!qs.exists || !ts.exists ||
              qs.data()?.status !== 'provider_processing' ||
              qs.data()?.provider !== 'github_actions' ||
              ts.data()?.status !== 'provider_processing') return;
          tx.update(taskRef, {
            status:finalStatus,
            result:{
              text:result.text,
              provider:'github_actions',
              evidenceUrl:result.runUrl,
              runId:result.runId,
              runStatus:result.status,
              conclusion:result.conclusion,
              verifiedSuccess:result.verifiedSuccess,
              branch:result.branch,
              commit:result.commit,
              totalJobs:result.totalJobs,
              paginationComplete:result.paginationComplete,
              verificationError:result.verificationError,
              jobs:result.jobs,
              diagnostics,
            },
            error:finalStatus === 'failed' ? 'GitHub Actions run completed with a failure conclusion.' :
              finalStatus === 'verification_incomplete' ? (result.verificationError || 'GitHub job results could not be fully verified.') : null,
            completedAt:finalStatus === 'provider_processing' ? null : FieldValue.serverTimestamp(),
            updatedAt:FieldValue.serverTimestamp(),
          });
          tx.update(queueRef, {
            status:finalStatus,
            provider:finalStatus === 'provider_processing' ? 'github_actions' : FieldValue.delete(),
            pollLeaseUntil:FieldValue.delete(),
            completedAt:finalStatus === 'provider_processing' ? null : FieldValue.serverTimestamp(),
            updatedAt:FieldValue.serverTimestamp(),
          });
          tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
            action:result.verifiedSuccess ? 'nova.github_ci.verified_success' :
              finalStatus === 'verification_incomplete' ? 'nova.github_ci.verification_incomplete' :
              'nova.github_ci.polled',
            actorUid:'nova_worker', taskId, taskType:'github_ci_check',
            runId:result.runId, runStatus:result.status, conclusion:result.conclusion,
            verifiedSuccess:result.verifiedSuccess, evidenceUrl:result.runUrl,
            totalJobs:result.totalJobs, paginationComplete:result.paginationComplete,
            createdAt:FieldValue.serverTimestamp(),
          });
        });
      } catch (error) {
        const message = String(error?.message || error).slice(0, 500);
        await db.runTransaction(async (tx) => {
          const qs = await tx.get(queueRef);
          const ts = await tx.get(taskRef);
          if (!qs.exists || !ts.exists || qs.data()?.status !== 'provider_processing' ||
              ts.data()?.status !== 'provider_processing') return;
          tx.update(queueRef, {
            pollLeaseUntil:FieldValue.delete(),
            lastPollError:message,
            updatedAt:FieldValue.serverTimestamp(),
          });
          tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
            action:'nova.github_ci.poll_error', actorUid:'nova_worker',
            taskId, taskType:'github_ci_check', error:message,
            evidenceUrl:runUrl, createdAt:FieldValue.serverTimestamp(),
          });
        });
      }
    }
  }
);
