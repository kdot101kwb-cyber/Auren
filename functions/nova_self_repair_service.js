'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {
  createRepairProposal,
  approveRepairProposal,
  canApplyRepairProposal,
  evaluateRepairValidation,
} = require('./nova_self_repair_engine');

const db = getFirestore();
const NOVA_GITHUB_REPAIR_TOKEN = defineSecret('NOVA_GITHUB_REPAIR_TOKEN');
const REGION = 'us-central1';
const REPOSITORY = 'kdot101kwb-cyber/Auren';
const API = 'https://api.github.com';
const REQUIRED_CHECKS = [
  'ci/circleci: flutter_ci',
  'ci/circleci: functions_tests',
  'ci/circleci: plugin_worker_tests',
  'ci/circleci: action_executor_tests',
  'ci/circleci: plugin_worker_image',
];

function extractVerifiedEvidence(result) {
  const diagnostics = result?.diagnostics || {};
  const rows = [];
  for (const job of Array.isArray(diagnostics.failedJobs) ? diagnostics.failedJobs : []) {
    for (const item of Array.isArray(job.evidence) ? job.evidence : []) {
      rows.push({source:String(job.jobName || 'github_actions'), line:item.line, text:item.text});
    }
  }
  for (const step of Array.isArray(diagnostics.failedSteps) ? diagnostics.failedSteps : []) {
    for (const item of Array.isArray(step.evidence) ? step.evidence : []) {
      rows.push({source:String(step.name || 'circleci'), line:item.line, text:item.text});
    }
  }
  return rows.slice(0, 12);
}

function validateFailedTask(task, uid) {
  if (!task || task.ownerUid !== uid || task.status !== 'failed') {
    throw new Error('Repair proposals require an owned, completed failed CI task.');
  }
  const result = task.result || {};
  if (!['github_actions', 'circleci'].includes(String(result.provider || ''))) {
    throw new Error('The task is not a supported GitHub Actions or CircleCI diagnostic.');
  }
  if (result.diagnostics?.status !== 'available') {
    throw new Error('Verified failure evidence is unavailable; no repair proposal can be created.');
  }
  const commitSha = String(result.commit || result.commitSha || '');
  if (!/^[a-f0-9]{40}$/i.test(commitSha)) {
    throw new Error('The failed CI task does not contain a verified source commit SHA.');
  }
  const evidence = extractVerifiedEvidence(result);
  if (!evidence.length) throw new Error('No bounded failure evidence is available.');
  return {provider:result.provider, commitSha, evidence};
}

function apiPath(path) {
  return path.split('/').map(encodeURIComponent).join('/');
}

async function githubRequest(path, token, options = {}) {
  const response = await fetch(API + path, {
    method:options.method || 'GET',
    headers:{
      accept:'application/vnd.github+json',
      authorization:'Bearer ' + token,
      'x-github-api-version':'2022-11-28',
      ...(options.body ? {'content-type':'application/json'} : {}),
    },
    body:options.body ? JSON.stringify(options.body) : undefined,
    signal:options.signal,
  });
  const raw = await response.text();
  let payload = {};
  try { payload = raw ? JSON.parse(raw) : {}; } catch (_) {}
  if (!response.ok) {
    const error = new Error('GitHub repair API returned HTTP ' + response.status + '.');
    error.status = response.status;
    throw error;
  }
  return payload;
}

async function createIsolatedRepairCommit(proposal, token, proposalId, fetchImpl = fetch) {
  if (!token) throw new Error('NOVA_GITHUB_REPAIR_TOKEN is not configured.');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 60000);
  try {
    const request = async (path, options = {}) => {
      const response = await fetchImpl(API + path, {
        method:options.method || 'GET',
        headers:{
          accept:'application/vnd.github+json',
          authorization:'Bearer ' + token,
          'x-github-api-version':'2022-11-28',
          ...(options.body ? {'content-type':'application/json'} : {}),
        },
        body:options.body ? JSON.stringify(options.body) : undefined,
        signal:controller.signal,
      });
      const raw = await response.text();
      let payload = {};
      try { payload = raw ? JSON.parse(raw) : {}; } catch (_) {}
      if (!response.ok) throw new Error('GitHub repair API returned HTTP ' + response.status + '.');
      return payload;
    };
    const source = await request('/repos/' + REPOSITORY + '/git/commits/' + proposal.sourceCommitSha);
    if (String(source.sha || '') !== proposal.sourceCommitSha || !/^[a-f0-9]{40}$/i.test(String(source.tree?.sha || ''))) {
      throw new Error('GitHub did not verify the exact source commit and tree.');
    }
    for (const file of proposal.files) {
      const current = await request('/repos/' + REPOSITORY + '/contents/' + apiPath(file.path) + '?ref=' + encodeURIComponent(proposal.sourceCommitSha));
      if (String(current.sha || '') !== file.expectedSha) {
        throw new Error('Source file changed since proposal creation: ' + file.path);
      }
    }
    const tree = [];
    for (const file of proposal.files) {
      const blob = await request('/repos/' + REPOSITORY + '/git/blobs', {
        method:'POST',
        body:{content:file.content, encoding:'utf-8'},
      });
      if (!/^[a-f0-9]{40}$/i.test(String(blob.sha || ''))) throw new Error('GitHub did not return a valid patch blob SHA.');
      tree.push({path:file.path, mode:'100644', type:'blob', sha:blob.sha});
    }
    const nextTree = await request('/repos/' + REPOSITORY + '/git/trees', {
      method:'POST',
      body:{base_tree:source.tree.sha, tree},
    });
    if (!/^[a-f0-9]{40}$/i.test(String(nextTree.sha || ''))) throw new Error('GitHub did not return a valid repair tree SHA.');
    const commit = await request('/repos/' + REPOSITORY + '/git/commits', {
      method:'POST',
      body:{
        message:'NOVA repair proposal ' + proposalId,
        tree:nextTree.sha,
        parents:[proposal.sourceCommitSha],
      },
    });
    if (!/^[a-f0-9]{40}$/i.test(String(commit.sha || ''))) throw new Error('GitHub did not return a valid repair commit SHA.');
    const branch = 'nova/repairs/' + String(proposalId).toLowerCase();
    await request('/repos/' + REPOSITORY + '/git/refs', {
      method:'POST',
      body:{ref:'refs/heads/' + branch, sha:commit.sha},
    });
    return {branch, commitSha:commit.sha};
  } finally {
    clearTimeout(timeout);
  }
}

function buildValidationResult(proposal, statuses) {
  const byContext = new Map();
  for (const item of Array.isArray(statuses) ? statuses : []) {
    const context = String(item.context || '');
    if (REQUIRED_CHECKS.includes(context)) byContext.set(context, item);
  }
  const checks = REQUIRED_CHECKS.filter(name => byContext.has(name)).map(name => ({
    name,
    conclusion:String(byContext.get(name)?.state || 'pending') === 'success' ? 'success' :
      String(byContext.get(name)?.state || 'pending') === 'failure' ? 'failure' : 'pending',
  }));
  return evaluateRepairValidation(
    {...proposal, state:'validation_pending'},
    {commitSha:proposal.repairCommitSha, validatedCommitSha:proposal.repairCommitSha, requiredChecks:REQUIRED_CHECKS, checks},
  );
}

exports.createNovaRepairProposal = onCall(
  {region:REGION, timeoutSeconds:30, memory:'256MiB', enforceAppCheck:true, consumeAppCheckToken:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to create a NOVA repair proposal.');
    const taskId = String(request.data?.taskId || '').trim();
    if (!/^[A-Za-z0-9_-]{12,128}$/.test(taskId)) throw new HttpsError('invalid-argument', 'Invalid source task ID.');
    const taskSnap = await db.collection('users').doc(uid).collection('nova_tasks').doc(taskId).get();
    if (!taskSnap.exists) throw new HttpsError('not-found', 'Source CI task was not found.');
    try {
      const verified = validateFailedTask(taskSnap.data(), uid);
      const proposal = createRepairProposal({
        provider:verified.provider,
        failureVerified:true,
        commitSha:verified.commitSha,
        evidence:verified.evidence,
        summary:request.data?.summary,
        files:request.data?.files,
      });
      const ref = db.collection('users').doc(uid).collection('nova_repair_proposals').doc();
      await ref.create({
        ...proposal,
        proposalId:ref.id,
        ownerUid:uid,
        sourceTaskId:taskId,
        createdAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
      });
      await db.collection('users').doc(uid).collection('nova_audit').add({
        action:'nova.repair.proposed',
        actorUid:uid,
        proposalId:ref.id,
        sourceTaskId:taskId,
        sourceCommitSha:verified.commitSha,
        createdAt:FieldValue.serverTimestamp(),
      });
      return {ok:true, proposalId:ref.id, state:'awaiting_approval', requiresOwnerApproval:true};
    } catch (error) {
      throw new HttpsError('failed-precondition', String(error.message || error).slice(0,300));
    }
  },
);

exports.approveAndApplyNovaRepair = onCall(
  {region:REGION, timeoutSeconds:120, memory:'512MiB', enforceAppCheck:true, consumeAppCheckToken:true, secrets:[NOVA_GITHUB_REPAIR_TOKEN]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to approve a NOVA repair.');
    const proposalId = String(request.data?.proposalId || '').trim();
    if (!/^[A-Za-z0-9]{15,40}$/.test(proposalId)) throw new HttpsError('invalid-argument', 'Invalid repair proposal ID.');
    const ref = db.collection('users').doc(uid).collection('nova_repair_proposals').doc(proposalId);
    let proposal;
    await db.runTransaction(async tx => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError('not-found', 'Repair proposal was not found.');
      const current = snap.data() || {};
      if (current.ownerUid !== uid) throw new HttpsError('permission-denied', 'Only the proposal owner can approve it.');
      if (current.state !== 'awaiting_approval') throw new HttpsError('failed-precondition', 'Proposal is not awaiting approval.');
      const approved = approveRepairProposal(current, uid, uid);
      if (!canApplyRepairProposal(approved, uid, 'nova/repairs/' + proposalId.toLowerCase())) {
        throw new HttpsError('failed-precondition', 'Repair proposal failed the isolated-branch policy.');
      }
      proposal = {...approved, state:'applying'};
      tx.update(ref, {state:'applying', approvedBy:uid, approvedAt:FieldValue.serverTimestamp(), updatedAt:FieldValue.serverTimestamp()});
      tx.create(db.collection('users').doc(uid).collection('nova_audit').doc(), {
        action:'nova.repair.approved', actorUid:uid, proposalId,
        createdAt:FieldValue.serverTimestamp(),
      });
    });
    try {
      const result = await createIsolatedRepairCommit(proposal, NOVA_GITHUB_REPAIR_TOKEN.value().trim(), proposalId);
      await ref.update({
        state:'validation_pending',
        repairBranch:result.branch,
        repairCommitSha:result.commitSha,
        appliedAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
      });
      await db.collection('users').doc(uid).collection('nova_audit').add({
        action:'nova.repair.branch_pushed', actorUid:'nova_worker', proposalId,
        repairBranch:result.branch, repairCommitSha:result.commitSha,
        createdAt:FieldValue.serverTimestamp(),
      });
      return {ok:true, proposalId, state:'validation_pending', branch:result.branch, commitSha:result.commitSha, pullRequestCreated:false};
    } catch (error) {
      await ref.update({state:'failed', error:String(error.message || error).slice(0,300), updatedAt:FieldValue.serverTimestamp()});
      await db.collection('users').doc(uid).collection('nova_audit').add({
        action:'nova.repair.apply_failed', actorUid:'nova_worker', proposalId,
        error:String(error.message || error).slice(0,300), createdAt:FieldValue.serverTimestamp(),
      });
      throw new HttpsError('failed-precondition', String(error.message || error).slice(0,300));
    }
  },
);

exports.checkNovaRepairValidation = onCall(
  {region:REGION, timeoutSeconds:45, memory:'256MiB', enforceAppCheck:true, secrets:[NOVA_GITHUB_REPAIR_TOKEN]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to check a NOVA repair.');
    const proposalId = String(request.data?.proposalId || '').trim();
    if (!/^[A-Za-z0-9]{15,40}$/.test(proposalId)) throw new HttpsError('invalid-argument', 'Invalid repair proposal ID.');
    const ref = db.collection('users').doc(uid).collection('nova_repair_proposals').doc(proposalId);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError('not-found', 'Repair proposal was not found.');
    const proposal = snap.data() || {};
    if (proposal.ownerUid !== uid) throw new HttpsError('permission-denied', 'Only the proposal owner can inspect it.');
    if (proposal.state !== 'validation_pending' || !/^[a-f0-9]{40}$/i.test(String(proposal.repairCommitSha || ''))) {
      throw new HttpsError('failed-precondition', 'Repair is not awaiting CI validation.');
    }
    const token = NOVA_GITHUB_REPAIR_TOKEN.value().trim();
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 30000);
    try {
      const response = await fetch(API + '/repos/' + REPOSITORY + '/commits/' + proposal.repairCommitSha + '/status', {
        headers:{accept:'application/vnd.github+json', authorization:'Bearer ' + token, 'x-github-api-version':'2022-11-28'},
        signal:controller.signal,
      });
      if (!response.ok) throw new HttpsError('unavailable', 'GitHub CI status lookup failed with HTTP ' + response.status + '.');
      const payload = await response.json();
      const updated = buildValidationResult(proposal, payload.statuses || []);
      await ref.update({
        state:updated.state,
        validation:updated.validation,
        validationCheckedAt:FieldValue.serverTimestamp(),
        updatedAt:FieldValue.serverTimestamp(),
      });
      return {ok:true, proposalId, state:updated.state, validation:updated.validation, repairCommitSha:proposal.repairCommitSha};
    } finally {
      clearTimeout(timeout);
    }
  },
);

exports.extractVerifiedEvidence = extractVerifiedEvidence;
exports.validateFailedTask = validateFailedTask;
exports.buildValidationResult = buildValidationResult;
exports.createIsolatedRepairCommit = createIsolatedRepairCommit;
