'use strict';

const {createNovaApprovalScopeHash} = require('./nova_task_contract');

// Explicit inventory: unknown task types are always treated as high risk and denied.
const ACTION_POLICIES = Object.freeze({
  chat: Object.freeze({risk:'low', approvalRequired:false, workerExecutable:true}),
  plan: Object.freeze({risk:'low', approvalRequired:false, workerExecutable:true}),
  research: Object.freeze({risk:'low', approvalRequired:false, workerExecutable:true}),
  content_draft: Object.freeze({risk:'low', approvalRequired:false, workerExecutable:true}),
  social_content_draft: Object.freeze({risk:'low', approvalRequired:false, workerExecutable:true}),
  opportunity_scan: Object.freeze({risk:'low', approvalRequired:false, workerExecutable:false}),
  github_ci_check: Object.freeze({risk:'medium', approvalRequired:false, workerExecutable:false}),
  integration_health: Object.freeze({risk:'medium', approvalRequired:false, workerExecutable:false}),
  finance_report: Object.freeze({risk:'medium', approvalRequired:false, workerExecutable:false}),
  image_generation: Object.freeze({risk:'external_cost_or_provider', approvalRequired:true, workerExecutable:false}),
  video_generation: Object.freeze({risk:'external_cost_or_provider', approvalRequired:true, workerExecutable:false}),
  social_publish: Object.freeze({risk:'external_publication', approvalRequired:true, workerExecutable:false}),
  send_message: Object.freeze({risk:'external_communication', approvalRequired:true, workerExecutable:false}),
  purchase: Object.freeze({risk:'financial', approvalRequired:true, workerExecutable:false}),
  paid_api_call: Object.freeze({risk:'financial', approvalRequired:true, workerExecutable:false}),
  production_deploy: Object.freeze({risk:'production_change', approvalRequired:true, workerExecutable:false}),
  delete_data: Object.freeze({risk:'destructive', approvalRequired:true, workerExecutable:false}),
  permission_change: Object.freeze({risk:'privilege_change', approvalRequired:true, workerExecutable:false}),
  data_migration: Object.freeze({risk:'data_change', approvalRequired:true, workerExecutable:false}),
  secret_rotation: Object.freeze({risk:'credential_change', approvalRequired:true, workerExecutable:false}),
});

const APPROVAL_REQUIRED_TYPES = new Set(
  Object.keys(ACTION_POLICIES).filter((type) => ACTION_POLICIES[type].approvalRequired)
);

function getNovaActionPolicy(type) {
  return ACTION_POLICIES[String(type || '')] || Object.freeze({
    risk:'unknown',
    approvalRequired:true,
    workerExecutable:false,
  });
}

function isNovaActionApprovalValid(task, ownerUid, nowMs = Date.now()) {
  if (!task || typeof task !== 'object' || !ownerUid || task.ownerUid !== ownerUid ||
      task.requiresApproval !== true) return false;
  const policy = getNovaActionPolicy(task.type);
  if (!policy.approvalRequired && task.requiresApproval !== true) return false;
  const approval = task.approval;
  if (!approval || approval.required !== true || approval.approvedBy !== ownerUid ||
      typeof approval.scopeHash !== 'string' || !/^[a-f0-9]{64}$/i.test(approval.scopeHash)) return false;
  const expiry = approval.expiresAt;
  const expiryMs = typeof expiry === 'number'
    ? expiry
    : (expiry && typeof expiry.toMillis === 'function'
      ? expiry.toMillis()
      : (expiry instanceof Date ? expiry.getTime() : NaN));
  if (!Number.isFinite(expiryMs) || expiryMs <= nowMs) return false;
  try {
    return approval.scopeHash === createNovaApprovalScopeHash(task);
  } catch (_) {
    return false;
  }
}

function canNovaWorkerExecute(task, ownerUid, nowMs = Date.now()) {
  if (!task || typeof task !== 'object') return false;
  const policy = getNovaActionPolicy(task.type);
  if (!policy.workerExecutable) return false;
  return (policy.approvalRequired || task.requiresApproval === true)
    ? isNovaActionApprovalValid(task, ownerUid, nowMs)
    : true;
}

module.exports = {
  ACTION_POLICIES,
  APPROVAL_REQUIRED_TYPES,
  getNovaActionPolicy,
  isNovaActionApprovalValid,
  canNovaWorkerExecute,
};
