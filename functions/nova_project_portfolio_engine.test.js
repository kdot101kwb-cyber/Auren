'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeNovaProjectInput,
  normalizeNovaWorkItemInput,
  validateProjectTransition,
  validateWorkItemTransition,
  normalizeProjectId,
  priorityScore,
  sortProjectsByPriority,
} = require('./nova_project_portfolio_engine');

test('normalizes project fields and computes a bounded priority score', () => {
  const project = normalizeNovaProjectInput({
    title:'  NOVA  ', area:'nova', priority:'high',
    strategicValue:5, urgency:4, confidence:4, effort:2,
    status:'completed',
  });
  assert.equal(project.title, 'NOVA');
  assert.equal(project.area, 'nova');
  assert.equal(project.status, 'idea');
  assert.equal(project.ownerDecisionRequired, true);
  assert.equal(project.priorityScore, 87);
  assert.ok(project.priorityScore >= 0 && project.priorityScore <= 100);
});

test('rejects empty or oversized project names and bounds descriptions', () => {
  assert.throws(() => normalizeNovaProjectInput({title:'  '}), /اسم المشروع/);
  assert.throws(() => normalizeNovaProjectInput({title:'x'.repeat(121)}), /أطول/);
  assert.equal(normalizeNovaProjectInput({title:'X',description:'d'.repeat(3000)}).description.length, 2400);
});

test('recalculates project priority using updated evidence inputs', () => {
  const score = require('./nova_project_portfolio_engine').normalizeProjectScoring({
    strategicValue:5, urgency:5, confidence:4, effort:1, priority:'critical',
  });
  assert.equal(score.priority, 'critical');
  assert.equal(score.priorityScore, 94);
  assert.equal(score.effort, 1);
});

test('normalizes work items and defaults to owner approval', () => {
  const item = normalizeNovaWorkItemInput({title:'Build test'});
  assert.equal(item.status, 'backlog');
  assert.equal(item.requiresOwnerApproval, true);
  assert.equal(normalizeNovaWorkItemInput({title:'Read-only',requiresOwnerApproval:false}).requiresOwnerApproval, false);
  assert.throws(() => normalizeNovaWorkItemInput({title:''}), /عنوان المهمة/);
});

test('allows only explicit project lifecycle transitions', () => {
  assert.deepEqual(validateProjectTransition('idea','active',''), {status:'active',decisionNote:''});
  assert.throws(() => validateProjectTransition('idea','completed','done'), /غير مسموح/);
  assert.throws(() => validateProjectTransition('active','paused',''), /سبباً واضحاً/);
  assert.deepEqual(validateProjectTransition('active','paused','نقص الموارد'), {
    status:'paused', decisionNote:'نقص الموارد',
  });
  assert.throws(() => validateProjectTransition('cancelled','active','reopen'), /غير مسموح/);
});

test('requires evidence for blocked, deferred, cancelled and completed work', () => {
  assert.throws(() => validateWorkItemTransition('in_progress','blocked',''), /سبباً أو نتيجة/);
  assert.equal(validateWorkItemTransition('in_progress','completed','اختبارات ناجحة').status, 'completed');
  assert.throws(() => validateWorkItemTransition('completed','in_progress','reopen'), /غير مسموح/);
});

test('validates project ids and sorts by score without mutating input', () => {
  assert.equal(normalizeProjectId('project_123456'), 'project_123456');
  assert.throws(() => normalizeProjectId('../private'), /معرّف/);
  const input = [{priorityScore:10},{priorityScore:90},{priorityScore:50}];
  const sorted = sortProjectsByPriority(input);
  assert.deepEqual(sorted.map((item) => item.priorityScore), [90,50,10]);
  assert.equal(input[0].priorityScore, 10);
  assert.ok(priorityScore({strategicValue:1,urgency:1,confidence:1,effort:5}) >= 0);
});
