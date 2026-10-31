'use strict';

const PROJECT_STATUSES = Object.freeze(['idea', 'active', 'paused', 'deferred', 'cancelled', 'completed']);
const WORK_ITEM_STATUSES = Object.freeze(['backlog', 'planned', 'in_progress', 'blocked', 'deferred', 'cancelled', 'completed']);
const AREAS = Object.freeze(['personal', 'auren', 'nova', 'income', 'content', 'research', 'operations', 'other']);
const PRIORITIES = Object.freeze(['low', 'normal', 'high', 'critical']);

const PROJECT_TRANSITIONS = Object.freeze({
  idea: ['active', 'deferred', 'cancelled'],
  active: ['paused', 'deferred', 'cancelled', 'completed'],
  paused: ['active', 'deferred', 'cancelled'],
  deferred: ['idea', 'active', 'cancelled'],
  cancelled: [],
  completed: [],
});
const WORK_ITEM_TRANSITIONS = Object.freeze({
  backlog: ['planned', 'in_progress', 'deferred', 'cancelled'],
  planned: ['in_progress', 'blocked', 'deferred', 'cancelled'],
  in_progress: ['blocked', 'deferred', 'cancelled', 'completed'],
  blocked: ['planned', 'in_progress', 'deferred', 'cancelled'],
  deferred: ['planned', 'cancelled'],
  cancelled: [],
  completed: [],
});

function clean(value, max) {
  return String(value ?? '').replace(/\u0000/g, '').trim().slice(0, max);
}
function boundedScore(value, fallback = 3) {
  const n = Number(value);
  return Number.isInteger(n) && n >= 1 && n <= 5 ? n : fallback;
}
function priorityScore(input) {
  const value = boundedScore(input.strategicValue);
  const urgency = boundedScore(input.urgency);
  const confidence = boundedScore(input.confidence);
  const effort = boundedScore(input.effort);
  return Math.round(((value * 0.35 + urgency * 0.25 + confidence * 0.20 + (6 - effort) * 0.20) / 5) * 100);
}
function normalizeNovaProjectInput(data = {}) {
  const title = clean(data.title, 120);
  if (!title) throw new Error('اكتب اسم المشروع أولاً.');
  if (String(data.title ?? '').length > 120) throw new Error('اسم المشروع أطول من الحد المسموح.');
  const area = AREAS.includes(data.area) ? data.area : 'other';
  const priority = PRIORITIES.includes(data.priority) ? data.priority : 'normal';
  const strategicValue = boundedScore(data.strategicValue);
  const urgency = boundedScore(data.urgency);
  const confidence = boundedScore(data.confidence);
  const effort = boundedScore(data.effort);
  return {
    title,
    description: clean(data.description, 2400),
    area,
    priority,
    strategicValue,
    urgency,
    confidence,
    effort,
    priorityScore: priorityScore({strategicValue, urgency, confidence, effort}),
    status: 'idea',
    ownerDecisionRequired: true,
  };
}
function normalizeNovaWorkItemInput(data = {}) {
  const title = clean(data.title, 180);
  if (!title) throw new Error('اكتب عنوان المهمة أولاً.');
  if (String(data.title ?? '').length > 180) throw new Error('عنوان المهمة أطول من الحد المسموح.');
  const priority = PRIORITIES.includes(data.priority) ? data.priority : 'normal';
  return {
    title,
    description: clean(data.description, 1600),
    priority,
    status: 'backlog',
    requiresOwnerApproval: data.requiresOwnerApproval !== false,
  };
}
function validateProjectTransition(current, next, decisionNote) {
  if (!PROJECT_STATUSES.includes(current) || !PROJECT_STATUSES.includes(next)) {
    throw new Error('حالة المشروع غير معروفة.');
  }
  if (current === next) throw new Error('المشروع موجود بالفعل في هذه الحالة.');
  if (!(PROJECT_TRANSITIONS[current] || []).includes(next)) {
    throw new Error('انتقال حالة المشروع غير مسموح: ' + current + ' → ' + next + '.');
  }
  if (['paused', 'deferred', 'cancelled', 'completed'].includes(next) && !clean(decisionNote, 1000)) {
    throw new Error('اكتب سبباً واضحاً لهذا القرار قبل تغيير حالة المشروع.');
  }
  return {status: next, decisionNote: clean(decisionNote, 1000)};
}
function validateWorkItemTransition(current, next, decisionNote) {
  if (!WORK_ITEM_STATUSES.includes(current) || !WORK_ITEM_STATUSES.includes(next)) {
    throw new Error('حالة المهمة غير معروفة.');
  }
  if (current === next) throw new Error('المهمة موجودة بالفعل في هذه الحالة.');
  if (!(WORK_ITEM_TRANSITIONS[current] || []).includes(next)) {
    throw new Error('انتقال حالة المهمة غير مسموح.');
  }
  if (['blocked', 'deferred', 'cancelled', 'completed'].includes(next) && !clean(decisionNote, 1000)) {
    throw new Error('اكتب سبباً أو نتيجة موثقة قبل تغيير حالة المهمة.');
  }
  return {status: next, decisionNote: clean(decisionNote, 1000)};
}
function normalizeProjectId(value) {
  const id = clean(value, 128);
  if (!/^[A-Za-z0-9_-]{12,128}$/.test(id)) throw new Error('معرّف المشروع غير صالح.');
  return id;
}
function sortProjectsByPriority(projects) {
  return [...projects].sort((a, b) =>
    Number(b.priorityScore || 0) - Number(a.priorityScore || 0) ||
    String(b.updatedAt || '').localeCompare(String(a.updatedAt || '')));
}

module.exports = {
  PROJECT_STATUSES,
  WORK_ITEM_STATUSES,
  AREAS,
  PRIORITIES,
  normalizeNovaProjectInput,
  normalizeNovaWorkItemInput,
  validateProjectTransition,
  validateWorkItemTransition,
  normalizeProjectId,
  priorityScore,
  sortProjectsByPriority,
};
