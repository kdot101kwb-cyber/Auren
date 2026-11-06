'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  TASK_SCHEMA_VERSION,
  TASK_STATUSES,
  TERMINAL_STATUSES,
  canTransitionTask,
  createNovaTaskRecord,
  createTaskApprovalScopeHash,
  matchesTaskApprovalScope,
  createNovaQueueRecord,
  createNovaAuditEvent,
  normalizeTaskEvidence,
} = require('./nova_task_contract');

const input = {
  type: 'research',
  prompt: 'ابحث عن فرصة موثوقة',
  metadata: {source: 'nova_android', locale: 'ar'},
  requiresApproval: false,
};

test('creates a versioned task envelope with safe defaults and durable identity', () => {
  const task = createNovaTaskRecord({taskId: 'nova_task_123456', ownerUid: 'owner-1', input});
  assert.equal(task.schemaVersion, TASK_SCHEMA_VERSION);
  assert.equal(task.taskId, task.idempotencyKey);
  assert.equal(task.ownerUid, 'owner-1');
  assert.equal(task.status, 'queued');
  assert.equal(task.executionMode, 'queued_backend_worker_required');
  assert.equal(task.retryCount, 0);
  assert.equal(task.maxAttempts, 3);
  assert.equal(task.estimatedCostUsd, 0);
  assert.deepEqual(task.evidence, []);
  assert.equal(task.approval.required, false);
});

test('approval-required tasks start blocked from execution until approval', () => {
  const task = createNovaTaskRecord({
    taskId: 'nova_task_123456',
    ownerUid: 'owner-1',
    input: {...input, requiresApproval: true},
  });
  assert.equal(task.status, 'awaiting_approval');
  assert.equal(task.approval.required, true);
  assert.equal(task.approval.approvedBy, null);
});

test('queue envelope preserves owner and bounded retry contract', () => {
  const queue = createNovaQueueRecord({taskId: 'task-1', ownerUid: 'owner-1'});
  assert.equal(queue.schemaVersion, TASK_SCHEMA_VERSION);
  assert.equal(queue.status, 'queued');
  assert.equal(queue.maxAttempts, 3);
  assert.equal(queue.ownerUid, 'owner-1');
});

test('task status transitions reject skipped and terminal transitions', () => {
  assert.equal(canTransitionTask('queued', 'running'), true);
  assert.equal(canTransitionTask('running', 'verifying'), true);
  assert.equal(canTransitionTask('running', 'succeeded'), true);
  assert.equal(canTransitionTask('queued', 'succeeded'), false);
  assert.equal(canTransitionTask('succeeded', 'queued'), false);
  assert.equal(canTransitionTask('cancelled', 'running'), false);
  assert.equal(canTransitionTask('unknown', 'running'), false);
  for (const status of TERMINAL_STATUSES) {
    assert.equal(canTransitionTask(status, 'running'), false, status);
  }
  assert.ok(TASK_STATUSES.includes('provider_processing'));
});

test('audit events keep a stable schema and allowlisted details only', () => {
  const event = createNovaAuditEvent({
    action: 'nova.task.started',
    actorUid: 'nova_worker',
    taskId: 'task-1',
    taskType: 'research',
    details: {status: 'running', provider: 'openrouter', secret: 'must-not-leak'},
  });
  assert.equal(event.schemaVersion, TASK_SCHEMA_VERSION);
  assert.equal(event.taskType, 'research');
  assert.equal(event.status, 'running');
  assert.equal(event.secret, undefined);
});

test('evidence accepts only bounded HTTPS references with optional SHA-256', () => {
  const evidence = normalizeTaskEvidence([
    {kind: 'ci', uri: 'https://github.com/example/repo/actions/runs/1', label: 'CI', sha256: 'a'.repeat(64)},
    {kind: 'bad', uri: 'http://insecure.example'},
    {kind: 'bad', uri: 'javascript:alert(1)'},
    null,
  ]);
  assert.equal(evidence.length, 1);
  assert.equal(evidence[0].sha256, 'a'.repeat(64));
  assert.equal(normalizeTaskEvidence('not-an-array').length, 0);
});

test('invalid task envelopes fail closed', () => {
  assert.throws(() => createNovaTaskRecord({taskId: '', ownerUid: 'owner-1', input}), /required/);
  assert.throws(() => createNovaQueueRecord({taskId: 'task-1', ownerUid: 'owner-1', status: 'magic'}), /valid task status/);
  assert.throws(() => createNovaAuditEvent({action: 'x', actorUid: '', taskId: 'task-1'}), /required/);
});

test('approval scope hash is stable and changes when execution-relevant task data changes', () => {
  const task = createNovaTaskRecord({
    taskId: 'nova_task_123456',
    ownerUid: 'owner-1',
    input: {...input, requiresApproval: true},
  });
  const hash = createTaskApprovalScopeHash(task);
  assert.match(hash, /^[a-f0-9]{64}$/);
  assert.equal(matchesTaskApprovalScope(task, hash), true);
  assert.equal(matchesTaskApprovalScope({...task, prompt: 'different action'}, hash), false);
  assert.equal(matchesTaskApprovalScope({...task, metadata: {source: 'changed'}}, hash), false);
  assert.equal(matchesTaskApprovalScope(task, 'not-a-hash'), false);
});
