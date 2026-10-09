'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  FINANCIAL_INDICATORS,
  normalizeCountryCode,
  normalizeIndicatorKeys,
  normalizeWorldBankResponse,
} = require('./world_bank_financial_indicators');

test('accepts ISO-style country codes and rejects unsafe input', () => {
  assert.equal(normalizeCountryCode('sd'), 'SD');
  assert.equal(normalizeCountryCode('USA'), 'USA');
  assert.equal(normalizeCountryCode('../sd'), '');
  assert.equal(normalizeCountryCode(''), '');
});

test('defaults to supported indicators and rejects unknown keys', () => {
  assert.equal(normalizeIndicatorKeys(undefined).length, 4);
  assert.deepEqual(normalizeIndicatorKeys(['account_ownership_adults']), ['account_ownership_adults']);
  assert.equal(normalizeIndicatorKeys(['made_up_indicator']), null);
  assert.equal(normalizeIndicatorKeys(['account_ownership_adults', 'domestic_credit_private_sector_gdp', 'commercial_bank_branches_per_100k', 'domestic_credit_financial_sector_gdp', 'account_ownership_adults']), null);
});

test('normalizes World Bank results with source attribution and no fabricated missing values', () => {
  const result = normalizeWorldBankResponse([
    {page: 1, pages: 1, total: 2},
    [
      {
        indicator: {id: FINANCIAL_INDICATORS.account_ownership_adults.code},
        country: {value: 'Sudan'},
        countryiso3code: 'SDN',
        date: '2021',
        value: 12.5,
        unit: '',
      },
      {
        indicator: {id: FINANCIAL_INDICATORS.account_ownership_adults.code},
        country: {value: 'Sudan'},
        countryiso3code: 'SDN',
        date: '2020',
        value: null,
        unit: '',
      },
    ],
  ], ['account_ownership_adults'], 'SD');
  assert.equal(result.observations.length, 1);
  assert.equal(result.observations[0].countryName, 'Sudan');
  assert.equal(result.observations[0].year, '2021');
  assert.equal(result.observations[0].value, 12.5);
  assert.equal(result.observations[0].sourceName, 'World Bank');
  assert.equal(result.observations[0].verificationStatus, 'source_published_not_independently_verified');
});
