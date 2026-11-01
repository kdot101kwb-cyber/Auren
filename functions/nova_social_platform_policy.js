'use strict';

// Central capability registry for NOVA's social integrations.
// A platform being listed here means "in scope", not connected or publish-ready.
const SOCIAL_PLATFORM_POLICIES = Object.freeze({
  facebook: Object.freeze({label:'Facebook Pages', supportsText:true, supportsImages:true, supportsVideo:true, supportsComments:true, requiresOfficialAdapter:true, costSensitive:false}),
  x: Object.freeze({label:'X', supportsText:true, supportsImages:true, supportsVideo:true, supportsComments:true, requiresOfficialAdapter:true, costSensitive:true}),
  instagram: Object.freeze({label:'Instagram', supportsText:true, supportsImages:true, supportsVideo:true, supportsComments:true, requiresOfficialAdapter:true, costSensitive:false}),
  tiktok: Object.freeze({label:'TikTok', supportsText:true, supportsImages:false, supportsVideo:true, supportsComments:true, requiresOfficialAdapter:true, costSensitive:false}),
  youtube: Object.freeze({label:'YouTube', supportsText:true, supportsImages:true, supportsVideo:true, supportsComments:true, requiresOfficialAdapter:true, costSensitive:false}),
  telegram: Object.freeze({label:'Telegram', supportsText:true, supportsImages:true, supportsVideo:true, supportsComments:false, requiresOfficialAdapter:true, costSensitive:false}),
  linkedin: Object.freeze({label:'LinkedIn', supportsText:true, supportsImages:true, supportsVideo:true, supportsComments:true, requiresOfficialAdapter:true, costSensitive:false}),
  pinterest: Object.freeze({label:'Pinterest', supportsText:true, supportsImages:true, supportsVideo:true, supportsComments:false, requiresOfficialAdapter:true, costSensitive:false}),
  threads: Object.freeze({label:'Threads', supportsText:true, supportsImages:true, supportsVideo:true, supportsComments:true, requiresOfficialAdapter:true, costSensitive:false}),
});

function normalizePlatform(platform) {
  return String(platform || '').trim().toLowerCase().replace(/[\s-]+/g, '_');
}

function getSocialPlatformPolicy(platform) {
  const key = normalizePlatform(platform);
  const aliases = {'twitter':'x', 'facebook_pages':'facebook', 'youtube_shorts':'youtube'};
  return SOCIAL_PLATFORM_POLICIES[aliases[key] || key] || null;
}

/**
 * Fail closed: publishing is allowed only after a real official/authorized
 * adapter is configured, OAuth is verified, publish scope is confirmed, the
 * owner enabled that platform, and any cost gate is satisfied.
 */
function getSocialPublishBlockers(platform, state = {}) {
  const policy = getSocialPlatformPolicy(platform);
  if (!policy) return ['unsupported_platform'];
  const blockers = [];
  if (state.enabled !== true) blockers.push('platform_not_enabled');
  if (state.adapterConfigured !== true) blockers.push('adapter_not_configured');
  if (state.authorizationVerified !== true) blockers.push('authorization_not_verified');
  if (state.publishScopeVerified !== true) blockers.push('publish_scope_not_verified');
  if (state.accountScopeVerified !== true) blockers.push('account_scope_not_verified');
  if (state.postApproved !== true) blockers.push('post_not_approved');
  if (state.ownerPolicyApproved !== true) blockers.push('owner_policy_not_approved');
  if (state.ownerKillSwitchActive !== false) blockers.push('publishing_paused_or_kill_switch_unknown');
  if (state.contentRightsVerified !== true) blockers.push('content_rights_not_verified');
  if (state.mediaFormatSupported !== true) blockers.push('media_format_not_verified');
  if (state.rateLimitAvailable !== true) blockers.push('rate_limit_not_verified');
  if (state.quotaAvailable !== true) blockers.push('quota_not_verified');
  if (state.auditLogReady !== true) blockers.push('audit_log_not_ready');
  if (policy.costSensitive && state.costApproved !== true) blockers.push('cost_not_approved');
  return blockers;
}

/**
 * Fail closed: a post is publishable only after explicit per-post approval,
 * verified account scopes, rights/format checks, quota, audit logging, and
 * an explicitly inactive kill switch, in addition to official OAuth gates.
 */
function canPublishToSocialPlatform(platform, state = {}) {
  const blockers = getSocialPublishBlockers(platform, state);
  if (blockers.length > 0) return {allowed:false, reason:blockers[0]};
  return {allowed:true, reason:'ready', platform:normalizePlatform(platform)};
}

module.exports = {
  SOCIAL_PLATFORM_POLICIES,
  normalizePlatform,
  getSocialPlatformPolicy,
  canPublishToSocialPlatform,
  getSocialPublishBlockers,
};
