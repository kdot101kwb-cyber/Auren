'use strict';
const {createNovaApprovalScopeHash} = require('./nova_task_contract');

const SAFE_TEXT_TYPES = new Set(['chat', 'plan', 'research', 'content_draft', 'social_content_draft']);

function isTaskExecutable(task, ownerUid, nowMs = Date.now()) {
  if (!task || typeof task !== 'object') return false;
  const type = String(task.type || '');
  if (SAFE_TEXT_TYPES.has(type)) return true;
  if (type !== 'video_generation' || task.requiresApproval !== true ||
      !ownerUid || task.ownerUid !== ownerUid) return false;

  const approval = task.approval;
  if (!approval || approval.required !== true || approval.approvedBy !== ownerUid ||
      typeof approval.scopeHash !== 'string' || !/^[a-f0-9]{64}$/i.test(approval.scopeHash)) {
    return false;
  }

  const expiresAt = approval.expiresAt;
  const expiresAtMs = typeof expiresAt === 'number'
    ? expiresAt
    : (expiresAt && typeof expiresAt.toMillis === 'function'
      ? expiresAt.toMillis()
      : (expiresAt instanceof Date ? expiresAt.getTime() : NaN));
  if (!Number.isFinite(expiresAtMs) || expiresAtMs <= nowMs) return false;

  try {
    return approval.scopeHash === createNovaApprovalScopeHash(task);
  } catch (_) {
    return false;
  }
}

module.exports = {SAFE_TEXT_TYPES, isTaskExecutable};
