'use strict';

const crypto = require('crypto');

function canonicalize(value) {
  if (value === null || typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return value;
  }
  if (Array.isArray(value)) return value.map(canonicalize);
  if (typeof value === 'object') {
    const out = {};
    for (const key of Object.keys(value).sort()) {
      out[key] = canonicalize(value[key]);
    }
    return out;
  }
  return String(value);
}

function payloadHash(payload) {
  const canonical = JSON.stringify(canonicalize(payload || {}));
  return crypto.createHash('sha256').update(canonical, 'utf8').digest('hex');
}

function constantTimeEqual(a, b) {
  const left = Buffer.from(String(a || ''), 'utf8');
  const right = Buffer.from(String(b || ''), 'utf8');
  if (left.length !== right.length) return false;
  return crypto.timingSafeEqual(left, right);
}

function createIdempotencyKey() {
  return crypto.randomUUID();
}

module.exports = {canonicalize, payloadHash, constantTimeEqual, createIdempotencyKey};
