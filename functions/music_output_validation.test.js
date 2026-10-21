'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {isMaterializedMusicOutput} = require('./music_output_validation');

test('accepts an existing Storage path as a materialized output reference', () => {
  assert.equal(isMaterializedMusicOutput({storagePath: 'music/track.mp3'}), true);
});

test('accepts HTTPS output URLs', () => {
  assert.equal(isMaterializedMusicOutput({url: 'https://cdn.example.test/track.mp3'}), true);
});

test('rejects provider IDs without a playable artifact reference', () => {
  assert.equal(isMaterializedMusicOutput({externalId: 'prediction-123'}), false);
});

test('rejects non-HTTPS and malformed URLs', () => {
  assert.equal(isMaterializedMusicOutput({url: 'http://cdn.example.test/track.mp3'}), false);
  assert.equal(isMaterializedMusicOutput({url: 'not a URL'}), false);
});

test('rejects empty, null, array, and primitive output values', () => {
  for (const value of [null, undefined, [], 'track.mp3', 7, {}]) {
    assert.equal(isMaterializedMusicOutput(value), false);
  }
});
