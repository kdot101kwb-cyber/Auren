'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  SOCIAL_PLATFORM_POLICIES,
  getSocialPlatformPolicy,
  canPublishToSocialPlatform,
} = require('./nova_social_platform_policy');

test('Facebook and X are explicitly in scope without implying connection', () => {
  assert.equal(getSocialPlatformPolicy('facebook').label, 'Facebook Pages');
  assert.equal(getSocialPlatformPolicy('x').label, 'X');
  assert.equal(getSocialPlatformPolicy('twitter').label, 'X');
  assert.equal(SOCIAL_PLATFORM_POLICIES.facebook.requiresOfficialAdapter, true);
  assert.equal(SOCIAL_PLATFORM_POLICIES.x.requiresOfficialAdapter, true);
});

test('all requested primary and secondary social platforms have policy entries', () => {
  for (const platform of [
    'facebook', 'x', 'instagram', 'tiktok', 'youtube',
    'telegram', 'linkedin', 'pinterest', 'threads',
  ]) {
    assert.ok(getSocialPlatformPolicy(platform), platform + ' should be registered');
  }
});

test('publishing fails closed when any authorization gate is missing', () => {
  const complete = {
    enabled:true,
    adapterConfigured:true,
    authorizationVerified:true,
    publishScopeVerified:true,
    ownerPolicyApproved:true,
    costApproved:true,
  };
  assert.deepEqual(canPublishToSocialPlatform('facebook', {}), {
    allowed:false, reason:'platform_not_enabled',
  });
  assert.deepEqual(canPublishToSocialPlatform('facebook', {
    ...complete, authorizationVerified:false,
  }), {allowed:false, reason:'authorization_not_verified'});
  assert.deepEqual(canPublishToSocialPlatform('facebook', {
    ...complete, publishScopeVerified:false,
  }), {allowed:false, reason:'publish_scope_not_verified'});
  assert.deepEqual(canPublishToSocialPlatform('facebook', complete), {
    allowed:true, reason:'ready', platform:'facebook',
  });
});

test('X publishing remains blocked until cost is explicitly approved', () => {
  const state = {
    enabled:true,
    adapterConfigured:true,
    authorizationVerified:true,
    publishScopeVerified:true,
    ownerPolicyApproved:true,
    costApproved:false,
  };
  assert.deepEqual(canPublishToSocialPlatform('x', state), {
    allowed:false, reason:'cost_not_approved',
  });
  assert.deepEqual(canPublishToSocialPlatform('x', {...state, costApproved:true}), {
    allowed:true, reason:'ready', platform:'x',
  });
});

test('unsupported platforms cannot publish', () => {
  assert.deepEqual(canPublishToSocialPlatform('unknown-network', {
    enabled:true,
    adapterConfigured:true,
    authorizationVerified:true,
    publishScopeVerified:true,
    ownerPolicyApproved:true,
  }), {allowed:false, reason:'unsupported_platform'});
});
