'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeWorkflowSteps, buildWorkflowSequence} = require('./nova_autonomous_workflow');

test('accepts a bounded sequence of safe text-only follow-up steps', () => {
  const steps = normalizeWorkflowSteps([
    {type:'research', prompt:'Verify the facts'},
    {type:'content_draft', prompt:'Prepare a concise report'},
  ]);
  assert.deepEqual(steps, [
    {type:'research', prompt:'Verify the facts'},
    {type:'content_draft', prompt:'Prepare a concise report'},
  ]);
  assert.equal(buildWorkflowSequence({type:'plan', prompt:'Create a plan', workflowSteps:steps}).length, 3);
});

test('rejects external side effects and provider-paid actions in autonomous steps', () => {
  for (const type of ['social_publish', 'video_generation', 'image_generation', 'purchase', 'github_ci_check']) {
    assert.throws(() => normalizeWorkflowSteps([{type, prompt:'Do it'}]));
  }
});

test('rejects empty, oversized, and excessive workflow steps', () => {
  assert.throws(() => normalizeWorkflowSteps([{type:'research', prompt:'  '}]));
  assert.throws(() => normalizeWorkflowSteps([{type:'research', prompt:'x'.repeat(3001)}]));
  assert.throws(() => normalizeWorkflowSteps(Array.from({length:5}, () => ({type:'plan', prompt:'step'}))));
});
