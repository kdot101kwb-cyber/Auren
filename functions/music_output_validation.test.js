'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {isMaterializedMusicOutput, validateMaterializedMusicOutput} = require('./music_output_validation');

test('recognizes structurally valid output references', () => {
  assert.equal(isMaterializedMusicOutput({storagePath: 'music/track.mp3'}), true);
  assert.equal(isMaterializedMusicOutput({url: 'https://cdn.example.test/track.mp3'}), true);
  assert.equal(isMaterializedMusicOutput({externalId: 'prediction-123'}), false);
  assert.equal(isMaterializedMusicOutput({url: 'http://cdn.example.test/track.mp3'}), false);
  assert.equal(isMaterializedMusicOutput({url: 'not a URL'}), false);
  for (const value of [null, undefined, [], 'track.mp3', 7, {}]) {
    assert.equal(isMaterializedMusicOutput(value), false);
  }
});

test('requires Storage object to exist and have an audio-compatible content type', async () => {
  const missing = await validateMaterializedMusicOutput({storagePath: 'music/missing.mp3'}, {
    getStorageFile: () => ({exists: async () => [false]}),
  });
  assert.deepEqual(missing, {ok: false, reason: 'storage_object_missing'});

  const notAudio = await validateMaterializedMusicOutput({storagePath: 'music/document.txt'}, {
    getStorageFile: () => ({
      exists: async () => [true],
      getMetadata: async () => [{contentType: 'text/plain'}],
    }),
  });
  assert.deepEqual(notAudio, {ok: false, reason: 'not_audio', contentType: 'text/plain'});

  const valid = await validateMaterializedMusicOutput({storagePath: 'music/track.mp3'}, {
    getStorageFile: () => ({
      exists: async () => [true],
      getMetadata: async () => [{contentType: 'audio/mpeg'}],
    }),
  });
  assert.deepEqual(valid, {ok: true, storagePath: 'music/track.mp3', contentType: 'audio/mpeg'});
});

test('validates HTTPS URL response and audio content type', async () => {
  const valid = await validateMaterializedMusicOutput({url: 'https://cdn.example.test/track.mp3'}, {
    fetchImpl: async () => ({ok: true, status: 200, headers: {get: () => 'audio/mpeg'}}),
  });
  assert.deepEqual(valid, {ok: true, contentType: 'audio/mpeg'});

  const html = await validateMaterializedMusicOutput({url: 'https://cdn.example.test/track'}, {
    fetchImpl: async () => ({ok: true, status: 200, headers: {get: () => 'text/html'}}),
  });
  assert.deepEqual(html, {ok: false, reason: 'not_audio', contentType: 'text/html'});
});

test('rejects external IDs without a materialized artifact', async () => {
  assert.deepEqual(
    await validateMaterializedMusicOutput({externalId: 'prediction-123'}),
    {ok: false, reason: 'artifact_not_materialized'},
  );
});
