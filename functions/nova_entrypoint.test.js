'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const deployedFunctions = require('./nova_entrypoint');

test('Firebase deployment entrypoint exports NOVA revenue callables and daily scheduler', () => {
  assert.equal(typeof deployedFunctions.configureNovaRevenueEngine, 'function');
  assert.equal(typeof deployedFunctions.getNovaRevenueDashboard, 'function');
  assert.equal(typeof deployedFunctions.runNovaRevenueEngineDaily, 'function');
  assert.equal(typeof deployedFunctions.getNovaSignalOpportunities, 'function');
});

test('Firebase deployment entrypoint exports NOVA task and push notification functions', () => {
  for (const name of [
    'submitNovaTask',
    'getNovaTask',
    'approveNovaTask',
    'cancelNovaTask',
    'listNovaTasks',
    'registerNovaDeviceToken',
    'unregisterNovaDeviceToken',
    'notifyNovaTaskMilestone',
  ]) {
    assert.equal(typeof deployedFunctions[name], 'function', name + ' must be exported');
  }
});
