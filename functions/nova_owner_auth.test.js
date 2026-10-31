'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {requireNovaOwner} = require('./nova_owner_auth');

function request(uid, token = {}) {
  return {auth:uid ? {uid, token} : null};
}

test('requires an authenticated Firebase user', () => {
  assert.throws(() => requireNovaOwner(request(null)), {code:'unauthenticated'});
});

test('rejects anonymous accounts even if a malformed token contains the owner claim', () => {
  assert.throws(() => requireNovaOwner(request('anon-1', {
    novaOwner:true,
    email_verified:true,
    firebase:{sign_in_provider:'anonymous'},
  })), {code:'permission-denied'});
});

test('rejects users without the server-issued owner claim', () => {
  assert.throws(() => requireNovaOwner(request('user-1', {
    email_verified:true,
    firebase:{sign_in_provider:'password'},
  })), {code:'permission-denied'});
});

test('rejects owner claims when the email is not verified', () => {
  assert.throws(() => requireNovaOwner(request('user-1', {
    novaOwner:true,
    email_verified:false,
    firebase:{sign_in_provider:'password'},
  })), {code:'permission-denied'});
});

test('accepts only a verified, non-anonymous account with the server-issued owner claim', () => {
  assert.equal(requireNovaOwner(request('owner-1', {
    novaOwner:true,
    email_verified:true,
    firebase:{sign_in_provider:'password'},
  })), 'owner-1');
});
