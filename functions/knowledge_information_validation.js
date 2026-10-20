'use strict';

const MAX_TITLE = 180;
const MAX_TEXT = 6000;
const MAX_URLS = 12;

function clean(value, max = MAX_TEXT) {
  return String(value ?? '').replace(/\s+/g, ' ').trim().slice(0, max);
}

function required(value, label, max = MAX_TEXT) {
  const result = clean(value, max);
  if (!result) throw new TypeError(label + ' is required.');
  return result;
}

function safeUrls(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.slice(0, MAX_URLS).map((item) => {
    const raw = clean(item, 2000);
    try {
      const url = new URL(raw);
      if (!['https:', 'http:'].includes(url.protocol)) return '';
      if (url.username || url.password || !url.hostname) return '';
      return url.toString();
    } catch (_) { return ''; }
  }).filter(Boolean))];
}

function boundedUniqueStrings(value, maxItems, maxLength) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((item) => clean(item, maxLength)).filter(Boolean))]
    .slice(0, maxItems);
}

function normalizeQueueStatus(value) {
  return ['to_read', 'reading', 'read'].includes(value) ? value : 'to_read';
}

function normalizePriority(value) {
  return ['low', 'normal', 'high'].includes(value) ? value : 'normal';
}

function normalizeEvidenceVerdict(value) {
  return ['unverified', 'supported', 'disputed', 'mixed'].includes(value)
    ? value : 'unverified';
}

module.exports = {
  MAX_TITLE,
  MAX_TEXT,
  MAX_URLS,
  clean,
  required,
  safeUrls,
  boundedUniqueStrings,
  normalizeQueueStatus,
  normalizePriority,
  normalizeEvidenceVerdict,
};
