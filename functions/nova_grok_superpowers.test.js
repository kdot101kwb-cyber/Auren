'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {buildGrokSuperpowers, evaluateDraft} = require('./nova_grok_superpowers');

test('builds a four-role challenge council and mode-specific quality gate', () => {
  const result = buildGrokSuperpowers({mode: 'coding'});
  assert.deepEqual(result.council.map((member) => member.id), ['strategist', 'skeptic', 'security', 'cost']);
  assert.ok(result.qualityGate.some((check) => /tests/i.test(check)));
  assert.equal(result.executionPolicy.default, 'proposal-only');
});

test('requires evidence mode sources and offline fallback never pretends Grok ran offline', () => {
  const research = buildGrokSuperpowers({mode: 'research'});
  assert.equal(research.evidencePolicy, 'source-backed-claims-only');
  const offline = buildGrokSuperpowers({mode: 'research', networkAvailable: false});
  assert.equal(offline.offlineFallback.available, true);
  assert.match(offline.offlineFallback.strategy, /do not claim Grok answered offline/);
});

test('budget guard uses configured limit but never invents provider prices', () => {
  const result = buildGrokSuperpowers({budgetLimitUsd: 0});
  assert.equal(result.budgetGuard.budgetLimitUsd, 0);
  assert.equal(result.budgetGuard.pricingSourceRequired, true);
  assert.match(result.budgetGuard.behavior, /block optional paid provider calls/);
});

test('review flags unverified completion claims and missing research sources', () => {
  assert.deepEqual(evaluateDraft('Done, fixed everything', {mode: 'coding'}).issues, ['verification-plan-not-detected', 'unverified-completion-claim']);
  assert.ok(evaluateDraft('A recent market fact', {mode: 'research'}).issues.includes('research-sources-not-detected'));
  assert.equal(evaluateDraft('Tests passed; CI run 123', {mode: 'coding', hasTrustedExecutionEvidence: true}).ok, true);
});

test('sensitive secrets are marked never-persist in memory policy', () => {
  const result = buildGrokSuperpowers();
  assert.ok(result.memoryPolicy.neverPersist.includes('API keys'));
  assert.equal(result.memoryPolicy.persistOnlyWithConsent, true);
});
