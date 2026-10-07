'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {payloadHash, constantTimeEqual} = require('./action_security');

test('payload hash is deterministic for reordered object keys', () => {
  const a = {b: 2, nested: {z: 1, a: true}, a: 'x'};
  const b = {a: 'x', nested: {a: true, z: 1}, b: 2};
  assert.equal(payloadHash(a), payloadHash(b));
});

test('payload hash changes when approved payload changes', () => {
  const approved = payloadHash({amountMinor: 1000, currency: 'USD'});
  const tampered = payloadHash({amountMinor: 1001, currency: 'USD'});
  assert.equal(constantTimeEqual(approved, tampered), false);
});

test('nested arrays are canonicalized without losing order', () => {
  const a = {items: [{b: 2, a: 1}, {c: 3}]};
  const b = {items: [{a: 1, b: 2}, {c: 3}]};
  assert.equal(payloadHash(a), payloadHash(b));
  assert.notEqual(payloadHash(a), payloadHash({items: [{a: 1, b: 2}, {c: 4}]}));
});
