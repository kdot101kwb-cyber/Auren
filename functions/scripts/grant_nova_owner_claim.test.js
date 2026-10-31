'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {validateNovaOwnerGrantTarget} = require('./grant_nova_owner_claim');

const validUser = {
  email:'owner@example.com',
  emailVerified:true,
  providerData:[{providerId:'password'}],
};

test('accepts the expected verified owner identity in an approved Firebase project', () => {
  assert.doesNotThrow(() => validateNovaOwnerGrantTarget(
    'owner-uid-123', 'owner@example.com', 'auren-staging', validUser,
  ));
});

test('rejects a UID whose Firebase email differs from the expected owner email', () => {
  assert.throws(() => validateNovaOwnerGrantTarget(
    'wrong-uid', 'owner@example.com', 'auren-90ccc',
    {...validUser, email:'other@example.com'},
  ), /UID and expected email must match/);
});

test('rejects an unverified email', () => {
  assert.throws(() => validateNovaOwnerGrantTarget(
    'owner-uid-123', 'owner@example.com', 'auren-90ccc',
    {...validUser, emailVerified:false},
  ), /verified/);
});

test('rejects an anonymous-only account', () => {
  assert.throws(() => validateNovaOwnerGrantTarget(
    'owner-uid-123', 'owner@example.com', 'auren-90ccc',
    {...validUser, providerData:[{providerId:'anonymous'}]},
  ), /non-anonymous/);
});

test('rejects an account without a non-anonymous provider', () => {
  assert.throws(() => validateNovaOwnerGrantTarget(
    'owner-uid-123', 'owner@example.com', 'auren-90ccc',
    {...validUser, providerData:[]},
  ), /non-anonymous/);
});

test('rejects a Firebase project outside the explicit allowlist', () => {
  assert.throws(() => validateNovaOwnerGrantTarget(
    'owner-uid-123', 'owner@example.com', 'unexpected-project', validUser,
  ), /explicitly to auren-90ccc or auren-staging/);
});

test('rejects malformed UID or expected email', () => {
  assert.throws(() => validateNovaOwnerGrantTarget(
    'bad uid', 'owner@example.com', 'auren-90ccc', validUser,
  ), /valid Firebase UID/);
  assert.throws(() => validateNovaOwnerGrantTarget(
    'owner-uid-123', 'not-an-email', 'auren-90ccc', validUser,
  ), /valid Firebase UID/);
});
