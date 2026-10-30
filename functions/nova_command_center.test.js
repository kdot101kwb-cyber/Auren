'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeNovaTaskInput} = require('./nova_command_validation');

test('accepts a bounded task with stable idempotency key', () => {
  const task = normalizeNovaTaskInput({type:'research',prompt:'ابحث عن فرصة',idempotencyKey:'nova_task_123456'});
  assert.equal(task.type,'research');
  assert.equal(task.requiresApproval,false);
  assert.equal(task.metadata.locale,'ar');
});

test('accepts read-only CI diagnostic task types without approval', () => {
  for (const type of ['github_ci_check', 'circleci_check']) {
    const task = normalizeNovaTaskInput({type, prompt:'https://circleci.com/gh/kdot101kwb-cyber/Auren/28039', idempotencyKey:'nova_task_123456'});
    assert.equal(task.requiresApproval, false);
  }
});

test('accepts self-repair planning as a read-only proposal task', () => {
  const task = normalizeNovaTaskInput({type:'self_repair_plan',prompt:'{}',idempotencyKey:'nova_task_123456'});
  assert.equal(task.requiresApproval, false);
});

test('rejects unknown task types and missing prompt', () => {
  assert.throws(() => normalizeNovaTaskInput({type:'root_access',prompt:'x',idempotencyKey:'nova_task_123456'}), /Unsupported NOVA task type/);
  assert.throws(() => normalizeNovaTaskInput({type:'chat',prompt:' ',idempotencyKey:'nova_task_123456'}), /Prompt/);
});

test('requires idempotency key to prevent duplicate task creation', () => {
  assert.throws(() => normalizeNovaTaskInput({type:'chat',prompt:'hello',idempotencyKey:'short'}), /idempotencyKey/);
});

test('external side effects require approval by default', () => {
  assert.equal(normalizeNovaTaskInput({type:'social_publish',prompt:'publish',idempotencyKey:'nova_task_123456'}).requiresApproval,true);
  assert.equal(normalizeNovaTaskInput({type:'chat',prompt:'answer',idempotencyKey:'nova_task_123456',requiresApproval:true}).requiresApproval,true);
});

test('limits prompt size and normalizes metadata', () => {
  assert.throws(() => normalizeNovaTaskInput({type:'chat',prompt:'x'.repeat(6001),idempotencyKey:'nova_task_123456'}), /Prompt/);
  const task = normalizeNovaTaskInput({type:'chat',prompt:'hello',idempotencyKey:'nova_task_123456',metadata:{source:'a'.repeat(100),locale:'ar-SA'}});
  assert.equal(task.metadata.source.length,80);
});
