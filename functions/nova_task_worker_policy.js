'use strict';

const {payloadHash, constantTimeEqual} = require('./action_security');
const SAFE_TEXT_TYPES = new Set(['chat', 'plan', 'research', 'content_draft', 'social_content_draft']);
const APPROVAL_TYPES = new Set(['image_generation', 'video_generation', 'social_publish']);

function taskPayloadFingerprint(task) {
  return payloadHash({
    type: String(task?.type || ''),
    prompt: String(task?.prompt || ''),
    metadata: task?.metadata && typeof task.metadata === 'object' && !Array.isArray(task.metadata) ? task.metadata : {},
  });
}

function isTaskExecutable(task, ownerUid) {
  if (!task || typeof task !== 'object' || !ownerUid) return false;
  if (task.ownerUid !== ownerUid) return false;
  const type = String(task.type || '');
  const prompt = typeof task.prompt === 'string' ? task.prompt.trim() : '';
  if (!prompt || prompt.length > 6000) return false;
  if (SAFE_TEXT_TYPES.has(type)) return true;
  if (!APPROVAL_TYPES.has(type)) return false;
  if (type !== 'video_generation') return false; // no publish/image execution adapter is registered
  if (task.requiresApproval !== true || task.approvedBy !== ownerUid) return false;
  const expected = taskPayloadFingerprint(task);
  return typeof task.approvedFingerprint === 'string' &&
    constantTimeEqual(task.approvedFingerprint, expected) &&
    typeof task.approvalFingerprint === 'string' &&
    constantTimeEqual(task.approvalFingerprint, expected);
}

module.exports = {SAFE_TEXT_TYPES, APPROVAL_TYPES, taskPayloadFingerprint, isTaskExecutable};
