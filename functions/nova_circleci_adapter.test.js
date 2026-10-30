'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  parseCircleCiJobUrl,
  safeOutputUrl,
  extractCircleCiFailureEvidence,
  checkCircleCiJob,
} = require('./nova_circleci_adapter');

test('accepts only the configured AUREN CircleCI job URL', () => {
  assert.equal(parseCircleCiJobUrl('https://circleci.com/gh/kdot101kwb-cyber/Auren/28039').jobNumber, 28039);
  for (const url of [
    'http://circleci.com/gh/kdot101kwb-cyber/Auren/28039',
    'https://circleci.com/gh/other/repo/28039',
    'https://evil.example/gh/kdot101kwb-cyber/Auren/28039',
    'https://circleci.com/gh/kdot101kwb-cyber/Auren/28039?x=1',
  ]) assert.throws(() => parseCircleCiJobUrl(url));
});

test('allows only CircleCI signed output host URLs', () => {
  assert.ok(safeOutputUrl('https://output.circle-artifacts.com/0/raw/log.txt'));
  assert.equal(safeOutputUrl('https://evil.example/log.txt'), null);
  assert.equal(safeOutputUrl('http://output.circle-artifacts.com/log.txt'), null);
});

test('extracts failure lines and redacts credentials', () => {
  const evidence = extractCircleCiFailureEvidence([
    'compile started',
    'Error: compiler failed with ghp_abcdefghijklmnopqrstuvwxyz123456',
    'Authorization: Bearer abcdefghijklmnopqrstuvwxyz',
  ]);
  assert.equal(evidence.length, 1);
  assert.match(evidence[0].text, /REDACTED_GITHUB_TOKEN/);
  assert.doesNotMatch(evidence[0].text, /ghp_/);
  assert.match(extractCircleCiFailureEvidence(['Error: circle-token=ci_secret_value'])[0].text, /REDACTED/);
  assert.doesNotMatch(extractCircleCiFailureEvidence(['Error: circle-token=ci_secret_value'])[0].text, /ci_secret_value/);
});

test('requires a CircleCI token and does not call the API without one', async () => {
  const result = await checkCircleCiJob('https://circleci.com/gh/kdot101kwb-cyber/Auren/28039');
  assert.equal(result.state, 'unknown');
  assert.equal(result.diagnostics.status, 'not_configured');
});

test('reads failed CircleCI job step output and returns compact evidence', async () => {
  const calls = [];
  const fetchImpl = async (url) => {
    calls.push(url);
    if (url === 'https://circleci.com/api/v1.1/project/github/kdot101kwb-cyber/Auren/28039') {
      return new Response(JSON.stringify({
        build_num:28039,
        vcs_url:'https://github.com/kdot101kwb-cyber/Auren',
        status:'failed',
        branch:'feature/test',
        vcs_revision:'abc123',
        steps:[{name:'Run tests', step:2, actions:[{
          name:'npm test', status:'failed', exit_code:1, has_output:true,
          output_url:'https://output.circle-artifacts.com/0/raw/step.json',
        }]}],
      }), {status:200});
    }
    return new Response(JSON.stringify([{message:'Error: expected true but received false'}]), {status:200});
  };
  const result = await checkCircleCiJob(
    'https://circleci.com/gh/kdot101kwb-cyber/Auren/28039',
    {token:'test-token', fetchImpl},
  );
  assert.equal(result.state, 'failed');
  assert.equal(result.diagnostics.status, 'available');
  assert.match(result.diagnostics.failedSteps[0].evidence[0].text, /expected true/);
  assert.equal(calls.length, 2);
  assert.equal(result.diagnostics.failedSteps[0].truncated, false);
});

test('bounds CircleCI step output reads and marks oversized logs', async () => {
  const fetchImpl = async (url) => url.includes('/api/v1.1/')
    ? new Response(JSON.stringify({build_num:28039, status:'failed', steps:[{name:'test', actions:[{
        name:'npm test', status:'failed', has_output:true,
        output_url:'https://output.circle-artifacts.com/0/raw/step.json',
      }]}]}), {status:200})
    : new Response('Error: ' + 'x'.repeat(1501000), {status:200});
  const result = await checkCircleCiJob(
    'https://circleci.com/gh/kdot101kwb-cyber/Auren/28039',
    {token:'test-token', fetchImpl},
  );
  assert.equal(result.diagnostics.failedSteps[0].truncated, true);
});

test('does not follow untrusted step output URLs', async () => {
  let calls = 0;
  const fetchImpl = async () => {
    calls += 1;
    return new Response(JSON.stringify({
      build_num:28039, status:'failed',
      steps:[{name:'bad step', actions:[{
        name:'bad output', status:'failed', has_output:true,
        output_url:'https://evil.example/steal',
      }]}],
    }), {status:200});
  };
  const result = await checkCircleCiJob(
    'https://circleci.com/gh/kdot101kwb-cyber/Auren/28039',
    {token:'test-token', fetchImpl},
  );
  assert.equal(calls, 1);
  assert.equal(result.diagnostics.failedSteps[0].outputStatus, 'no_output');
});
