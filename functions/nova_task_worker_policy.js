'use strict';
const SAFE_TEXT_TYPES = new Set(['chat', 'plan', 'research', 'content_draft', 'social_content_draft', 'github_ci_check', 'circleci_check', 'self_repair_plan']);

function isTaskExecutable(task, ownerUid) {
  if (!task || typeof task !== 'object') return false;
  const type = String(task.type || '');
  if (SAFE_TEXT_TYPES.has(type)) return true;
  return type === 'video_generation' &&
    task.requiresApproval === true &&
    Boolean(ownerUid) &&
    task.approvedBy === ownerUid;
}

module.exports = {SAFE_TEXT_TYPES, isTaskExecutable};
