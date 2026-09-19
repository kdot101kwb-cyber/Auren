import test from 'node:test';
import assert from 'node:assert/strict';
import { calculateRisk } from '../src/risk-engine.js';

test('missing trust score is treated as neutral instead of restricted', () => {
  assert.equal(calculateRisk({disputes:0,failures:0}), 'normal');
});

test('risk escalates from concrete adverse metrics', () => {
  assert.equal(calculateRisk({score:95,disputes:1,failures:0}), 'watch');
  assert.equal(calculateRisk({score:80,disputes:3,failures:0}), 'restricted');
  assert.equal(calculateRisk({score:60,disputes:0,failures:5}), 'suspended');
});

test('negative or non-finite trust metrics are rejected', () => {
  assert.throws(() => calculateRisk({score:100,disputes:-1}), /Invalid trust metrics/);
  assert.throws(() => calculateRisk({score:Infinity}), /Invalid trust metrics/);
});
