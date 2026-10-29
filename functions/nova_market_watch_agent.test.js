'use strict';

const {initializeApp} = require('firebase-admin/app');
try { initializeApp({projectId: 'nova-market-watch-test'}); } catch (_) {}
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  scoreNovaMarketGrowthForTest,
  buildNovaMarketPackForTest,
  novaMarketWatchThemesForTest,
} = require('./nova_market_watch_agent');

test('market watch covers app building, offline mobile, creators, developer tools and local business', () => {
  const themes = novaMarketWatchThemesForTest;
  assert.ok(themes.length >= 6);
  assert.equal(new Set(themes.map((x) => x.id)).size, themes.length);
  for (const theme of themes) {
    assert.ok(theme.idea.length > 30);
    assert.ok(theme.mvp.length >= 3);
    assert.ok(theme.validation.length > 30);
  }
});

test('growth scoring rewards rising signals and returns null when evidence is missing', () => {
  assert.ok(scoreNovaMarketGrowthForTest(10, 25) > scoreNovaMarketGrowthForTest(25, 10));
  assert.equal(scoreNovaMarketGrowthForTest(null, 20), null);
  assert.equal(scoreNovaMarketGrowthForTest(20, null), null);
});

test('build pack is actionable but never claims the app is already built', () => {
  const theme = novaMarketWatchThemesForTest[0];
  const pack = buildNovaMarketPackForTest(theme, {
    recentMentions: 20,
    previousMentions: 10,
    githubNewRepositories: 30,
    githubExamples: [],
  }, '2026-10-29T08:40:00.000Z');
  assert.equal(pack.status, 'research_pack_ready');
  assert.equal(pack.notYetBuilt, true);
  assert.ok(pack.mvpScope.length >= 3);
  assert.ok(pack.acceptanceCriteria.length >= 4);
  assert.match(pack.disclaimer, /not a validated business/);
  assert.ok(pack.readinessChecklist.some((x) => x.includes('tests')));
});

test('missing source data is labelled incomplete rather than invented', () => {
  const pack = buildNovaMarketPackForTest(novaMarketWatchThemesForTest[0], {
    recentMentions: null,
    previousMentions: null,
    githubNewRepositories: null,
  }, '2026-10-29T08:40:00.000Z');
  assert.equal(pack.evidenceConfidence, 'incomplete');
  assert.ok(pack.evidenceSummary.some((x) => x.includes('unavailable')));
});

test('timing policy asks for more evidence when either source is unavailable', () => {
  const {evaluateNovaOpportunityTimingForTest} = require('./nova_market_watch_agent');
  const hnMissing = evaluateNovaOpportunityTimingForTest({
    recentMentions: null,
    previousMentions: null,
    githubNewRepositories: 14,
  });
  assert.equal(hnMissing.decision, 'collect_more_evidence');
  assert.equal(hnMissing.buildGate, 'human_approval_and_problem_validation_required');

  const githubMissing = evaluateNovaOpportunityTimingForTest({
    recentMentions: 20,
    previousMentions: 8,
    githubNewRepositories: null,
  });
  assert.equal(githubMissing.decision, 'collect_more_evidence');
  assert.match(githubMissing.caution, /not proof/);
});
