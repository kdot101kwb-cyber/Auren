'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  getDebateApprovalBlockReason,
  buildDebateApprovalUpdate,
  createDebateTaskEnvelope,
} = require('./nova_debate_policy');

const validRecord = () => ({
  status: 'awaiting_user_agreement',
  debate: {
    recommendation: 'revise',
    plan: [
      {step: 'إضافة الاختبار', verification: 'الاختبار ينجح على CI'},
      {step: 'مراجعة الصلاحيات', verification: 'اختبارات الأمان تمر'},
    ],
  },
});

test('approval requires a pending debate and a complete verifiable plan', () => {
  assert.match(getDebateApprovalBlockReason(null), /ليس بانتظار/);
  const record = validRecord();
  record.status = 'plan_approved';
  assert.match(getDebateApprovalBlockReason(record), /ليس بانتظار/);
  const incomplete = validRecord();
  incomplete.debate.plan[0].verification = ' ';
  assert.match(getDebateApprovalBlockReason(incomplete), /معيار تحقق/);
});

test('a reject recommendation cannot be approved as-is', () => {
  const record = validRecord();
  record.debate.recommendation = 'reject';
  assert.match(getDebateApprovalBlockReason(record), /رفض الخطة/);
  assert.throws(() => buildDebateApprovalUpdate(record, 'user-1'), {code: 'failed-precondition'});
});

test('approval is recorded without falsely starting execution', () => {
  const update = buildDebateApprovalUpdate(validRecord(), 'user-1');
  assert.equal(update.status, 'plan_approved');
  assert.equal(update.approvedBy, 'user-1');
  assert.equal(update.executionStarted, false);
  assert.equal(update.executionStatus, 'blocked_adapter_not_connected');
});

test('approval rejects empty approver identity', () => {
  assert.throws(() => buildDebateApprovalUpdate(validRecord(), ''), {code: 'invalid-argument'});
});

test('plan size remains bounded', () => {
  const record = validRecord();
  record.debate.plan = Array.from({length: 13}, (_, i) => ({
    step: 'step ' + i,
    verification: 'verified',
  }));
  assert.match(getDebateApprovalBlockReason(record), /خطة صالحة/);
});

test('debate record carries a shared task envelope gated on owner agreement', () => {
  const task = createDebateTaskEnvelope({
    taskId: 'debate-task-123456',
    ownerUid: 'owner-1',
    prompt: 'راجع خطة NOVA',
    context: 'bounded context',
    strategy: 'strategic',
  });
  assert.equal(task.schemaVersion, 1);
  assert.equal(task.type, 'strategic_debate');
  assert.equal(task.status, 'awaiting_approval');
  assert.equal(task.requiresApproval, true);
  assert.equal(task.executionMode, 'queued_backend_worker_required');
  assert.equal(task.metadata.strategy, 'strategic');
});
