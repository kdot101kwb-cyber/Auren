'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {buildProviderOrder, submitAurenProviderJob, submitWithFallback} = require('./provider_runtime');

test('provider order is deterministic and deduplicated', () => {
  assert.deepEqual(buildProviderOrder(['replicate','huggingface','replicate']), ['replicate','huggingface']);
});

test('unknown providers fail closed', async () => {
  const r = await submitAurenProviderJob({
    provider:'not_registered',
    credentials:{},
    task:{},
    idempotencyKey:'job:task',
  });
  assert.equal(r.ok, false);
  assert.equal(r.unavailable, true);
});

test('fallback reaches the next provider after an unavailable first provider', async () => {
  const r = await submitWithFallback({
    candidates:['huggingface','not_registered'],
    credentialsByProvider:{huggingface:{token:''}},
    task:{messages:[]},
    idempotencyKey:'job:task',
  });
  assert.equal(r.ok, false);
  assert.equal(r.state, 'waiting_provider');
  assert.equal(r.attempts.length, 2);
  assert.equal(r.attempts[0].providerId, 'huggingface');
  assert.equal(r.attempts[1].providerId, 'not_registered');
});
