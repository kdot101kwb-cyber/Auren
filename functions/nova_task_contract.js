'use strict';

const crypto = require('node:crypto');

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


function stableApprovalValue(value) {
  if (Array.isArray(value)) return value.map(stableApprovalValue);
  if (value && typeof value === 'object') {
    return Object.keys(value).sort().reduce((result, key) => {
      result[key] = stableApprovalValue(value[key]);
      return result;
    }, {});
  }
  return value;
}

/**
 * Bind an owner approval to the exact immutable task intent. Any change to
 * identity, owner, type, prompt, metadata, or approval requirement invalidates it.
 */
function createNovaApprovalScopeHash(task) {
  if (!task || typeof task !== 'object' || !task.taskId || !task.ownerUid ||
      !task.type || typeof task.prompt !== 'string') {
    throw new TypeError('A complete task is required to calculate its approval scope.');
  }
  const scope = stableApprovalValue({
    schemaVersion: task.schemaVersion || TASK_SCHEMA_VERSION,
    taskId: task.taskId,
    ownerUid: task.ownerUid,
    type: task.type,
    prompt: task.prompt,
    metadata: task.metadata || {},
    requiresApproval: task.requiresApproval === true,
  });
  return crypto.createHash('sha256').update(JSON.stringify(scope)).digest('hex');
}

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
  createNovaApprovalScopeHash,
  createNovaTaskRecord,
  createNovaQueueRecord,
  createNovaAuditEvent,
  normalizeTaskEvidence,
};
