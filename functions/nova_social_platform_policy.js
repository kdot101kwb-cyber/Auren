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
function canPublishToSocialPlatform(platform, state = {}) {
  const policy = getSocialPlatformPolicy(platform);
  if (!policy) return {allowed:false, reason:'unsupported_platform'};
  if (state.enabled !== true) return {allowed:false, reason:'platform_not_enabled'};
  if (state.adapterConfigured !== true) return {allowed:false, reason:'adapter_not_configured'};
  if (state.authorizationVerified !== true) return {allowed:false, reason:'authorization_not_verified'};
  if (state.publishScopeVerified !== true) return {allowed:false, reason:'publish_scope_not_verified'};
  if (policy.costSensitive && state.costApproved !== true) return {allowed:false, reason:'cost_not_approved'};
  if (state.ownerPolicyApproved !== true) return {allowed:false, reason:'owner_policy_not_approved'};
  return {allowed:true, reason:'ready', platform:normalizePlatform(platform)};
}

module.exports = {
  SOCIAL_PLATFORM_POLICIES,
  normalizePlatform,
  getSocialPlatformPolicy,
  canPublishToSocialPlatform,
};
