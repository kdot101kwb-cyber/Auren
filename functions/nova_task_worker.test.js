'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {SAFE_TEXT_TYPES, isTaskExecutable} = require('./nova_task_worker_policy');

test('safe research and content-drafting tasks can run autonomously', () => {
  for (const type of ['chat', 'plan', 'research', 'content_draft', 'social_content_draft']) {
    assert.equal(SAFE_TEXT_TYPES.has(type), true, type + ' should be an allowed text task');
    assert.equal(isTaskExecutable({type}, 'owner-1'), true);
  }
  assert.equal(SAFE_TEXT_TYPES.has('social_publish'), false);
  assert.equal(SAFE_TEXT_TYPES.has('image_generation'), false);
  assert.equal(SAFE_TEXT_TYPES.has('video_generation'), false);
});

test('video generation is executable only after the owner explicitly approves it', () => {
  const task = {type:'video_generation', requiresApproval:true, approvedBy:'owner-1'};
  assert.equal(isTaskExecutable(task, 'owner-1'), true);
  assert.equal(isTaskExecutable(task, 'owner-2'), false);
  assert.equal(isTaskExecutable({...task, requiresApproval:false}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...task, approvedBy:undefined}, 'owner-1'), false);
  assert.equal(isTaskExecutable({type:'social_publish', requiresApproval:true, approvedBy:'owner-1'}, 'owner-1'), false);
});
