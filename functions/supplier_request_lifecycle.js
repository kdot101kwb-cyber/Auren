'use strict';

const TRANSITIONS = Object.freeze({
  draft: new Set(['waiting_response', 'failed', 'cancelled']),
  waiting_response: new Set(['replied', 'completed', 'failed', 'cancelled']),
  replied: new Set(['completed', 'cancelled']),
  failed: new Set(['cancelled']),
  cancelled: new Set(),
  completed: new Set(),
});

const RESPONSE_STATUSES = new Set(['waiting_response', 'replied']);

function normalizeStatus(value, fallback = 'draft') {
  const normalized = String(value ?? '').trim().toLowerCase();
  return normalized || fallback;
}

function isAllowedTransition(currentValue, nextValue) {
  const current = normalizeStatus(currentValue);
  const next = normalizeStatus(nextValue);
  return current === next || Boolean(TRANSITIONS[current]?.has(next));
}

function requiresExternalDispatch(statusValue, externalDispatch) {
  return RESPONSE_STATUSES.has(normalizeStatus(statusValue)) && externalDispatch !== true;
}

function nextRetryCount(value) {
  const current = value == null ? 0 : Number(value);
  if (!Number.isSafeInteger(current) || current < 0) {
    return {ok: false, reason: 'invalid-count'};
  }
  const next = current + 1;
  if (next > 5) return {ok: false, reason: 'limit-reached'};
  return {ok: true, count: next};
}

module.exports = {
  normalizeStatus,
  isAllowedTransition,
  requiresExternalDispatch,
  nextRetryCount,
};
