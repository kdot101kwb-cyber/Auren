'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {parseGithubRunUrl, checkGithubActionsRun} = require('./nova_github_ci_adapter');
test('accepts only HTTPS run links for the configured repository', () => {
  assert.equal(parseGithubRunUrl('https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345').runId, '12345');
  for (const url of ['http://github.com/kdot101kwb-cyber/Auren/actions/runs/12345','https://github.com/other/repo/actions/runs/12345','https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345?x=1','https://evil.example/x']) assert.throws(() => parseGithubRunUrl(url));
});
test('green requires completed successful run and every returned job', async () => {
  const payloads = [{id:12345,status:'completed',conclusion:'success',head_branch:'feature',head_sha:'abc'}, {jobs:[{name:'build',status:'completed',conclusion:'success',steps:[]}]}];
  const result = await checkGithubActionsRun('https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345', {fetchImpl:async () => new Response(JSON.stringify(payloads.shift()), {status:200})});
  assert.equal(result.verifiedSuccess, true);
  assert.equal(result.state, 'succeeded');
});
test('never reports green for an active run or failed job', async () => {
  for (const payloads of [
    [{id:12345,status:'in_progress',conclusion:null},{jobs:[]}],
    [{id:12345,status:'completed',conclusion:'success'},{jobs:[{name:'test',status:'completed',conclusion:'failure',steps:[]}]}],
  ]) {
    const result = await checkGithubActionsRun('https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345', {fetchImpl:async () => new Response(JSON.stringify(payloads.shift()), {status:200})});
    assert.notEqual(result.verifiedSuccess, true);
  }
});
test('fails closed on GitHub API errors', async () => {
  await assert.rejects(() => checkGithubActionsRun('https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345', {fetchImpl:async () => new Response('{}',{status:404})}), /HTTP 404/);
});
