'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {SAFE_TEXT_TYPES, isTaskExecutable} = require('./nova_task_worker_policy');
const {createTaskApprovalScopeHash} = require('./nova_task_contract');

test('safe research and content-drafting tasks can run autonomously', () => {
  for (const type of ['chat', 'plan', 'research', 'content_draft', 'social_content_draft']) {
    assert.equal(SAFE_TEXT_TYPES.has(type), true, type + ' should be an allowed text task');
    assert.equal(isTaskExecutable({type, ownerUid:'owner-1'}, 'owner-1'), true);
  }
  assert.equal(SAFE_TEXT_TYPES.has('social_publish'), false);
  assert.equal(SAFE_TEXT_TYPES.has('image_generation'), false);
  assert.equal(SAFE_TEXT_TYPES.has('video_generation'), false);
});

test('video generation requires a matching owner approval bound to the exact task payload', () => {
  const base = {
    schemaVersion: 1,
    taskId: 'nova_task_123456',
    ownerUid: 'owner-1',
    type: 'video_generation',
    prompt: 'Create a short demo video',
    metadata: {source: 'nova_android'},
    executionMode: 'queued_backend_worker_required',
    estimatedCostUsd: 0,
    maxAttempts: 3,
    requiresApproval: true,
    approvedBy: 'owner-1',
  };
  const task = {...base, approval: {
    required: true,
    approvedBy: 'owner-1',
    scopeHash: createTaskApprovalScopeHash(base),
  }};
  assert.equal(isTaskExecutable(task, 'owner-1'), true);
  assert.equal(isTaskExecutable(task, 'owner-2'), false);
  assert.equal(isTaskExecutable({...task, ownerUid: 'owner-2'}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...task, requiresApproval: false}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...task, approvedBy: undefined}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...task, approval: {...task.approval, scopeHash: null}}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...task, prompt: 'Changed after approval'}, 'owner-1'), false);
  assert.equal(isTaskExecutable({type:'social_publish', requiresApproval:true, approvedBy:'owner-1'}, 'owner-1'), false);
});
