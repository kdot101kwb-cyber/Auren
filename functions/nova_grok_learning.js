'use strict';

const MAX_LESSON_CHARS = 500;
const MAX_LESSONS_IN_CONTEXT = 8;
const ALLOWED_TYPES = new Set(['correction', 'preference', 'successful_pattern', 'failed_pattern']);

function normalizeLesson(input = {}) {
  const type = String(input.type || '').trim();
  const lesson = String(input.lesson || '').trim().replace(/\s+/g, ' ');
  if (!ALLOWED_TYPES.has(type)) throw new Error('نوع الملاحظة غير مدعوم.');
  if (lesson.length < 3 || lesson.length > MAX_LESSON_CHARS) {
    throw new Error('الملاحظة يجب أن تكون بين 3 و500 حرف.');
  }
  if (/\b(password|api[_ -]?key|secret|recovery code|private key)\b/i.test(lesson)) {
    throw new Error('لا تحفظ كلمات المرور أو المفاتيح أو أسرار الحسابات في ذاكرة NOVA.');
  }
  return {type, lesson, confirmedByUser: true};
}

function buildLearningContext(records = []) {
  return records.slice(0, MAX_LESSONS_IN_CONTEXT).map((record) => ({
    type: String(record.type || 'preference'),
    lesson: String(record.lesson || '').slice(0, MAX_LESSON_CHARS),
    confirmedByUser: record.confirmedByUser === true,
  })).filter((record) => record.confirmedByUser && record.lesson.length > 0);
}

function buildImprovementLoop({draft, feedback, previousOutcome} = {}) {
  return {
    steps: ['compare the draft with the requested outcome', 'classify the error or successful pattern', 'ask the user to confirm a reusable lesson', 'apply confirmed lessons on the next relevant task', 'verify the next result against tests or evidence'],
    draftProvided: Boolean(String(draft || '').trim()),
    feedbackProvided: Boolean(String(feedback || '').trim()),
    outcomeEvidenceProvided: Boolean(String(previousOutcome || '').trim()),
    autoTrainingClaim: false,
    note: 'This is a feedback-and-memory loop, not model-weight training. Only user-confirmed, non-secret lessons should be persisted.',
  };
}

module.exports = {ALLOWED_TYPES, normalizeLesson, buildLearningContext, buildImprovementLoop};
