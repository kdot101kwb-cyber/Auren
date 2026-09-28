'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  listAurenEntertainmentProviders,
  chooseAurenEntertainmentProvider,
  buildAurenProviderAttemptOrder,
  getAurenEntertainmentProvider,
} = require('./entertainment_providers');

test('provider registry exposes free-limited and paid video paths without pretending they are unlimited free', () => {
  const video = listAurenEntertainmentProviders('video');
  assert.ok(video.some((p) => p.id === 'local_open_source' && p.freeTier === true));
  assert.ok(video.some((p) => p.id === 'gemini_veo' && p.freeTier === false));
});

test('provider selection prefers a configured free-tier provider when healthy', () => {
  const selected = chooseAurenEntertainmentProvider({
    capability: 'video',
    configured: ['gemini_veo', 'local_open_source'],
    health: {local_open_source: {available: true}, gemini_veo: {available: true}},
    preferFree: true,
  });
  assert.equal(selected.id, 'local_open_source');
});

test('provider selection falls back when the first provider is unhealthy', () => {
  const selected = chooseAurenEntertainmentProvider({
    capability: 'video',
    configured: ['local_open_source', 'gemini_veo'],
    health: {local_open_source: {available: false}, gemini_veo: {available: true}},
    preferFree: true,
  });
  assert.equal(selected.id, 'gemini_veo');
});

test('attempt order is deterministic and excludes disabled/unhealthy providers', () => {
  const order = buildAurenProviderAttemptOrder({
    capability: 'video',
    configured: ['gemini_veo', 'local_open_source', 'auren_external'],
    disabled: ['auren_external'],
    health: {local_open_source: {available: true}, gemini_veo: {available: true}},
  });
  assert.deepEqual(order, ['local_open_source', 'gemini_veo']);
});

test('provider lookup is strict', () => {
  assert.equal(getAurenEntertainmentProvider('gemini_veo').id, 'gemini_veo');
  assert.equal(getAurenEntertainmentProvider('does_not_exist'), null);
});
