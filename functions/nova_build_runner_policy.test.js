'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  REQUIRED_ISOLATION,
  buildRunnerPlan,
  isRunnerEligible,
  isApprovalValid,
} = require('./nova_build_runner_policy');

test('Flutter plan uses a fixed allowlist and never executes by itself', () => {
  const plan = buildRunnerPlan('flutter');
  assert.equal(plan.status, 'waiting_for_isolated_runner');
  assert.equal(plan.executable, false);
  assert.equal(plan.requiresUserApprovalBeforeExecution, true);
  assert.deepEqual(plan.steps.map(step => step.id), [
    'dependencies', 'format_check', 'analyze', 'tests', 'debug_apk',
  ]);
  assert.ok(plan.steps.every(step => !step.args.some(arg => /[;&|\n]/.test(arg) || arg.includes(String.fromCharCode(96)))));
  assert.deepEqual(plan.requiredIsolation, [...REQUIRED_ISOLATION]);
});

test('automatic and unsupported stacks cannot execute', () => {
  assert.equal(buildRunnerPlan('auto').executable, false);
  assert.equal(buildRunnerPlan('unknown').status, 'unsupported_stack');
  assert.deepEqual(buildRunnerPlan('unknown').steps, []);
});

test('runner must attest every isolation requirement', () => {
  const eligible = {status:'ready', attested:true};
  for (const requirement of REQUIRED_ISOLATION) eligible[requirement] = true;
  assert.equal(isRunnerEligible(eligible), true);
  eligible.noProductionSecrets = false;
  assert.equal(isRunnerEligible(eligible), false);
  assert.equal(isRunnerEligible({status:'ready', attested:true}), false);
});

test('approval is bound to owner, job, and exact plan hash', () => {
  const job = {ownerUid:'owner-1', jobId:'job-1', planHash:'hash-1'};
  const approval = {approvedBy:'owner-1', jobId:'job-1', planHash:'hash-1', approved:true, approvedAt:'2026-10-27T12:00:00.000Z'};
  assert.equal(isApprovalValid(job, approval), true);
  assert.equal(isApprovalValid(job, {...approval, approvedBy:'other'}), false);
  assert.equal(isApprovalValid(job, {...approval, planHash:'changed'}), false);
  assert.equal(isApprovalValid(job, {...approval, approvedAt:'not-a-date'}), false);
});
