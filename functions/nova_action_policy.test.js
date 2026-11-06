'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  ACTION_POLICIES,
  APPROVAL_REQUIRED_TYPES,
  getNovaActionPolicy,
  isNovaActionApprovalValid,
  canNovaWorkerExecute,
} = require('./nova_action_policy');
const {createNovaApprovalScopeHash} = require('./nova_task_contract');

test('known side-effect and sensitive actions require owner approval by default', () => {
  for (const type of [
    'image_generation', 'video_generation', 'social_publish', 'send_message',
    'purchase', 'paid_api_call', 'production_deploy', 'delete_data',
    'permission_change', 'data_migration', 'secret_rotation',
  ]) {
    assert.equal(APPROVAL_REQUIRED_TYPES.has(type), true, type);
    assert.equal(getNovaActionPolicy(type).approvalRequired, true, type);
  }
});

test('unknown actions are high-risk and cannot be executed by the worker', () => {
  assert.deepEqual(getNovaActionPolicy('unregistered_action'), {
    risk: 'unknown', approvalRequired: true, workerExecutable: false,
  });
  assert.equal(canNovaWorkerExecute({type: 'unregistered_action'}, 'owner-1'), false);
});

test('only explicitly registered safe text actions are autonomously executable', () => {
  for (const type of ['chat', 'plan', 'research', 'content_draft', 'social_content_draft']) {
    assert.equal(canNovaWorkerExecute({type, requiresApproval: false}, 'owner-1'), true);
  }
  for (const type of ['social_publish', 'image_generation', 'video_generation', 'purchase', 'production_deploy']) {
    assert.equal(canNovaWorkerExecute({type, requiresApproval: true}, 'owner-1'), false);
  }
});

function taskWithApproval(overrides = {}) {
  const task = {
    schemaVersion: 1,
    taskId: 'nova_action_123456',
    ownerUid: 'owner-1',
    type: 'video_generation',
    prompt: 'Generate a private preview video',
    metadata: {source: 'nova_android', locale: 'ar'},
    requiresApproval: true,
    approval: {required: true, approvedBy: 'owner-1', expiresAt: 5000, scopeHash: ''},
    ...overrides,
  };
  task.approval = {
    ...task.approval,
    scopeHash: createNovaApprovalScopeHash(task),
  };
  return task;
}

test('approval is valid only for the same owner, exact action, and unexpired scope', () => {
  const task = taskWithApproval();
  assert.equal(isNovaActionApprovalValid(task, 'owner-1', 1000), true);
  assert.equal(isNovaActionApprovalValid(task, 'owner-2', 1000), false);
  assert.equal(isNovaActionApprovalValid({...task, prompt: 'Publish publicly instead'}, 'owner-1', 1000), false);
  assert.equal(isNovaActionApprovalValid({...task, metadata: {...task.metadata, locale: 'en'}}, 'owner-1', 1000), false);
  assert.equal(isNovaActionApprovalValid(task, 'owner-1', 5000), false);
  assert.equal(isNovaActionApprovalValid({...task, approval: {...task.approval, scopeHash: 'bad'}}, 'owner-1', 1000), false);
});

test('approved but unconnected side-effect adapters remain non-executable', () => {
  const social = taskWithApproval({type: 'social_publish'});
  assert.equal(isNovaActionApprovalValid(social, 'owner-1', 1000), true);
  assert.equal(canNovaWorkerExecute(social, 'owner-1', 1000), false);
  const image = taskWithApproval({type: 'image_generation'});
  assert.equal(isNovaActionApprovalValid(image, 'owner-1', 1000), true);
  assert.equal(canNovaWorkerExecute(image, 'owner-1', 1000), false);
  const video = taskWithApproval({type: 'video_generation'});
  assert.equal(isNovaActionApprovalValid(video, 'owner-1', 1000), true);
  assert.equal(canNovaWorkerExecute(video, 'owner-1', 1000), false);
});


test('revoked approvals are immediately invalid even before expiry', () => {
  const task = taskWithApproval();
  const revoked = {
    ...task,
    approval: {
      ...task.approval,
      approvedBy: null,
      approvedAt: null,
      expiresAt: null,
      scopeHash: null,
      revokedBy: 'owner-1',
    },
  };
  assert.equal(isNovaActionApprovalValid(revoked, 'owner-1', 1000), false);
  assert.equal(canNovaWorkerExecute(revoked, 'owner-1', 1000), false);
});

test('explicit owner approval can also gate a normally safe task', () => {
  const task = taskWithApproval({type: 'research'});
  assert.equal(canNovaWorkerExecute(task, 'owner-1', 1000), true);
});
