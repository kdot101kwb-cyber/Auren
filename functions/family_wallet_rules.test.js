'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const rules = fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8');

test('family wallet documents are owner-scoped and use a fixed wallet id', () => {
  assert.match(rules, /match\s*\/users\/{userId}\/familyWallet\/{walletId}\s*\{[\s\S]*?allow read:\s*if isOwner\(userId\)/);
  assert.match(rules, /walletId\s*==\s*'current'/);
  assert.match(rules, /requestData\(\)\.ownerUid\s*==\s*userId/);
});

test('family wallet ledger accepts only positive income or expense entries and is append-only', () => {
  assert.match(rules, /match\s*\/entries\/{entryId}\s*\{[\s\S]*?requestData\(\)\.kind\s+in\s*\['income','expense'\]/);
  assert.match(rules, /allow update, delete:\s*if false/);
  assert.match(rules, /intWithin\(requestData\(\)\.amountMinor,1,1000000000000\)/);
});

test('family savings goals cannot rewrite their target or owner when progress changes', () => {
  assert.match(rules, /match\s*\/goals\/{goalId}\s*\{[\s\S]*?changedFields\(\)\.hasOnly\(\['savedMinor','updatedAt'\]\)/);
  assert.match(rules, /requestData\(\)\.targetMinor\s*==\s*resource\.data\.targetMinor/);
  assert.match(rules, /requestData\(\)\.ownerUid\s*==\s*resource\.data\.ownerUid/);
});

test('family monthly budgets validate month, currency, positive limit, and limited updates', () => {
  assert.match(rules, /match\s*\/budgets\/{budgetId}\s*\{[\s\S]*?requestData\(\)\.periodKey\.matches\('\^\[0-9\]\{4\}-\(0\[1-9\]\|1\[0-2\]\)\$'\)/);
  assert.match(rules, /changedFields\(\)\.hasOnly\(\['limitMinor','updatedAt'\]\)/);
  assert.match(rules, /intWithin\(requestData\(\)\.limitMinor,1,1000000000000\)/);
});
