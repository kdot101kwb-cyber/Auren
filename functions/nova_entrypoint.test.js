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
