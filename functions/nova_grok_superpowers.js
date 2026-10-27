'use strict';

const MODES = new Set(['chat', 'research', 'coding', 'planning', 'content']);

const COUNCIL = Object.freeze([
  {id: 'strategist', title: 'Strategist', purpose: 'clarify the goal and propose the smallest useful plan'},
  {id: 'skeptic', title: 'Critical Reviewer', purpose: 'look for weak assumptions, missing evidence, and simpler alternatives'},
  {id: 'security', title: 'Safety Reviewer', purpose: 'identify privacy, permission, security, and irreversible-action risks'},
  {id: 'cost', title: 'Cost Guardian', purpose: 'prefer local/free paths and expose costs before external calls'},
]);

const MODE_CHECKS = Object.freeze({
  chat: ['answer the actual question', 'separate known facts from uncertainty'],
  research: ['attach verifiable source URLs for material claims', 'record source date and freshness', 'label unsupported claims as unverified'],
  coding: ['identify exact files and minimal patch', 'run relevant tests and report actual output', 'never claim a build passed without CI evidence'],
  planning: ['compare benefit, time, cost, risk, and measurable outcome', 'define a low-cost first experiment'],
  content: ['check originality and platform requirements', 'separate free/local tools from paid provider calls'],
});

function normalizeSuperpowerOptions(options = {}) {
  const mode = MODES.has(options.mode) ? options.mode : 'chat';
  const networkAvailable = options.networkAvailable !== false;
  const budgetLimitUsd = Number.isFinite(options.budgetLimitUsd) && options.budgetLimitUsd >= 0
    ? options.budgetLimitUsd : null;
  return {mode, networkAvailable, budgetLimitUsd};
}

function buildGrokSuperpowers(options = {}) {
  const normalized = normalizeSuperpowerOptions(options);
  return {
    version: 1,
    mode: normalized.mode,
    council: COUNCIL.map((member) => ({...member})),
    qualityGate: MODE_CHECKS[normalized.mode].slice(),
    evidencePolicy: normalized.mode === 'research'
      ? 'source-backed-claims-only'
      : 'cite-sources-for-time-sensitive-or-material-factual-claims',
    offlineFallback: normalized.networkAvailable
      ? {available: false, reason: 'network is currently marked available; local fallback is not asserted as installed'}
      : {available: true, strategy: 'queue a local draft and use only verified on-device tools; do not claim Grok answered offline'},
    budgetGuard: {
      enabled: true,
      budgetLimitUsd: normalized.budgetLimitUsd,
      behavior: 'block optional paid provider calls when the configured budget is exhausted; require explicit opt-in before paid calls',
      pricingSourceRequired: true,
    },
    executionPolicy: {
      default: 'proposal-only',
      approvalRequiredFor: ['repository writes', 'publishing', 'sending messages', 'account changes', 'purchases', 'investment actions', 'deletion', 'running untrusted code'],
      unconnectedAgentsCanExecute: false,
    },
    memoryPolicy: {
      default: 'ephemeral',
      persistOnlyWithConsent: true,
      neverPersist: ['passwords', 'API keys', 'recovery codes', 'payment secrets'],
    },
  };
}

function evaluateDraft(draft, options = {}) {
  const text = String(draft || '').trim();
  const normalized = normalizeSuperpowerOptions(options);
  const issues = [];
  if (!text) issues.push('empty-draft');
  if (normalized.mode === 'research' && /https?:\/\//i.test(text) === false) issues.push('research-sources-not-detected');
  if (normalized.mode === 'coding' && /test|ci|build/i.test(text) === false) issues.push('verification-plan-not-detected');
  if (/\b(done|completed|passed|deployed)\b/i.test(text) && !options.hasTrustedExecutionEvidence) {
    issues.push('unverified-completion-claim');
  }
  return {ok: issues.length === 0, issues, requiresHumanReview: true};
}

module.exports = {COUNCIL, MODE_CHECKS, buildGrokSuperpowers, evaluateDraft};
