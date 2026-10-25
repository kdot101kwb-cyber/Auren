'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {__testables} = require('./nova_task_worker');

test('only safe text tasks are eligible for automatic execution', () => {
  assert.equal(__testables.SAFE_TEXT_TYPES.has('chat'), true);
  assert.equal(__testables.SAFE_TEXT_TYPES.has('plan'), true);
  assert.equal(__testables.SAFE_TEXT_TYPES.has('research'), true);
  assert.equal(__testables.SAFE_TEXT_TYPES.has('content_draft'), true);
  assert.equal(__testables.SAFE_TEXT_TYPES.has('social_publish'), false);
  assert.equal(__testables.SAFE_TEXT_TYPES.has('image_generation'), false);
  assert.equal(__testables.SAFE_TEXT_TYPES.has('video_generation'), false);
});
