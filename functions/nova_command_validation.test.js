'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeNovaTaskInput} = require('./nova_command_validation');

function input(overrides = {}) {
  return {
    type:'plan',
    prompt:'Create a safe execution plan',
    idempotencyKey:'nova_workflow_001',
    metadata:{source:'nova_android', locale:'ar'},
    ...overrides,
  };
}

test('normalizes safe workflow steps into task metadata', () => {
  const result = normalizeNovaTaskInput(input({
    metadata:{workflowSteps:[{type:'research', prompt:'Check the evidence'}]},
  }));
  assert.deepEqual(result.metadata.workflowSteps, [
    {type:'research', prompt:'Check the evidence'},
  ]);
});

test('rejects unsafe workflow steps at task submission validation', () => {
  assert.throws(() => normalizeNovaTaskInput(input({
    metadata:{workflowSteps:[{type:'social_publish', prompt:'Publish this'}]},
  })));
});
