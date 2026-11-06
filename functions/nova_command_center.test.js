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


const {
  buildNovaMilestoneNotification,
  shouldNotifyNovaTransition,
} = require('./nova_notification_policy');

test('push policy notifies only on a new milestone status', () => {
  assert.equal(shouldNotifyNovaTransition('running', 'succeeded'), true);
  assert.equal(shouldNotifyNovaTransition('succeeded', 'succeeded'), false);
  assert.equal(shouldNotifyNovaTransition('running', 'running'), false);
  assert.equal(shouldNotifyNovaTransition('running', 'provider_processing'), false);
});

test('milestone push copy is localized and identifies success clearly', () => {
  const notification = buildNovaMilestoneNotification('succeeded', 'research');
  assert.equal(notification.title, '🟢 اكتملت مهمة NOVA');
  assert.match(notification.body, /بنجاح/);
});

test('approval and failure milestones have distinct messages', () => {
  assert.match(buildNovaMilestoneNotification('awaiting_approval', 'publish').title, /موافقتك/);
  assert.match(buildNovaMilestoneNotification('failed', 'research').body, /مراجعة السبب/);
  assert.equal(buildNovaMilestoneNotification('queued', 'research'), null);
});

test('accepts valid dependency IDs and defaults to an empty dependency list', () => {
  const task = normalizeNovaTaskInput({
    type:'research',
    prompt:'continue the report',
    idempotencyKey:'nova_task_654321',
    dependsOnTaskIds:['nova_task_123456'],
  });
  assert.deepEqual(task.dependsOnTaskIds, ['nova_task_123456']);
  assert.deepEqual(normalizeNovaTaskInput({
    type:'chat', prompt:'hello', idempotencyKey:'nova_task_654322',
  }).dependsOnTaskIds, []);
});

test('rejects invalid or self-referential task dependencies', () => {
  assert.throws(() => normalizeNovaTaskInput({
    type:'research', prompt:'x', idempotencyKey:'nova_task_654323',
    dependsOnTaskIds:['invalid'],
  }), /valid NOVA task ID/);
  assert.throws(() => normalizeNovaTaskInput({
    type:'research', prompt:'x', idempotencyKey:'nova_task_654324',
    dependsOnTaskIds:['nova_task_654324'],
  }), /itself/);
});
