'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeReplicateOutput,
  submitHuggingFaceChat,
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
