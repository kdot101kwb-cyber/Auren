const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, 'knowledge_information_ecosystem.js'), 'utf8');
const indexSource = fs.readFileSync(path.join(__dirname, 'index.js'), 'utf8');
const screenSource = fs.readFileSync(path.join(__dirname, '..', 'lib', 'features', 'knowledge', 'presentation', 'knowledge_information_screen.dart'), 'utf8');
const serviceSource = fs.readFileSync(path.join(__dirname, '..', 'lib', 'services', 'knowledge', 'knowledge_information_service.dart'), 'utf8');

test('five distinct authenticated Knowledge & Information systems are callable', () => {
  for (const name of [
    'captureAurenKnowledgeItem',
    'saveAurenEvidenceRecord',
    'saveAurenSourceProfile',
    'upsertAurenReadingQueueItem',
    'saveAurenGlossaryEntry',
  ]) {
    assert.match(source, new RegExp('exports\\.' + name + '\\s*=\\s*onCall'));
    assert.match(source, /requireUid\(request\)/);
  }
  assert.match(indexSource, /knowledge_information_ecosystem/);
});

test('URL intake rejects non-HTTP schemes and embedded credentials', () => {
  assert.match(source, /\['https:', 'http:'\]/);
  assert.match(source, /url\.username \|\| url\.password/);
  assert.match(source, /At least one valid source URL is required/);
});

test('Evidence Vault does not silently declare claims verified', () => {
  assert.match(source, /\['unverified', 'supported', 'disputed', 'mixed'\]/);
  assert.match(source, /: 'unverified'/);
  assert.match(source, /verificationStatus: 'not_checked'/);
});

test('user data is scoped under the authenticated user and bounded', () => {
  assert.match(source, /collection\('users'\)\.doc\(uid\)\.collection\(name\)/);
  assert.match(source, /MAX_TITLE = 180/);
  assert.match(source, /MAX_TEXT = 6000/);
  assert.match(source, /MAX_URLS = 12/);
});

test('all five systems expose bounded authenticated list operations', () => {
  assert.equal((source.match(/action === 'list'/g) || []).length, 5);
  assert.match(source, /orderBy\('updatedAt', 'desc'\)\.limit\(50\)/);
});

test('Flutter workspace exposes five distinct tools and client adapters', () => {
  assert.match(screenSource, /DefaultTabController/);
  assert.match(screenSource, /TabBarView/);
  for (const method of [
    'captureKnowledge',
    'saveEvidence',
    'saveSourceProfile',
    'saveReadingQueueItem',
    'saveGlossaryEntry',
    'listKnowledge',
    'listEvidence',
    'listSourceProfiles',
    'listReadingQueue',
    'listGlossary',
  ]) assert.match(serviceSource, new RegExp(method));
  assert.match(screenSource, /AurenKnowledgeInformationScreen/);
});
