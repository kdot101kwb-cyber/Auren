'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  validateNovaOwnerGrantTarget,
  grantNovaOwnerClaim,
} = require('./grant_nova_owner_claim');

const validUser = {
  email:'owner@example.com',
  emailVerified:true,
  providerData:[{providerId:'password'}],
  customClaims:{existingRole:'admin'},
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

test('grants only after reading and validating the actual Firebase account, preserving existing claims', async () => {
  const calls = [];
  const auth = {
    async getUser(uid) {
      calls.push(['getUser', uid]);
      return validUser;
    },
    async setCustomUserClaims(uid, claims) {
      calls.push(['setCustomUserClaims', uid, claims]);
    },
  };
  const result = await grantNovaOwnerClaim(
    auth, 'owner-uid-123', 'OWNER@example.com', 'auren-staging',
  );
  assert.deepEqual(calls, [
    ['getUser', 'owner-uid-123'],
    ['setCustomUserClaims', 'owner-uid-123', {
      existingRole:'admin',
      novaOwner:true,
    }],
  ]);
  assert.equal(result.customClaims.novaOwner, true);
});

test('does not change claims when the fetched Firebase identity is invalid', async () => {
  let setClaimsCalls = 0;
  const auth = {
    async getUser() {
      return {...validUser, email:'attacker@example.com'};
    },
    async setCustomUserClaims() {
      setClaimsCalls += 1;
    },
  };
  await assert.rejects(
    grantNovaOwnerClaim(auth, 'owner-uid-123', 'owner@example.com', 'auren-staging'),
    /UID and expected email must match/,
  );
  assert.equal(setClaimsCalls, 0);
});

test('rejects invalid project and malformed target before any Firebase Auth calls', async () => {
  let calls = 0;
  const auth = {
    async getUser() { calls += 1; return validUser; },
    async setCustomUserClaims() { calls += 1; },
  };
  await assert.rejects(
    grantNovaOwnerClaim(auth, 'owner-uid-123', 'owner@example.com', 'unapproved-project'),
    /explicitly to auren-90ccc or auren-staging/,
  );
  await assert.rejects(
    grantNovaOwnerClaim(auth, 'bad uid', 'owner@example.com', 'auren-staging'),
    /valid Firebase UID/,
  );
  assert.equal(calls, 0);
});
