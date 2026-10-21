'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const rules = fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8');
const service = fs.readFileSync(path.join(__dirname, '..', 'lib/services/social/community_casework_service.dart'), 'utf8');

test('community reports can only be created by an authenticated reporter with bounded fields', () => {
  const start = rules.indexOf('match /reports/{reportId}');
  const end = rules.indexOf('match /users/{userId}/notifications', start);
  assert.ok(start >= 0 && end > start, 'reports rule must exist and have a following rule');
  const block = rules.slice(start, end);
  assert.match(block, /allow create:\s*if isSignedIn\(\)/);
  assert.match(block, /requestData\(\)\.reporterUid==request\.auth\.uid/);
  assert.match(block, /requestData\(\)\.status=='open'/);
  assert.match(block, /keys\(\)\.hasOnly\(\[/);
  assert.doesNotMatch(block, /allow update|allow delete/);
});

test('casework service validates moderator decisions and requires a signed-in user', () => {
  assert.match(service, /auth\.currentUser\?\.uid/);
  assert.match(service, /under_review.*resolved.*rejected/);
  assert.match(service, /Report not found/);
  assert.match(service, /Report is not reviewable/);
  assert.match(service, /n\.isEmpty/);
});

test('governance write paths remain explicitly unshipped until rules are implemented', () => {
  assert.doesNotMatch(rules, /match \/community_case_events\//);
  assert.match(service, /collection\('community_case_events'\)/);
});
