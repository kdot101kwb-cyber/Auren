'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');

function normalizeE164(value) {
  const phone = String(value || '').trim().replace(/[()\s.-]/g, '');
  return /^\+[1-9]\d{7,14}$/.test(phone) ? phone : null;
}

test('normalizes common E.164 formatting without changing country code', () => {
  assert.equal(normalizeE164('+249 912-345-678'), '+249912345678');
  assert.equal(normalizeE164('+1 (415) 555.0100'), '+14155550100');
});

test('rejects national, malformed, and overlong numbers until explicitly normalized by the client', () => {
  assert.equal(normalizeE164('0912345678'), null);
  assert.equal(normalizeE164('+012345678'), null);
  assert.equal(normalizeE164('+1234567890123456'), null);
  assert.equal(normalizeE164(''), null);
});
