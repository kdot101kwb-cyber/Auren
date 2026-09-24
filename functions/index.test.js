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
