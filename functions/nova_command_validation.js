'use strict';

const ALLOWED_TYPES = new Set([
  'chat', 'plan', 'research', 'opportunity_scan', 'content_draft',
  'image_generation', 'video_generation', 'social_publish',
  'github_ci_check', 'integration_health', 'finance_report',
]);
const APPROVAL_TYPES = new Set(['social_publish', 'image_generation', 'video_generation']);

function normalizeNovaTaskInput(data, ErrorType = Error) {
  const fail = (code, message) => { throw ErrorType === Error ? new ErrorType(message) : new ErrorType(code, message); };
  if (!data || typeof data !== 'object' || Array.isArray(data)) fail('invalid-argument', 'Task input must be an object.');
  const type = String(data.type || '').trim();
  const prompt = String(data.prompt || '').trim();
  const idempotencyKey = String(data.idempotencyKey || '').trim();
  if (!ALLOWED_TYPES.has(type)) fail('invalid-argument', 'Unsupported NOVA task type.');
  if (!prompt || prompt.length > 6000) fail('invalid-argument', 'Prompt must contain 1–6000 characters.');
  if (!/^[A-Za-z0-9_-]{12,128}$/.test(idempotencyKey)) fail('invalid-argument', 'A 12–128 character idempotencyKey is required.');
  const metadata = data.metadata && typeof data.metadata === 'object' && !Array.isArray(data.metadata) ? data.metadata : {};
  return {
    type,
    prompt,
    idempotencyKey,
    metadata: {
      source: String(metadata.source || 'nova_android').slice(0, 80),
      locale: String(metadata.locale || 'ar').slice(0, 20),
    },
    requiresApproval: APPROVAL_TYPES.has(type) || data.requiresApproval === true,
  };
}

function evaluateNovaTaskRateLimit(rate, nowMs = Date.now()) {
  const now = new Date(nowMs);
  const minuteBucket = now.toISOString().slice(0, 16);
  const dayBucket = now.toISOString().slice(0, 10);
  const minuteCount = rate?.minuteBucket === minuteBucket ? Number(rate?.minuteCount) || 0 : 0;
  const dayCount = rate?.dayBucket === dayBucket ? Number(rate?.dayCount) || 0 : 0;
  return {
    allowed: minuteCount < 10 && dayCount < 100,
    minuteBucket,
    minuteCount: minuteCount + 1,
    dayBucket,
    dayCount: dayCount + 1,
    limits: {perMinute: 10, perUtcDay: 100},
  };
}

module.exports = {normalizeNovaTaskInput, evaluateNovaTaskRateLimit, ALLOWED_TYPES, APPROVAL_TYPES};
