'use strict';

const MAX_DEPENDENCIES = 5;
const TASK_ID_PATTERN = /^[A-Za-z0-9_-]{12,128}$/;
const SUCCESS_STATUSES = new Set(['succeeded', 'completed']);
const FAILURE_STATUSES = new Set(['failed', 'cancelled', 'blocked']);

function normalizeDependencyIds(value, taskId) {
  if (value == null) return [];
  if (!Array.isArray(value)) throw new Error('dependsOnTaskIds must be an array.');
  if (value.length > MAX_DEPENDENCIES) {
    throw new Error('A NOVA task can depend on at most ' + MAX_DEPENDENCIES + ' tasks.');
  }
  const ids = value.map((item) => String(item || '').trim());
  if (ids.some((id) => !TASK_ID_PATTERN.test(id))) {
    throw new Error('Every dependency must be a valid NOVA task ID.');
  }
  if (new Set(ids).size !== ids.length) {
    throw new Error('Duplicate task dependencies are not allowed.');
  }
  if (taskId && ids.includes(taskId)) {
    throw new Error('A task cannot depend on itself.');
  }
  return ids;
}

function resolveDependencyState(statuses, requiresApproval = false) {
  const normalized = statuses.map((status) => String(status || 'unknown').trim().toLowerCase());
  if (normalized.some((status) => FAILURE_STATUSES.has(status))) {
    return {
      status: 'blocked',
      error: 'A prerequisite task failed, was cancelled, or was blocked. Review the dependency before continuing.',
    };
  }
  if (normalized.length === 0 || normalized.every((status) => SUCCESS_STATUSES.has(status))) {
    return {status: requiresApproval ? 'awaiting_approval' : 'queued', error: null};
  }
  return {status: 'waiting_for_dependencies', error: null};
}

module.exports = {
  MAX_DEPENDENCIES,
  normalizeDependencyIds,
  resolveDependencyState,
};
