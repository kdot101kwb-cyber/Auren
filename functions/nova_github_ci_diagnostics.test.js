'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  redactSensitiveText,
  extractFailureEvidence,
  fetchGithubActionsJobDiagnostics,
  diagnoseGithubActionsRun,
} = require('./nova_github_ci_diagnostics');

test('extracts bounded failure evidence and redacts credentials', () => {
  const evidence = extractFailureEvidence([
    'Build started',
    'Error: request failed with token ghp_abcdefghijklmnopqrstuvwxyz123456',
    'Error: Authorization: Bearer abcdefghijklmnopqrstuvwxyz',
    'All done',
  ].join('\n'));
  assert.equal(evidence.length, 2);
  assert.match(evidence[0].text, /REDACTED_GITHUB_TOKEN/);
  assert.doesNotMatch(evidence[0].text, /ghp_/);
  assert.match(redactSensitiveText('api_key=secret-value'), /REDACTED/);
});

test('does not request private logs without a configured token', async () => {
  const result = await fetchGithubActionsJobDiagnostics({runId:123, jobId:456});
  assert.equal(result.status, 'not_configured');
});

test('verifies job ownership before downloading its log', async () => {
  const calls = [];
  const fetchImpl = async (url) => {
    calls.push(url);
    if (url.endsWith('/logs')) return new Response('Error: compiler failed', {status:200});
    return new Response(JSON.stringify({id:456, run_id:999, status:'completed', conclusion:'failure'}), {status:200});
  };
  await assert.rejects(
    () => fetchGithubActionsJobDiagnostics({runId:123, jobId:456, token:'test-token', fetchImpl}),
    /does not belong/,
  );
  assert.equal(calls.length, 1);
  assert.equal(calls[0].endsWith('/logs'), false);
});

test('downloads only a failed job log and returns compact evidence', async () => {
  const calls = [];
  const fetchImpl = async (url) => {
    calls.push(url);
    if (url.endsWith('/logs')) return new Response('Step 1 ok\nError: compilation failed\nDone', {status:200});
    return new Response(JSON.stringify({
      id:456, run_id:123, name:'Flutter analyze', status:'completed', conclusion:'failure',
      steps:[{name:'Analyze', conclusion:'failure'}],
    }), {status:200});
  };
  const result = await fetchGithubActionsJobDiagnostics({runId:123, jobId:456, token:'test-token', fetchImpl});
  assert.equal(result.status, 'available');
  assert.equal(result.failedSteps[0], 'Analyze');
  assert.match(result.evidence[0].text, /compilation failed/);
  assert.equal(calls.length, 2);
});

test('diagnoses failed workflow jobs without attempting any write operation', async () => {
  const result = await diagnoseGithubActionsRun({
    state:'failed', runId:123,
    jobs:[{jobId:456, name:'test', status:'completed', conclusion:'failure'}],
  }, null);
  assert.equal(result.status, 'not_configured');
  assert.equal(result.failedJobs.length, 0);
});
