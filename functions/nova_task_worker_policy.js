'use strict';
const {matchesTaskApprovalScope} = require('./nova_task_contract');
const SAFE_TEXT_TYPES = new Set(['chat', 'plan', 'research', 'content_draft', 'social_content_draft']);

function hasValidOwnerApproval(task, ownerUid) {
  return Boolean(ownerUid) &&
    task.ownerUid === ownerUid &&
    task.requiresApproval === true &&
    task.approval?.required === true &&
    task.approvedBy === ownerUid &&
    task.approval?.approvedBy === ownerUid &&
    matchesTaskApprovalScope(task, task.approval?.scopeHash);
}

function isTaskExecutable(task, ownerUid) {
  if (!task || typeof task !== 'object' || !ownerUid || task.ownerUid !== ownerUid) return false;
  const type = String(task.type || '');
  if (SAFE_TEXT_TYPES.has(type)) {
    return task.requiresApproval === true ? hasValidOwnerApproval(task, ownerUid) : true;
  }
  return type === 'video_generation' && hasValidOwnerApproval(task, ownerUid);
}

module.exports = {SAFE_TEXT_TYPES, hasValidOwnerApproval, isTaskExecutable};
