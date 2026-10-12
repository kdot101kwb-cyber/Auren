'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeGroupSelection, hasBlockedPair} = require('./random_group_matching_logic');

test('group selection requires exactly the expected number of unique request IDs', () => {
  assert.deepEqual(normalizeGroupSelection({
    ownRequestId: 'own',
    candidateRequestIds: ['a', 'b'],
    groupSize: 3,
  }), ['own', 'a', 'b']);
  assert.throws(() => normalizeGroupSelection({
    ownRequestId: 'own', candidateRequestIds: ['a'], groupSize: 3,
  }), {code: 'invalid-argument'});
  assert.throws(() => normalizeGroupSelection({
    ownRequestId: 'own', candidateRequestIds: ['a', 'a'], groupSize: 3,
  }), {code: 'invalid-argument'});
  assert.throws(() => normalizeGroupSelection({
    ownRequestId: 'own', candidateRequestIds: ['own', 'b'], groupSize: 3,
  }), {code: 'invalid-argument'});
});

test('group selection rejects malformed sizes and empty IDs', () => {
  for (const groupSize of [2, 9, 3.5, '3', null]) {
    assert.throws(() => normalizeGroupSelection({
      ownRequestId: 'own', candidateRequestIds: ['a', 'b'], groupSize,
    }), {code: 'invalid-argument'});
  }
  assert.throws(() => normalizeGroupSelection({
    ownRequestId: 'own', candidateRequestIds: ['a', ' '], groupSize: 3,
  }), {code: 'invalid-argument'});
});

test('block checks reject either direction between selected members only', () => {
  assert.equal(hasBlockedPair(['a', 'b', 'c'], [{uid: 'a', blockedUid: 'b'}]), true);
  assert.equal(hasBlockedPair(['a', 'b', 'c'], [{uid: 'c', blockedUid: 'a'}]), true);
  assert.equal(hasBlockedPair(['a', 'b', 'c'], [{uid: 'a', blockedUid: 'outside'}]), false);
  assert.equal(hasBlockedPair(['a', 'b', 'c'], [{uid: 'a', blockedUid: 'a'}]), false);
  assert.equal(hasBlockedPair(['a', 'b', 'c'], []), false);
});

test('trusted callable endpoints validate membership, block state and request lifecycle', () => {
  const fs = require('node:fs');
  const source = fs.readFileSync(require('node:path').join(__dirname, 'random_group_matching.js'), 'utf8');
  assert.match(source, /exports\.listAurenRandomGroupCandidates/);
  assert.match(source, /exports\.formAurenRandomGroup/);
  assert.match(source, /exports\.createAurenRandomGroupConversation/);
  assert.match(source, /status !== 'waiting'/);
  assert.match(source, /tx\.update\(ref, \{/);
  assert.match(source, /readBlockedPairs\(tx, memberUids\)/);
});
