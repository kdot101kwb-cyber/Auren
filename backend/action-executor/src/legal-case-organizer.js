const CASE_STATUSES = Object.freeze(['draft', 'active', 'waiting', 'closed', 'archived']);
const MAX_ID_LENGTH = 128;
const MAX_TEXT_LENGTH = 2000;

function text(value, field, max = MAX_TEXT_LENGTH, required = false) {
  if (value == null && !required) return '';
  if (typeof value !== 'string') throw Object.assign(new Error(`${field} must be text.`), { code: 400 });
  const result = value.trim();
  if ((required && !result) || result.length > max || /[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/.test(result)) {
    throw Object.assign(new Error(`Invalid ${field}.`), { code: 400 });
  }
  return result;
}

function isoDate(value, field) {
  if (value == null || value === '') return null;
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw Object.assign(new Error(`${field} must use YYYY-MM-DD.`), { code: 400 });
  }
  const parsed = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
    throw Object.assign(new Error(`Invalid ${field}.`), { code: 400 });
  }
  return value;
}

export function normalizeLegalCase(input, ownerUid) {
  if (typeof ownerUid !== 'string' || !ownerUid.trim() || ownerUid.length > MAX_ID_LENGTH || ownerUid.includes('/')) {
    throw Object.assign(new Error('A valid owner uid is required.'), { code: 400 });
  }
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw Object.assign(new Error('Case input must be an object.'), { code: 400 });
  }
  const status = CASE_STATUSES.includes(input.status) ? input.status : 'draft';
  const createdDate = isoDate(input.createdDate, 'createdDate');
  const nextDeadline = isoDate(input.nextDeadline, 'nextDeadline');
  if (createdDate && nextDeadline && nextDeadline < createdDate) {
    throw Object.assign(new Error('Deadline cannot precede the case creation date.'), { code: 400 });
  }
  return {
    caseId: text(input.caseId, 'caseId', MAX_ID_LENGTH),
    ownerUid: ownerUid.trim(),
    title: text(input.title, 'title', 160, true),
    category: text(input.category, 'category', 80),
    referenceNumber: text(input.referenceNumber, 'referenceNumber', 128),
    summary: text(input.summary, 'summary', MAX_TEXT_LENGTH),
    status,
    createdDate,
    nextDeadline,
    updatedAt: isoDate(input.updatedAt, 'updatedAt'),
    reminderEnabled: input.reminderEnabled === true,
    // Legal content is user-entered; this helper does not determine rights or provide legal advice.
  };
}

export function listUpcomingCaseDeadlines(cases, asOfDate) {
  const today = isoDate(asOfDate, 'asOfDate');
  if (!Array.isArray(cases)) throw Object.assign(new Error('Cases must be an array.'), { code: 400 });
  return cases
    .filter((item) => {
      if (!item || typeof item !== 'object' || item.status === 'closed' || item.status === 'archived'
          || item.reminderEnabled !== true) return false;
      try {
        const deadline = isoDate(item.nextDeadline, 'nextDeadline');
        return deadline !== null && deadline >= today;
      } catch {
        return false;
      }
    })
    .slice()
    .sort((a, b) => a.nextDeadline.localeCompare(b.nextDeadline));
}

export { CASE_STATUSES };
