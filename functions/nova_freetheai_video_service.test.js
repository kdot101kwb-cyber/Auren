'use strict';
const {initializeApp} = require('firebase-admin/app');
try { initializeApp({projectId: 'auren-nova-freetheai-test'}); } catch (_) {}
const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeNovaFreeTheAIVideoInput, novaFreeTheAIVideoSafeStatus} = require('./nova_freetheai_video_service');

test('accepts a valid FreeTheAI video request with explicit free-tier acknowledgement', () => {
  assert.deepEqual(normalizeNovaFreeTheAIVideoInput({
    prompt: 'A cinematic technology explainer with glowing blue circuits',
    idempotencyKey: 'nova_free_video_1234',
    model: 'video-model-test',
    seconds: 5,
    size: '720p',
    confirmFreeTierUsage: true,
  }), {
    prompt: 'A cinematic technology explainer with glowing blue circuits',
    idempotencyKey: 'nova_free_video_1234',
    model: 'video-model-test',
    seconds: 5,
    size: '720p',
  });
});

test('requires explicit acknowledgement of free-tier limits', () => {
  assert.throws(() => normalizeNovaFreeTheAIVideoInput({
    prompt: 'A cinematic technology explainer',
    idempotencyKey: 'nova_free_video_1234',
    model: 'video-model-test',
  }), /Confirm that you understand/);
});

test('rejects malformed prompts, IDs, models, durations and sizes', () => {
  const base = {prompt: 'A cinematic technology explainer', idempotencyKey: 'nova_free_video_1234', model: 'video-model-test', confirmFreeTierUsage: true};
  assert.throws(() => normalizeNovaFreeTheAIVideoInput({...base, prompt: 'tiny'}), /Prompt/);
  assert.throws(() => normalizeNovaFreeTheAIVideoInput({...base, idempotencyKey: 'short'}), /idempotencyKey/);
  assert.throws(() => normalizeNovaFreeTheAIVideoInput({...base, model: ''}), /video model/);
  assert.throws(() => normalizeNovaFreeTheAIVideoInput({...base, seconds: 60}), /duration/);
  assert.throws(() => normalizeNovaFreeTheAIVideoInput({...base, size: 'free'}), /size/);
});

test('normalizes provider statuses safely', () => {
  assert.equal(novaFreeTheAIVideoSafeStatus('completed'), 'completed');
  assert.equal(novaFreeTheAIVideoSafeStatus('running'), 'running');
  assert.equal(novaFreeTheAIVideoSafeStatus('arbitrary-value'), 'queued');
});
