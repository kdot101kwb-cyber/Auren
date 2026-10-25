'use strict';

const MAX_PLAN_STEPS = 12;

/**
 * Enforces the human agreement gate independently of model-generated content.
 * This module is deliberately pure so policy checks can be tested without Firebase.
 */
function getDebateApprovalBlockReason(record) {
  if (!record || record.status !== 'awaiting_user_agreement') {
    return 'هذا النقاش ليس بانتظار موافقة جديدة.';
  }
  const debate = record.debate;
  if (!debate || debate.recommendation === 'reject') {
    return 'توصية المجلس هي رفض الخطة؛ راجع الاعتراضات وقدّم خطة معدّلة قبل اعتمادها.';
  }
  if (!Array.isArray(debate.plan) || debate.plan.length === 0 || debate.plan.length > MAX_PLAN_STEPS) {
    return 'لا توجد خطة صالحة للاعتماد.';
  }
  const incomplete = debate.plan.some((step) =>
    !step || typeof step.step !== 'string' || !step.step.trim() ||
    typeof step.verification !== 'string' || !step.verification.trim()
  );
  if (incomplete) {
    return 'كل خطوة في الخطة تحتاج معيار تحقق واضحاً قبل اعتمادها.';
  }
  return null;
}

function buildDebateApprovalUpdate(record, uid) {
  const reason = getDebateApprovalBlockReason(record);
  if (reason) {
    const error = new Error(reason);
    error.code = 'failed-precondition';
    throw error;
  }
  if (typeof uid !== 'string' || !uid.trim()) {
    const error = new Error('المستخدم الموافق غير محدد.');
    error.code = 'invalid-argument';
    throw error;
  }
  return {
    status: 'plan_approved',
    approvedBy: uid,
    executionStarted: false,
    executionStatus: 'blocked_adapter_not_connected',
  };
}

module.exports = {getDebateApprovalBlockReason, buildDebateApprovalUpdate};
