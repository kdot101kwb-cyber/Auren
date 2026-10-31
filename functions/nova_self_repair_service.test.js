'use strict';

const {initializeApp} = require('firebase-admin/app');
try { initializeApp({projectId:'auren-nova-repair-tests'}); } catch (_) {}
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  parseModelJson,
  requireAiDataTransferConsent,
  extractVerifiedEvidence,
  formatRepairEvidence,
  validateFailedTask,
  buildValidationResult,
  createIsolatedRepairCommit,
  containsCredentialMaterial,
  readRepairSourceFile,
  isStaleApplyingProposal,
  buildRecoveryDisposition,
  buildApplyCompletionDisposition,
  buildApplyFailureDisposition,
  verifySourceSecretScan,
} = require('./nova_self_repair_service');

const sha = 'a'.repeat(40);
const fileSha = 'b'.repeat(40);

test('requires explicit consent before AI source transfer', () => {
  assert.throws(() => requireAiDataTransferConsent(undefined), /Explicit owner consent/);
  assert.throws(() => requireAiDataTransferConsent(false), /Explicit owner consent/);
  assert.doesNotThrow(() => requireAiDataTransferConsent(true));
});

test('requires Gitleaks success on the exact source commit before AI transfer', async () => {
  const successFetch = async (url) => new Response(JSON.stringify({
    sha,
    statuses:[
      {context:'ci/circleci: gitleaks_scan', state:'success'},
      {context:'ci/circleci: functions_tests', state:'failure'},
    ],
  }), {status:200});
  const verified = await verifySourceSecretScan(sha, 'test-token', successFetch);
  assert.equal(verified.commitSha, sha);
  assert.equal(verified.state, 'success');

  const missingFetch = async () => new Response(JSON.stringify({sha, statuses:[]}), {status:200});
  await assert.rejects(() => verifySourceSecretScan(sha, 'test-token', missingFetch), /must pass the Gitleaks/);

  const failedFetch = async () => new Response(JSON.stringify({
    sha, statuses:[{context:'ci/circleci: gitleaks_scan', state:'failure'}],
  }), {status:200});
  await assert.rejects(() => verifySourceSecretScan(sha, 'test-token', failedFetch), /must pass the Gitleaks/);

  const wrongShaFetch = async () => new Response(JSON.stringify({
    sha:'f'.repeat(40), statuses:[{context:'ci/circleci: gitleaks_scan', state:'success'}],
  }), {status:200});
  await assert.rejects(() => verifySourceSecretScan(sha, 'test-token', wrongShaFetch), /did not match/);
});

test('parses bounded JSON model output and rejects malformed responses', () => {
  assert.deepEqual(parseModelJson('```json\n{"summary":"ok","files":[]}\n```'), {summary:'ok', files:[]});
  assert.throws(() => parseModelJson('not json'), /JSON repair proposal/);
});

test('accepts only owned failed CI tasks with available redacted evidence and a full commit SHA', () => {
  const task = {
    ownerUid:'owner-1',
    status:'failed',
    result:{
      provider:'github_actions',
      commit:sha,
      diagnostics:{status:'available', failedJobs:[{jobName:'flutter_ci', evidence:[{line:8,text:'Error: missing package'}]}]},
    },
  };
  assert.equal(validateFailedTask(task, 'owner-1').commitSha, sha);
  assert.equal(extractVerifiedEvidence(task.result).length, 1);
  assert.throws(() => validateFailedTask(task, 'owner-2'), /owned/);
  assert.throws(() => validateFailedTask({...task, status:'succeeded'}, 'owner-1'), /failed CI/);
  assert.throws(() => validateFailedTask({...task, result:{...task.result, diagnostics:{status:'unavailable'}}}, 'owner-1'), /evidence is unavailable/);
  assert.throws(() => validateFailedTask({...task, result:{...task.result, commit:'abc'}}, 'owner-1'), /commit SHA/);
});

test('redacts CI evidence before it is formatted for AI analysis', () => {
  const formatted = formatRepairEvidence([
    {source:'circleci', line:12, text:'Authorization: Bearer abcdefghijklmnopqrstuvwxyz123456'},
    {source:'github_actions', line:13, text:'OPENROUTER_API_KEY=sk-or-v1-1234567890abcdef'},
    {source:'circleci', line:14, text:'AKIA1234567890ABCDEF'},
    {source:'circleci', line:15, text:'sk-or-v1-abcdefghijklmnopqrstuvwxyz1234567890'},
  ]);
  assert.doesNotMatch(formatted, /abcdefghijklmnopqrstuvwxyz123456/);
  assert.doesNotMatch(formatted, /sk-or-v1-1234567890abcdef/);
  assert.doesNotMatch(formatted, /AKIA1234567890ABCDEF/);
  assert.doesNotMatch(formatted, /sk-or-v1-abcdefghijklmnopqrstuvwxyz1234567890/);
  assert.equal(containsCredentialMaterial('raw log: sk-or-v1-abcdefghijklmnopqrstuvwxyz1234567890'), true);
  assert.match(formatted, /REDACTED/);
  assert.ok(formatted.length <= 5000);
});

test('blocks credential-bearing source files before they can be passed to the repair model', async () => {
  const secretContent = 'const OPENROUTER_API_KEY = "sk-or-v1-1234567890abcdef";';
  const fetchImpl = async () => new Response(JSON.stringify({
    encoding:'base64',
    content:Buffer.from(secretContent, 'utf8').toString('base64'),
    sha:fileSha,
  }), {status:200});
  await assert.rejects(
    () => readRepairSourceFile('functions/nova_example.js', sha, 'test-token', fetchImpl),
    /credential-like material and cannot be sent/,
  );
});

test('allows a clean source file after verifying its GitHub blob metadata', async () => {
  const cleanContent = 'const token = process.env.API_KEY;\\nmodule.exports = true;';
  let requestedUrl = '';
  const fetchImpl = async (url) => {
    requestedUrl = url;
    return new Response(JSON.stringify({
      encoding:'base64',
      content:Buffer.from(cleanContent, 'utf8').toString('base64'),
      sha:fileSha,
    }), {status:200});
  };
  const result = await readRepairSourceFile('functions/nova_example.js', sha, 'test-token', fetchImpl);
  assert.equal(result.content, cleanContent);
  assert.equal(result.sha, fileSha);
  assert.match(requestedUrl, /ref=/);
});

test('only recovers applying operations after the 15-minute stale threshold', () => {
  const now = 2_000_000_000_000;
  assert.equal(isStaleApplyingProposal({state:'awaiting_approval', applyStartedAt:now - 900_000}, now), false);
  assert.equal(isStaleApplyingProposal({state:'applying', applyStartedAt:now - 899_999}, now), false);
  assert.equal(isStaleApplyingProposal({state:'applying', applyStartedAt:now - 900_000}, now), true);
  assert.equal(isStaleApplyingProposal({state:'applying'}, now), false);
  assert.equal(isStaleApplyingProposal({state:'applying', applyStartedAt:now + 1000}, now), false);
});

test('in-flight completion cannot overwrite a recovery quarantine', () => {
  const result = {branch:'nova/repairs/example', commitSha:'d'.repeat(40)};
  const recovered = buildApplyCompletionDisposition({state:'recovery_required'}, result);
  assert.equal(recovered.state, 'recovery_required');
  assert.equal(recovered.recoveryOutcome, 'apply_error_requires_manual_review');
  assert.equal(recovered.recoveryObservedCommitSha, null);
  const ambiguousRecovery = buildApplyCompletionDisposition({state:'recovery_required', recoveryOutcome:'apply_error_requires_manual_review'}, result);
  assert.equal(ambiguousRecovery.recoveryObservedCommitSha, null);
  assert.equal(ambiguousRecovery.recoveryOutcome, 'apply_error_requires_manual_review');
  assert.equal(recovered.repairCommitSha, result.commitSha);
  const normal = buildApplyCompletionDisposition({state:'applying'}, result);
  assert.equal(normal.state, 'validation_pending');
  assert.throws(() => buildApplyCompletionDisposition({state:'failed'}, result), /state changed/);
});

test('uncertain GitHub apply failures are quarantined instead of marked retryable', () => {
  const failure = buildApplyFailureDisposition({state:'applying'}, new Error('network timeout'));
  assert.equal(failure.state, 'recovery_required');
  assert.equal(failure.recoveryOutcome, 'apply_error_requires_manual_review');
  assert.match(failure.error, /network timeout/);
  const alreadyRecovered = buildApplyFailureDisposition({state:'recovery_required'}, new Error('late error'));
  assert.equal(alreadyRecovered.state, 'recovery_required');
  assert.throws(() => buildApplyFailureDisposition({state:'awaiting_approval'}, new Error('x')), /state changed/);
});
test('stale recovery always quarantines and never automatically re-approves', () => {
  const found = buildRecoveryDisposition('c'.repeat(40));
  assert.equal(found.state, 'recovery_required');
  assert.equal(found.branchFound, true);
  assert.equal(found.requiresManualReview, true);
  assert.equal(found.requiresOwnerReapproval, false);
  assert.equal(found.recoveryOutcome, 'branch_found');

  const notFound = buildRecoveryDisposition(null);
  assert.equal(notFound.state, 'recovery_required');
  assert.equal(notFound.branchFound, false);
  assert.equal(notFound.requiresManualReview, true);
  assert.equal(notFound.requiresOwnerReapproval, false);
  assert.equal(notFound.recoveryOutcome, 'branch_not_found_at_check');
});

test('repair validation requires every CircleCI gate on the exact pushed commit', () => {
  const proposal = {state:'validation_pending', repairCommitSha:sha};
  const required = [
    'ci/circleci: flutter_ci',
    'ci/circleci: functions_tests',
    'ci/circleci: plugin_worker_tests',
    'ci/circleci: action_executor_tests',
    'ci/circleci: plugin_worker_image',
    'ci/circleci: gitleaks_scan',
  ];
  const passed = buildValidationResult(proposal, required.map(context => ({context, state:'success'})));
  assert.equal(passed.state, 'verified');
  const missing = buildValidationResult(proposal, required.slice(0,4).map(context => ({context, state:'success'})));
  assert.equal(missing.state, 'validation_pending');
  const pending = buildValidationResult(proposal, required.map((context, index) => ({context, state:index ? 'success' : 'pending'})));
  assert.equal(pending.state, 'validation_pending');
  const failed = buildValidationResult(proposal, required.map((context, index) => ({context, state:index === 2 ? 'failure' : 'success'})));
  assert.equal(failed.state, 'failed');
  const latestFirst = buildValidationResult(proposal, [
    {context:required[0], state:'pending'},
    {context:required[0], state:'success'},
    ...required.slice(1).map(context => ({context, state:'success'})),
  ]);
  assert.equal(latestFirst.state, 'validation_pending');
});

test('creates a single isolated Git commit only after checking every expected source blob', async () => {
  const calls = [];
  const sourceTree = 'c'.repeat(40);
  const repairTree = 'd'.repeat(40);
  const repairCommit = 'e'.repeat(40);
  const fetchImpl = async (url, options = {}) => {
    calls.push({url, options});
    let payload;
    if (url.endsWith('/git/commits/' + sha)) payload = {sha, tree:{sha:sourceTree}};
    else if (url.includes('/contents/functions/nova_example.js?ref=')) payload = {sha:fileSha};
    else if (url.endsWith('/git/blobs')) payload = {sha:'f'.repeat(40)};
    else if (url.endsWith('/git/trees')) payload = {sha:repairTree};
    else if (url.endsWith('/git/commits')) payload = {sha:repairCommit};
    else if (url.endsWith('/git/refs')) payload = {ref:'refs/heads/nova/repairs/repairid123456789'};
    else throw new Error('Unexpected GitHub request: ' + url);
    return new Response(JSON.stringify(payload), {status:201});
  };
  const result = await createIsolatedRepairCommit({
    sourceCommitSha:sha,
    files:[{path:'functions/nova_example.js', content:'module.exports = true;', expectedSha:fileSha}],
  }, 'test-token', 'repairid123456789', fetchImpl);
  assert.equal(result.commitSha, repairCommit);
  assert.equal(result.branch, 'nova/repairs/repairid123456789');
  assert.equal(calls.length, 6);
  assert.equal(calls.at(-1).options.method, 'POST');
  assert.match(calls.at(-1).options.body, /refs\/heads\/nova\/repairs/);
});

test('refuses to write when a source blob changed after proposal creation', async () => {
  const fetchImpl = async (url) => new Response(JSON.stringify(
    url.endsWith('/git/commits/' + sha) ? {sha, tree:{sha:'c'.repeat(40)}} : {sha:'0'.repeat(40)},
  ), {status:200});
  await assert.rejects(() => createIsolatedRepairCommit({
    sourceCommitSha:sha,
    files:[{path:'functions/nova_example.js', content:'x', expectedSha:fileSha}],
  }, 'test-token', 'repairid123456789', fetchImpl), /Source file changed/);
});

test('credential scanner catches bearer, CircleCI, API secrets and common provider keys', () => {
  const samples = [
    'Authorization: Bearer abcdefghijklmnopqrstuvwxyz123456',
    'circle-token: circleci_abcdefghijklmnop',
    'const api_key = "this-is-a-long-hardcoded-secret-value";',
    'const access_token = "abcdefghijklmnopqrstuvwx";',
    'const secret = "abcdefghijklmnopqrstuvwx";',
    'const password = "abcdefghijklmnopqrstuvwx";',
    'AKIA1234567890ABCDEF',
    'AIza1234567890abcdefghijklmnopqrstuv',
    '-----BEGIN RSA PRIVATE KEY-----',
    'ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
    'github_pat_ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
    'sk-or-v1-abcdefghijklmnopqrstuvwxyz1234567890',
    'sk-proj-abcdefghijklmnopqrstuvwxyz1234567890',
  ];
  for (const sample of samples) {
    assert.equal(containsCredentialMaterial(sample), true, 'Expected secret pattern to be detected: ' + sample.slice(0, 24));
  }
  for (const sample of [
    'api_key: sk_live_1234567890abcdef',
    'OPENROUTER_API_KEY=sk-or-v1-1234567890abcdef',
    'password: long-password-value-123',
    'token = abcdefghijklmnopqrstuvwxyz123456',
  ]) {
    assert.equal(containsCredentialMaterial(sample), true, 'Expected unquoted secret assignment to be detected: ' + sample);
  }
  for (const safe of [
    'Authorization: Bearer [REDACTED]',
    'const api_key = process.env.API_KEY;',
    'const password = "";',
    'CircleCI job failed while running tests',
    'ordinary application source code',
  ]) {
    assert.equal(containsCredentialMaterial(safe), false, 'Unexpected secret detection: ' + safe);
  }
});