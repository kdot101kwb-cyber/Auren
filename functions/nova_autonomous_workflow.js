'use strict';

const SAFE_WORKFLOW_TYPES = new Set(['chat', 'plan', 'research', 'content_draft', 'social_content_draft']);

function normalizeWorkflowSteps(value, ErrorType = Error) {
  const fail = (message) => { throw ErrorType === Error ? new Error(message) : new ErrorType('invalid-argument', message); };
  if (value == null) return [];
  if (!Array.isArray(value) || value.length > 4) fail('A workflow may contain at most four follow-up steps.');
  return value.map((step, index) => {
    if (!step || typeof step !== 'object' || Array.isArray(step)) fail('Invalid workflow step at position ' + (index + 1) + '.');
    const type = String(step.type || '').trim();
    const prompt = String(step.prompt || '').trim();
    if (!SAFE_WORKFLOW_TYPES.has(type)) fail('Workflow step ' + (index + 1) + ' uses a type that is not safe for autonomous execution.');
    if (!prompt || prompt.length > 3000) fail('Workflow step ' + (index + 1) + ' must contain 1–3000 characters.');
    return {type, prompt};
  });
}

function buildWorkflowSequence(task) {
  const first = {type:String(task?.type || ''), prompt:String(task?.prompt || '')};
  return [first, ...(Array.isArray(task?.workflowSteps) ? task.workflowSteps : [])];
}

module.exports = {SAFE_WORKFLOW_TYPES, normalizeWorkflowSteps, buildWorkflowSequence};
