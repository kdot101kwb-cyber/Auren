'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeVideoInput} = require('./nova_higgsfield_service');

test('normalizes a confirmed video generation request', () => {
  assert.deepEqual(normalizeVideoInput({prompt:'A cinematic AI technology explainer',duration:10,idempotencyKey:'nova_video_123456',confirmPaidGeneration:true}), {
    prompt:'A cinematic AI technology explainer',duration:10,idempotencyKey:'nova_video_123456',
  });
});

test('requires explicit confirmation before any potentially paid generation', () => {
  assert.throws(() => normalizeVideoInput({prompt:'A cinematic video prompt',idempotencyKey:'nova_video_123456'}), /Explicit confirmation/);
});

test('rejects invalid durations and idempotency keys', () => {
  assert.throws(() => normalizeVideoInput({prompt:'A cinematic video prompt',duration:5,idempotencyKey:'nova_video_123456',confirmPaidGeneration:true}), /Duration/);
  assert.throws(() => normalizeVideoInput({prompt:'A cinematic video prompt',duration:6,idempotencyKey:'short',confirmPaidGeneration:true}), /idempotencyKey/);
});

test('rejects empty and oversized prompts', () => {
  assert.throws(() => normalizeVideoInput({prompt:'tiny',duration:6,idempotencyKey:'nova_video_123456',confirmPaidGeneration:true}), /Prompt/);
  assert.throws(() => normalizeVideoInput({prompt:'x'.repeat(1801),duration:6,idempotencyKey:'nova_video_123456',confirmPaidGeneration:true}), /Prompt/);
});
