'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {PROJECTS, INCOME_EXPERIMENTS, rankIncomeExperiments, rankGithubProjects} = require('./nova_grok_opportunity_radar');

test('income experiments default to zero upfront spend and avoid income guarantees', () => {
  const ranked = rankIncomeExperiments();
  assert.ok(ranked.length > 0);
  assert.ok(ranked.every((item) => item.upfrontCostUsd === 0));
  assert.ok(ranked.every((item) => item.expectedIncome === null));
  assert.ok(ranked.every((item) => item.confidence === 'hypothesis-not-validated'));
});

test('income experiment rank respects time and cost constraints', () => {
  const ranked = rankIncomeExperiments({maxUpfrontCostUsd: 0, availableMinutesPerDay: 45});
  assert.ok(ranked.every((item) => item.firstActionMinutes <= 45));
  assert.ok(ranked.every((item) => item.upfrontCostUsd === 0));
});

test('GitHub radar returns ranked candidates with explicit unverified flags', () => {
  const ranked = rankGithubProjects({priority: 'income'});
  assert.equal(ranked.length, PROJECTS.length);
  assert.ok(ranked.every((item) => item.recommendation === 'candidate-only'));
  assert.ok(ranked.every((item) => item.licenseVerified === false));
  assert.ok(ranked.every((item) => item.testedInNOVA === false));
  assert.equal(ranked[0].id, 'openhands');
});

test('research priority boosts research tools and cost filters are honored', () => {
  const ranked = rankGithubProjects({priority: 'research', maxIntegrationCost: 'medium'});
  assert.ok(ranked.every((item) => item.integrationCost !== 'high'));
  assert.ok(ranked.some((item) => item.id === 'firecrawl'));
});

test('catalog entries have valid GitHub URLs and unique identifiers', () => {
  assert.equal(new Set(PROJECTS.map((item) => item.id)).size, PROJECTS.length);
  assert.ok(PROJECTS.every((item) => item.url.startsWith('https://github.com/')));
  assert.ok(INCOME_EXPERIMENTS.every((item) => item.upfrontCostUsd >= 0));
});
