'use strict';
const {initializeApp} = require('firebase-admin/app');
try { initializeApp({projectId: 'auren-nova-revenue-test'}); } catch (_) {}
const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeNovaRevenuePreferences, novaRevenueUtcDateKey, buildNovaRevenuePrompt} = require('./nova_revenue_engine');

test('normalizes safe revenue-engine preferences and defaults', () => {
  assert.deepEqual(normalizeNovaRevenuePreferences({}), {
    skills: 'AI content writing, short-form video scripts, SEO',
    languages: 'Arabic and English',
    hoursPerDay: 3,
    startingBudgetUsd: 0,
    walletName: 'Trust Wallet',
    walletNetworks: 'multi-chain; verify each chain in Trust Wallet',
  });
});

test('rejects invalid time and starting budget', () => {
  assert.throws(() => normalizeNovaRevenuePreferences({hoursPerDay: 0}), /hoursPerDay/);
  assert.throws(() => normalizeNovaRevenuePreferences({hoursPerDay: 13}), /hoursPerDay/);
  assert.throws(() => normalizeNovaRevenuePreferences({startingBudgetUsd: -1}), /startingBudgetUsd/);
  assert.throws(() => normalizeNovaRevenuePreferences({startingBudgetUsd: 101}), /startingBudgetUsd/);
});

test('uses UTC date keys for idempotent daily runs', () => {
  assert.equal(novaRevenueUtcDateKey(new Date('2026-10-25T23:59:59Z')), '2026-10-25');
  assert.equal(novaRevenueUtcDateKey(new Date('2026-10-26T00:00:00Z')), '2026-10-26');
});

test('prompt requests concrete drafts without false claims or automatic outreach', () => {
  const prompt = buildNovaRevenuePrompt({skills:'copywriting', languages:'Arabic', hoursPerDay:2, startingBudgetUsd:0}, '2026-10-25');
  assert.match(prompt, /not a promise of earnings/i);
  assert.match(prompt, /must not be sent automatically/i);
  assert.match(prompt, /Revenue math/);
  assert.match(prompt, /Starting budget USD: 0/);
  assert.match(prompt, /Airdrop watch/);
  assert.match(prompt, /Trust Wallet/);
  assert.match(prompt, /never sign transactions/i);
  assert.match(prompt, /Social content pack/);
  assert.match(prompt, /Facebook Page\/Reels/);
  assert.match(prompt, /Facebook Professional Dashboard/);
  assert.match(prompt, /\(20\) setup of business profiles/);
  assert.match(prompt, /WhatsApp Business Status/);
});

test('daily revenue prompt includes the 50-platform catalog and $0/Sudan safeguards', () => {
  const prompt = buildNovaRevenuePrompt({hoursPerDay: 2, startingBudgetUsd: 0, languages: 'Arabic'}, '2026-10-26');
  assert.match(prompt, /Candidate platform catalog/);
  assert.match(prompt, /50 options/);
  assert.match(prompt, /Fiverr/);
  assert.match(prompt, /RapidAPI \/ Apify/);
  assert.match(prompt, /Do not assume any platform pays out in Sudan/);
  assert.match(prompt, /exclude any option requiring upfront spend/);
});
