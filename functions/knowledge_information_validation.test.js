'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  clean,
  required,
  safeUrls,
  boundedUniqueStrings,
  normalizeQueueStatus,
  normalizePriority,
  normalizeEvidenceVerdict,
} = require('./knowledge_information_validation');

test('clean collapses whitespace and enforces the maximum length', () => {
  assert.equal(clean('  one\n   two  ', 20), 'one two');
  assert.equal(clean('abcdef', 3), 'abc');
});

test('required rejects empty input after normalization', () => {
  assert.throws(() => required('  \n ', 'title', 20), /title is required/);
  assert.equal(required('  a   title ', 'title', 20), 'a title');
});

test('safeUrls accepts HTTP(S), deduplicates, and rejects unsafe schemes or credentials', () => {
  assert.deepEqual(safeUrls([
    'https://example.com/a',
    'https://example.com/a',
    'javascript:alert(1)',
    'https://user:pass@example.com/private',
    'file:///etc/passwd',
    'not a URL',
  ]), ['https://example.com/a']);
});

test('boundedUniqueStrings trims, bounds, and removes duplicates', () => {
  assert.deepEqual(
    boundedUniqueStrings([' ar ', 'en', 'ar', '', 'long-term'], 3, 2),
    ['ar', 'en', 'lo'],
  );
  assert.deepEqual(boundedUniqueStrings('not-an-array', 8, 40), []);
});

test('queue and evidence states fall back to safe defaults', () => {
  assert.equal(normalizeQueueStatus('reading'), 'reading');
  assert.equal(normalizeQueueStatus('done-ish'), 'to_read');
  assert.equal(normalizePriority('high'), 'high');
  assert.equal(normalizePriority('urgent'), 'normal');
  assert.equal(normalizeEvidenceVerdict('disputed'), 'disputed');
  assert.equal(normalizeEvidenceVerdict('verified'), 'unverified');
});
