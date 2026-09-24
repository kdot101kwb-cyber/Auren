import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const source = fs.readFileSync(new URL('./index.js', import.meta.url), 'utf8');

test('action lifecycle endpoints are present', () => {
  assert.match(source, /exports\.decideAurenAction\s*=\s*require\('firebase-functions\/v2\/https'\)/);
  assert.match(source, /exports\.executeAurenAction\s*=\s*require\('firebase-functions\/v2\/https'\)/);
  assert.match(source, /exports\.recoverAurenAction\s*=\s*require\('firebase-functions\/v2\/https'\)/);
});

test('approval is restricted to pending low-risk userApproval actions', () => {
  assert.match(source, /action\.status !== 'pending'/);
  assert.match(source, /action\.permission !== 'userApproval'/);
  assert.match(source, /action\.riskLevel !== 'low'/);
  assert.match(source, /action\.approvalLevel !== 1/);
  assert.match(source, /action\.requiresApproval !== true/);
});

test('execution is restricted to approved or safely recovering actions', () => {
  assert.match(source, /!\['approved', 'executing'\]\.includes\(action\.status\)/);
  assert.match(source, /Action is no longer approved for execution/);
});

test('deterministic side-effect identifiers prevent duplicate note and memory records', () => {
  assert.match(source, /collection\('notes'\)\.doc\(actionId\)/);
  assert.match(source, /collection\('memory'\)\.doc\('mem_' \+ actionId\)/);
});

test('recovery requires a stale execution window and verifies deterministic side effects', () => {
  assert.match(source, /2 \* 60 \* 1000/);
  assert.match(source, /No deterministic note side effect found/);
  assert.match(source, /No deterministic memory side effect found/);
  assert.match(source, /Action cannot be safely recovered/);
});

test('execution claim must stop retries before side effects', () => {
  assert.match(source, /const claimed = await db\.runTransaction/);
  assert.match(source, /if \(!claimed\)/);
  assert.match(source, /Action is already executing/);
  assert.match(source, /deduplicated: true/);
});


test('approval, execution and recovery remain explicit server endpoints', () => {
  assert.match(source, /exports\.decideAurenAction/);
  assert.match(source, /exports\.executeAurenAction/);
  assert.match(source, /exports\.recoverAurenAction/);
  assert.match(source, /action\.status !== 'pending'/);
  assert.match(source, /!\['approved', 'executing'\]\.includes\(action\.status\)/);
});

test('permission ledger enforces disabled state and daily spending limits', () => {
  assert.match(source, /AUREN agent permissions are disabled/);
  assert.match(source, /Daily AUREN spending limit exceeded/);
  assert.match(source, /Action is not granted by the permission ledger/);
});


test('spending reservation is atomic and day-scoped', () => {
  assert.match(source, /const requestedAmount =/);
  assert.match(source, /ledgerData.dailySpendingLimitMinor/);
  assert.match(source, /ledgerData.spendingDay/);
  assert.match(source, /spentToday + requestedAmount/);
  assert.match(source, /spentTodayMinor: spentToday + requestedAmount/);
  assert.match(source, /spendingDay: today/);
});

test('failed execution refunds only the current-day reservation', () => {
  assert.match(source, /if (ledgerData.spendingDay !== today) return/);
  assert.match(source, /spentTodayMinor: Math.max(0, spentToday - requestedAmount)/);
});


test('permission ledger parsing filters malformed actions and currency', () => {
  assert.match(source, /\.filter\(\(action\) => typeof action === 'string'\)/);
  assert.match(source, /\.map\(\(action\) => action\.trim\(\)\)/);
  assert.match(source, /\.slice\(0, 100\)/);
  assert.match(source, /\/\^\[A-Z\]\{3\}\$\/\.test\(data\.currency\)/);
});


test('action rules include execution metadata and keep action updates server-only', () => {
  const rules = fs.readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');
  assert.match(rules, /'executionStartedAt', 'executionSpendingDay'/);
  assert.match(rules, /match \/actions\/\\{actionId\\}/);
  assert.match(rules, /allow update: if false;/);
});


test('AI gateway finalizes missing-key and provider-failure idempotency states', () => {
  const source = fs.readFileSync(new URL('./index.js', import.meta.url), 'utf8');
  assert.match(source, /status: 'completed',[\s\S]*response: unavailable/);
  assert.match(source, /status: 'failed',[\s\S]*failedAt: FieldValue\.serverTimestamp\(\)/);
});


test('AI gateway marks empty provider content as failed', () => {
  const source = fs.readFileSync(new URL('./index.js', import.meta.url), 'utf8');
  assert.match(source, /errorCode: 'empty_provider_response'/);
});
