'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  SOCIAL_PLATFORM_POLICIES,
  getSocialPlatformPolicy,
  canPublishToSocialPlatform,
  getSocialPublishBlockers,
} = require('./nova_social_platform_policy');

const complete = {
  enabled:true,
  adapterConfigured:true,
  authorizationVerified:true,
  publishScopeVerified:true,
  accountScopeVerified:true,
  postApproved:true,
  ownerPolicyApproved:true,
  ownerKillSwitchActive:false,
  contentRightsVerified:true,
  mediaFormatSupported:true,
  rateLimitAvailable:true,
  quotaAvailable:true,
  auditLogReady:true,
  costApproved:true,
};

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

test('every post requires explicit owner approval and a live, unpaused channel', () => {
  assert.deepEqual(canPublishToSocialPlatform('facebook', {
    ...complete, postApproved:false,
  }), {allowed:false, reason:'post_not_approved'});
  assert.deepEqual(canPublishToSocialPlatform('facebook', {
    ...complete, ownerKillSwitchActive:true,
  }), {allowed:false, reason:'publishing_paused_or_kill_switch_unknown'});
  assert.deepEqual(canPublishToSocialPlatform('facebook', {
    ...complete, ownerKillSwitchActive:undefined,
  }), {allowed:false, reason:'publishing_paused_or_kill_switch_unknown'});
});

test('rights, media format, quota, rate limit and audit log must all be verified', () => {
  const cases = [
    ['contentRightsVerified', 'content_rights_not_verified'],
    ['mediaFormatSupported', 'media_format_not_verified'],
    ['rateLimitAvailable', 'rate_limit_not_verified'],
    ['quotaAvailable', 'quota_not_verified'],
    ['auditLogReady', 'audit_log_not_ready'],
    ['accountScopeVerified', 'account_scope_not_verified'],
  ];
  for (const [field, reason] of cases) {
    assert.deepEqual(canPublishToSocialPlatform('instagram', {
      ...complete, [field]:false,
    }), {allowed:false, reason}, field);
  }
});

test('X publishing remains blocked until cost is explicitly approved', () => {
  assert.deepEqual(canPublishToSocialPlatform('x', {
    ...complete, costApproved:false,
  }), {allowed:false, reason:'cost_not_approved'});
  assert.deepEqual(canPublishToSocialPlatform('x', complete), {
    allowed:true, reason:'ready', platform:'x',
  });
});

test('unsupported platforms cannot publish', () => {
  assert.deepEqual(canPublishToSocialPlatform('unknown-network', complete), {
    allowed:false, reason:'unsupported_platform',
  });
});

test('blocker report exposes every missing approval and safety gate', () => {
  const blockers = getSocialPublishBlockers('facebook', {});
  assert.ok(blockers.includes('post_not_approved'));
  assert.ok(blockers.includes('content_rights_not_verified'));
  assert.ok(blockers.includes('quota_not_verified'));
  assert.ok(blockers.includes('audit_log_not_ready'));
  assert.ok(blockers.includes('publishing_paused_or_kill_switch_unknown'));
  assert.deepEqual(getSocialPublishBlockers('facebook', complete), []);
});
