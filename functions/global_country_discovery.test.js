'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {filterGlobalCountries, normalizeCountry} = require('./global_country_discovery');

const countries = [
  {id: 'SDN', iso2Code: 'SD', name: 'Sudan', capitalCity: 'Khartoum', region: {id: 'SSF', value: 'Sub-Saharan Africa'}, incomeLevel: {id: 'LIC', value: 'Low income'}},
  {id: 'BRA', iso2Code: 'BR', name: 'Brazil', capitalCity: 'Brasilia', region: {id: 'LCN', value: 'Latin America & Caribbean'}, incomeLevel: {id: 'UMC', value: 'Upper middle income'}},
  {id: 'JPN', iso2Code: 'JP', name: 'Japan', capitalCity: 'Tokyo', region: {id: 'EAS', value: 'East Asia & Pacific'}, incomeLevel: {id: 'HIC', value: 'High income'}},
  {id: 'EAS', iso2Code: '', name: 'Aggregates', region: {id: 'NA', value: 'Aggregates'}, incomeLevel: {id: 'NA', value: 'Aggregates'}},
];

test('global country listing includes multiple world regions by default', () => {
  const result = filterGlobalCountries(countries);
  assert.deepEqual(result.map((country) => country.iso2), ['BR', 'JP', 'SD']);
  assert.equal(result.some((country) => country.iso2 === 'SD'), true);
  assert.equal(result.some((country) => country.iso2 === 'BR'), true);
  assert.equal(result.some((country) => country.iso2 === 'JP'), true);
});

test('country code, region, income and text are optional narrowing filters', () => {
  assert.deepEqual(filterGlobalCountries(countries, {countryCode: 'jp'}).map((c) => c.iso2), ['JP']);
  assert.deepEqual(filterGlobalCountries(countries, {region: 'africa'}).map((c) => c.iso2), ['SD']);
  assert.deepEqual(filterGlobalCountries(countries, {incomeLevel: 'high income'}).map((c) => c.iso2), ['JP']);
  assert.deepEqual(filterGlobalCountries(countries, {query: 'tokyo'}).map((c) => c.iso2), ['JP']);
});

test('country directory excludes aggregates and normalizes source provenance', () => {
  const result = filterGlobalCountries(countries);
  assert.ok(result.every((country) => country.region !== 'Aggregates'));
  const japan = result.find((country) => country.iso2 === 'JP');
  assert.equal(japan.source, 'World Bank Country API');
  assert.match(japan.sourceUrl, /api\.worldbank\.org\/v2\/country\/JP/);
});

test('malformed filters are rejected instead of silently narrowing results', () => {
  assert.throws(() => filterGlobalCountries(countries, {countryCode: 'JPN'}), /two-letter ISO/i);
  assert.throws(() => filterGlobalCountries(countries, {query: 'x'.repeat(101)}), /100 characters/i);
  assert.throws(() => filterGlobalCountries(countries, {region: 42}), /must be text/i);
});

test('country normalizer keeps missing metadata explicit', () => {
  const result = normalizeCountry({id: 'XX', name: 'Example', iso2Code: '', region: {value: 'Other'}});
  assert.equal(result.iso2, null);
  assert.equal(result.capitalCity, null);
  assert.equal(result.source, 'World Bank Country API');
});
