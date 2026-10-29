'use strict';

const VALID_DECISIONS = new Set([
  'validate_now',
  'monitor_and_validate',
  'wait_and_recheck',
  'collect_more_evidence',
]);

/**
 * Convert public trend signals into a cautious timing recommendation.
 * This is a triage rule, not a demand forecast or a revenue prediction.
 */
function evaluateOpportunityTiming(signals = {}) {
  const recent = signals.recentMentions;
  const previous = signals.previousMentions;
  const github = signals.githubNewRepositories;
  const hnAvailable = Number.isFinite(recent) && Number.isFinite(previous);
  const githubAvailable = Number.isFinite(github);
  const availableSources = Number(hnAvailable) + Number(githubAvailable);
  const trendScore = Number.isFinite(signals.trendScore) ? signals.trendScore : null;

  let decision;
  let reason;
  let recheckDays = 3;
  if (availableSources < 2) {
    decision = 'collect_more_evidence';
    reason = 'One or more discovery sources are unavailable. Do not rank this opportunity confidently until evidence is refreshed.';
  } else if (recent >= 5 && recent > previous && github >= 5) {
    decision = 'validate_now';
    reason = 'Both sources returned data, recent discussion volume increased, and related new repositories are present. Validate buyer pain before approving a build.';
    recheckDays = 2;
  } else if (recent >= 3 && recent >= previous && github >= 3) {
    decision = 'monitor_and_validate';
    reason = 'Signals are present but the timing advantage is not strong enough to justify building first. Run a small zero-cost validation test and monitor changes.';
    recheckDays = 3;
  } else {
    decision = 'wait_and_recheck';
    reason = 'Current public signals are weak or declining. Keep the idea in the queue and recheck rather than spending build effort now.';
    recheckDays = 7;
  }

  if (!VALID_DECISIONS.has(decision)) {
    decision = 'collect_more_evidence';
    reason = 'The evidence could not support a safe timing decision.';
  }

  return {
    decision,
    recheckDays,
    signalCoverage: availableSources + '/2',
    trendScore,
    reason,
    buildGate: 'human_approval_and_problem_validation_required',
    caution: 'Public discussion and repository activity are proxies, not proof of paying customers or market demand.',
  };
}

module.exports = {evaluateOpportunityTiming};
