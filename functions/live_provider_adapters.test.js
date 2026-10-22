'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeReplicateOutput,
  submitHuggingFaceChat,
  submitReplicate,
} = require('./live_provider_adapters');

test('normalizes a Replicate URL output', () => {
  assert.deepEqual(normalizeReplicateOutput({output:'https://example.com/video.mp4'}), {
    url:'https://example.com/video.mp4',
  });
});

test('normalizes the first string from a Replicate array output', () => {
  assert.deepEqual(normalizeReplicateOutput({output:['https://example.com/a.mp4','https://example.com/b.mp4']}), {
    url:'https://example.com/a.mp4',
  });
});

test('rejects missing Hugging Face credentials before network access', async () => {
  await assert.rejects(
    () => submitHuggingFaceChat({token:'', messages:[]}),
    /HF_TOKEN is not configured/,
  );
});

test('Replicate submission exposes the normalized direct payload used by workers', async () => {
  const originalFetch = global.fetch;
  global.fetch = async (url, options) => ({
    ok: true,
    status: 201,
    text: async () => JSON.stringify({id: 'prediction-123', status: 'starting', output: null}),
  });
  try {
    const result = await submitReplicate({
      token: 'test-token',
      version: 'test-version',
      input: {prompt: 'test'},
      idempotencyKey: 'music-task-1',
    });
    assert.equal(result.ok, true);
    assert.equal(result.providerId, 'replicate');
    assert.equal(result.state, 'starting');
    assert.equal(result.externalJobId, 'prediction-123');
    assert.equal(result.output, null);
    assert.equal(result.result, undefined);
  } finally {
    global.fetch = originalFetch;
  }
});
