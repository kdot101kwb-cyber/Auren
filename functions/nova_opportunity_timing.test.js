'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {evaluateOpportunityTiming} = require('./nova_opportunity_timing');

test('rising multi-source signals recommend validation now, not automatic building', () => {
  const result = evaluateOpportunityTiming({
    recentMentions: 18, previousMentions: 7, githubNewRepositories: 12, trendScore: 64,
  });
  assert.equal(result.decision, 'validate_now');
  assert.equal(result.recheckDays, 2);
  assert.equal(result.buildGate, 'human_approval_and_problem_validation_required');
});

test('missing sources trigger evidence collection rather than a false ranking', () => {
  const result = evaluateOpportunityTiming({
    recentMentions: null, previousMentions: null, githubNewRepositories: 12,
  });
  assert.equal(result.decision, 'collect_more_evidence');
  assert.equal(result.signalCoverage, '1/2');
});

test('weak or falling signals recommend waiting and never promise demand', () => {
  const result = evaluateOpportunityTiming({
    recentMentions: 1, previousMentions: 6, githubNewRepositories: 0,
  });
  assert.equal(result.decision, 'wait_and_recheck');
  assert.match(result.caution, /not proof/);
});
