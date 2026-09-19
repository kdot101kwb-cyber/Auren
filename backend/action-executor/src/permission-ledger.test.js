import test from 'node:test';
import assert from 'node:assert/strict';
import { assertPermission, assertSpendingLimit } from './permission-ledger.js';

const action = (amountMinor, limit = null) => ({
  actionType: 'demo.echo',
  payload: { text: 'test', amountMinor },
  spendingLimitMinor: limit,
});

test('allows spending when within the daily limit', () => {
  const ledger = {
    enabled: true,
    allowedActions: new Set(),
    dailySpendingLimitMinor: 1000,
    spentTodayMinor: 400,
  };
  assertPermission(ledger, action(500));
  assert.doesNotThrow(() => assertSpendingLimit(ledger, action(500)));
});

test('rejects spending that would exceed the daily limit', () => {
  const ledger = {
    enabled: true,
    allowedActions: new Set(),
    dailySpendingLimitMinor: 1000,
    spentTodayMinor: 600,
  };
  assert.throws(
    () => assertSpendingLimit(ledger, action(401)),
    /Daily AUREN spending limit exceeded/,
  );
});

test('rejects spending above the action approval limit', () => {
  const ledger = {
    enabled: true,
    allowedActions: new Set(),
    dailySpendingLimitMinor: null,
    spentTodayMinor: 0,
  };
  assert.throws(
    () => assertSpendingLimit(ledger, action(501, 500)),
    /approved spending limit/,
  );
});

test('rejects negative or unsafe spending amounts', () => {
  const ledger = {
    enabled: true,
    allowedActions: new Set(),
    dailySpendingLimitMinor: null,
    spentTodayMinor: 0,
  };
  assert.throws(() => assertSpendingLimit(ledger, action(-1)), /Invalid spending amount/);
  assert.throws(
    () => assertSpendingLimit(ledger, action(Number.MAX_SAFE_INTEGER + 1)),
    /Invalid spending amount/,
  );
});

test('enforces explicitly granted actions', () => {
  const ledger = {
    enabled: true,
    allowedActions: new Set(['demo.create_note']),
    dailySpendingLimitMinor: null,
    spentTodayMinor: 0,
  };
  assert.throws(
    () => assertPermission(ledger, action(0)),
    /not granted by the permission ledger/,
  );
});
