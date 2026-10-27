'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {SAFE_TEXT_TYPES, taskPayloadFingerprint, isTaskExecutable} = require('./nova_task_worker_policy');

const textTask = (type) => ({type, ownerUid:'owner-1', prompt:'Find useful opportunities', metadata:{source:'nova_android'}});

test('only bounded, owner-bound safe text tasks can run autonomously', () => {
  for (const type of ['chat', 'plan', 'research', 'content_draft', 'social_content_draft']) {
    assert.equal(SAFE_TEXT_TYPES.has(type), true, type + ' should be an allowed text task');
    assert.equal(isTaskExecutable(textTask(type), 'owner-1'), true);
  }
  for (const type of ['social_publish', 'image_generation', 'video_generation', 'github_ci_check', 'unknown']) {
    assert.equal(isTaskExecutable(textTask(type), 'owner-1'), false, type + ' must not run without a configured safe adapter');
  }
  assert.equal(isTaskExecutable(textTask('research'), 'owner-2'), false, 'another owner must not execute the task');
  assert.equal(isTaskExecutable({...textTask('research'), ownerUid:'owner-2'}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...textTask('research'), prompt:'  '}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...textTask('research'), prompt:'x'.repeat(6001)}, 'owner-1'), false);
});

test('video generation requires owner approval bound to the exact payload', () => {
  const task = {...textTask('video_generation'), requiresApproval:true, approvedBy:'owner-1'};
  task.approvalFingerprint = taskPayloadFingerprint(task);
  task.approvedFingerprint = task.approvalFingerprint;
  assert.equal(isTaskExecutable(task, 'owner-1'), true);
  assert.equal(isTaskExecutable(task, 'owner-2'), false);
  assert.equal(isTaskExecutable({...task, requiresApproval:false}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...task, approvedBy:'owner-2'}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...task, prompt:'different prompt'}, 'owner-1'), false, 'changed prompt invalidates approval');
  assert.equal(isTaskExecutable({...task, metadata:{source:'changed'}}, 'owner-1'), false, 'changed metadata invalidates approval');
  assert.equal(isTaskExecutable({...task, approvedFingerprint:'wrong'}, 'owner-1'), false);
  assert.equal(isTaskExecutable({...task, approvalFingerprint:'wrong'}, 'owner-1'), false);
});
