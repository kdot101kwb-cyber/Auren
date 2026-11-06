'use strict';

const {payloadHash, constantTimeEqual} = require('./action_security');

/**
 * Canonical, versioned contract shared by NOVA task submitters and workers.
 * This module is intentionally dependency-free so it can be tested with Node.
 */
const TASK_SCHEMA_VERSION = 1;
const TASK_STATUSES = Object.freeze([
  'awaiting_approval', 'queued', 'running', 'verifying',
  'provider_processing', 'succeeded', 'failed', 'blocked', 'cancelled',
]);

const TERMINAL_STATUSES = new Set(['succeeded', 'failed', 'blocked', 'cancelled']);
const TRANSITIONS = Object.freeze({
  awaiting_approval: new Set(['queued', 'cancelled', 'blocked']),
  queued: new Set(['running', 'cancelled', 'blocked', 'failed']),
  running: new Set(['verifying', 'provider_processing', 'succeeded', 'queued', 'failed', 'blocked', 'cancelled']),
  verifying: new Set(['succeeded', 'queued', 'failed', 'blocked', 'cancelled']),
  provider_processing: new Set(['succeeded', 'failed', 'blocked', 'cancelled']),
  succeeded: new Set(),
  failed: new Set(['queued']),
  blocked: new Set(),
  cancelled: new Set(),
});

const DEFAULT_MAX_ATTEMPTS = 3;
const MAX_EVIDENCE_ITEMS = 20;

function canTransitionTask(from, to) {
  return TASK_STATUSES.includes(from) && TRANSITIONS[from].has(to);
}

function createNovaTaskRecord({taskId, ownerUid, input}) {
  if (!taskId || !ownerUid || !input || !input.type || !input.prompt) {
    throw new TypeError('taskId, ownerUid, and a valid task input are required.');
  }
  const status = input.requiresApproval ? 'awaiting_approval' : 'queued';
  return {
    schemaVersion: TASK_SCHEMA_VERSION,
    taskId,
    ownerUid,
    idempotencyKey: taskId,
    type: input.type,
    prompt: input.prompt,
    metadata: input.metadata || {},
    status,
    executionMode: 'queued_backend_worker_required',
    requiresApproval: input.requiresApproval === true,
    approval: {
      required: input.requiresApproval === true,
      approvedBy: null,
      approvedAt: null,
      scopeHash: null,
    },
    result: null,
    error: null,
    provider: null,
    evidence: [],
    checkpoint: null,
    retryCount: 0,
    maxAttempts: DEFAULT_MAX_ATTEMPTS,
    estimatedCostUsd: 0,
    actualCostUsd: 0,
  };
}


/**
 * Hash only immutable, execution-relevant fields. Mutable lifecycle/result fields
 * are deliberately excluded so the worker can re-check the exact approved action.
 */
function taskApprovalScope(task) {
  if (!task || typeof task !== 'object') {
    throw new TypeError('A NOVA task is required to calculate its approval scope.');
  }
  return {
    schemaVersion: task.schemaVersion || TASK_SCHEMA_VERSION,
    taskId: String(task.taskId || ''),
    ownerUid: String(task.ownerUid || ''),
    type: String(task.type || ''),
    prompt: String(task.prompt || ''),
    metadata: task.metadata && typeof task.metadata === 'object' ? task.metadata : {},
    executionMode: String(task.executionMode || ''),
    requiresApproval: task.requiresApproval === true,
    estimatedCostUsd: Number(task.estimatedCostUsd || 0),
    maxAttempts: Number(task.maxAttempts || DEFAULT_MAX_ATTEMPTS),
  };
}

function createTaskApprovalScopeHash(task) {
  return payloadHash(taskApprovalScope(task));
}

function matchesTaskApprovalScope(task, candidateHash) {
  if (typeof candidateHash !== 'string' || !/^[a-f0-9]{64}$/i.test(candidateHash)) {
    return false;
  }
  try {
    return constantTimeEqual(createTaskApprovalScopeHash(task), candidateHash.toLowerCase());
  } catch (_) {
    return false;
  }
}

function createNovaQueueRecord({taskId, ownerUid, status = 'queued'}) {
  if (!taskId || !ownerUid || !TASK_STATUSES.includes(status)) {
    throw new TypeError('taskId, ownerUid, and a valid task status are required.');
  }
  return {
    schemaVersion: TASK_SCHEMA_VERSION,
    ownerUid,
    taskId,
    status,
    attempts: 0,
    maxAttempts: DEFAULT_MAX_ATTEMPTS,
    claimedAt: null,
    leaseExpiresAt: null,
  };
}

function createNovaAuditEvent({action, actorUid, taskId, taskType, details = {}}) {
  if (!action || !actorUid || !taskId) {
    throw new TypeError('action, actorUid, and taskId are required for a NOVA audit event.');
  }
  const safeDetails = {};
  for (const key of ['status', 'provider', 'model', 'attempt', 'errorCode', 'evidenceCount', 'scopeHash']) {
    if (details[key] !== undefined && details[key] !== null) {
      safeDetails[key] = typeof details[key] === 'string'
        ? details[key].slice(0, 300)
        : details[key];
    }
  }
  return {
    schemaVersion: TASK_SCHEMA_VERSION,
    action,
    actorUid,
    taskId,
    ...(taskType ? {taskType} : {}),
    ...safeDetails,
  };
}

function normalizeTaskEvidence(items) {
  if (!Array.isArray(items)) return [];
  return items.slice(0, MAX_EVIDENCE_ITEMS).filter((item) =>
    item && typeof item === 'object' &&
    typeof item.kind === 'string' && typeof item.uri === 'string' &&
    /^https:\/\//i.test(item.uri)
  ).map((item) => ({
    kind: item.kind.slice(0, 40),
    uri: item.uri.slice(0, 1000),
    ...(typeof item.label === 'string' ? {label: item.label.slice(0, 160)} : {}),
    ...(typeof item.sha256 === 'string' && /^[a-f0-9]{64}$/i.test(item.sha256)
      ? {sha256: item.sha256.toLowerCase()} : {}),
  }));
}

module.exports = {
  TASK_SCHEMA_VERSION,
  TASK_STATUSES,
  TERMINAL_STATUSES,
  DEFAULT_MAX_ATTEMPTS,
  canTransitionTask,
  createNovaTaskRecord,
  taskApprovalScope,
  createTaskApprovalScopeHash,
  matchesTaskApprovalScope,
  createNovaQueueRecord,
  createNovaAuditEvent,
  normalizeTaskEvidence,
};
