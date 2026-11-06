'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  MAX_DEPENDENCIES,
  normalizeDependencyIds,
  resolveDependencyState,
} = require('./nova_task_dependency_policy');

test('normalizes a bounded unique list of valid dependency IDs', () => {
  assert.deepEqual(normalizeDependencyIds(['nova_task_123456', 'task_1234567890']), [
    'nova_task_123456',
    'task_1234567890',
  ]);
  assert.deepEqual(normalizeDependencyIds(undefined), []);
});

test('rejects malformed, duplicate, excessive, and self dependencies', () => {
  assert.throws(() => normalizeDependencyIds('nova_task_123456'), /array/);
  assert.throws(() => normalizeDependencyIds(['bad']), /valid NOVA task ID/);
  assert.throws(() => normalizeDependencyIds(['nova_task_123456', 'nova_task_123456']), /Duplicate/);
  assert.throws(() => normalizeDependencyIds(Array.from({length: MAX_DEPENDENCIES + 1}, (_, i) => 'task_' + String(i).padStart(12, '0'))), /at most/);
  assert.throws(() => normalizeDependencyIds(['nova_task_123456'], 'nova_task_123456'), /itself/);
});

test('waits until every prerequisite succeeds', () => {
  assert.deepEqual(resolveDependencyState(['queued', 'succeeded']), {
    status: 'waiting_for_dependencies',
    error: null,
  });
  assert.deepEqual(resolveDependencyState(['succeeded', 'completed']), {
    status: 'queued',
    error: null,
  });
});

test('keeps approval-gated tasks out of the execution queue', () => {
  assert.deepEqual(resolveDependencyState(['succeeded'], true), {
    status: 'awaiting_approval',
    error: null,
  });
});

test('blocks a dependent task when any prerequisite fails or is cancelled', () => {
  for (const status of ['failed', 'cancelled', 'blocked']) {
    assert.equal(resolveDependencyState(['succeeded', status]).status, 'blocked');
  }
});

test('queues ordinary tasks immediately when no dependencies are supplied', () => {
  assert.deepEqual(resolveDependencyState([], false), {status:'queued', error:null});
  assert.deepEqual(resolveDependencyState([], true), {status:'awaiting_approval', error:null});
});
