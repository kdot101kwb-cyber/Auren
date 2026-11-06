'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {SAFE_TEXT_TYPES, isTaskExecutable} = require('./nova_task_worker_policy');
const {createNovaApprovalScopeHash} = require('./nova_task_contract');

test('safe research and content-drafting tasks can run autonomously', () => {
  for (const type of ['chat', 'plan', 'research', 'content_draft', 'social_content_draft']) {
    assert.equal(SAFE_TEXT_TYPES.has(type), true, type + ' should be an allowed text task');
    assert.equal(isTaskExecutable({type}, 'owner-1'), true);
  }
  assert.equal(SAFE_TEXT_TYPES.has('social_publish'), false);
  assert.equal(SAFE_TEXT_TYPES.has('image_generation'), false);
  assert.equal(SAFE_TEXT_TYPES.has('video_generation'), false);
});

function approvedVideoTask(overrides = {}) {
  const task = {
    schemaVersion: 1,
    taskId: 'nova_video_task_123',
    ownerUid: 'owner-1',
    idempotencyKey: 'nova_video_task_123',
    type: 'video_generation',
    prompt: 'Create a short landscape video about a sunrise.',
    metadata: {source: 'nova_android', locale: 'ar'},
    requiresApproval: true,
    approvedBy: 'owner-1',
    approval: {
      required: true,
      approvedBy: 'owner-1',
      expiresAt: 2_000_000,
      scopeHash: null,
    },
  };
  Object.assign(task, overrides);
  task.approval = {...task.approval, scopeHash: createNovaApprovalScopeHash(task)};
  return task;
}

test('video generation stays blocked even with exact owner approval until a zero-cost provider is verified', () => {
  const task = approvedVideoTask();
  assert.equal(isTaskExecutable(task, 'owner-1', 1_000_000), false);
  assert.equal(isTaskExecutable(task, 'owner-2', 1_000_000), false);
  assert.equal(isTaskExecutable({...task, ownerUid: 'owner-2'}, 'owner-1', 1_000_000), false);
  assert.equal(isTaskExecutable({...task, requiresApproval: false}, 'owner-1', 1_000_000), false);
});

test('changing the approved prompt or metadata invalidates the approval hash', () => {
  const task = approvedVideoTask();
  assert.equal(isTaskExecutable({...task, prompt: 'Different video request'}, 'owner-1', 1_000_000), false);
  assert.equal(isTaskExecutable({...task, metadata: {...task.metadata, locale: 'en'}}, 'owner-1', 1_000_000), false);
  assert.equal(isTaskExecutable({...task, type: 'social_publish'}, 'owner-1', 1_000_000), false);
});

test('legacy approvals without an exact scope and expiry fail closed', () => {
  const legacy = {
    type: 'video_generation',
    ownerUid: 'owner-1',
    requiresApproval: true,
    approvedBy: 'owner-1',
  };
  assert.equal(isTaskExecutable(legacy, 'owner-1'), false);
  assert.equal(isTaskExecutable({type: 'social_publish', requiresApproval: true, approvedBy: 'owner-1'}, 'owner-1'), false);
});
