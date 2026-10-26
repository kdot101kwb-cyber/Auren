'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {INCOME_PLATFORMS, formatIncomePlatformCatalog} = require('./nova_income_platform_catalog');

test('catalog contains all 50 numbered candidates without duplicate IDs', () => {
  assert.equal(INCOME_PLATFORMS.length, 50);
  assert.deepEqual(INCOME_PLATFORMS.map((p) => p.id), Array.from({length: 50}, (_, i) => i + 1));
  assert.equal(new Set(INCOME_PLATFORMS.map((p) => p.name)).size, 50);
});

test('catalog flags country/payout verification and non-zero-cost options', () => {
  const text = formatIncomePlatformCatalog();
  assert.match(text, /Fiverr/);
  assert.match(text, /Sudan/);
  assert.match(text, /Shopify/);
  assert.match(text, /not zero-cost/i);
  assert.match(text, /TikTok/);
  assert.match(text, /creator monetization varies by country/i);
});
