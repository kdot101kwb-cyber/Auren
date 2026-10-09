'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeInput,
  normalizeBusinessHit,
  BUSINESS_COLLECTIONS,
} = require('./global_business_directory_search');

test('global business search defaults to all supported business types and no country', () => {
  const input = normalizeInput({});
  assert.equal(input.countryCode, '');
  assert.equal(input.businessType, '');
  assert.deepEqual(Object.keys(BUSINESS_COLLECTIONS), ['supplier', 'exporter', 'importer', 'manufacturer']);
});

test('country and business type are optional narrowing filters', () => {
  assert.deepEqual(normalizeInput({countryCode: 'ke', businessType: 'manufacturer'}), {
    query: '', countryCode: 'KE', businessType: 'manufacturer', limit: 20,
  });
});

test('rejects invalid country codes and unknown business types', () => {
  assert.throws(() => normalizeInput({countryCode: 'KEN'}), /two-letter ISO/i);
  assert.throws(() => normalizeInput({businessType: 'investor'}), /businessType must be/i);
});

test('query length and result limit are bounded', () => {
  assert.throws(() => normalizeInput({query: 'x'.repeat(101)}), /100 characters/i);
  assert.equal(normalizeInput({limit: 999}).limit, 50);
  assert.equal(normalizeInput({limit: 0}).limit, 1);
});

test('normalizes business records with explicit source and verification status', () => {
  const hit = normalizeBusinessHit({
    id: 'record-1',
    data: () => ({
      name: 'Example Manufacturing Ltd',
      countryCode: 'KE',
      businessType: 'manufacturer',
      products: ['tea', 'packaging'],
      source: 'Official company register',
      sourceUrl: 'https://example.gov/record/1',
      sourceLicense: 'public-register-terms',
      provenanceStatus: 'provided',
      verificationStatus: 'unverified',
    }),
  }, 'manufacturer');
  assert.equal(hit.name, 'Example Manufacturing Ltd');
  assert.equal(hit.countryCode, 'KE');
  assert.equal(hit.verificationStatus, 'unverified');
  assert.equal(hit.sourceUrl, 'https://example.gov/record/1');
});
