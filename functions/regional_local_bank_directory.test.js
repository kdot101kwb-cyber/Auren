'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {HttpsError} = require('firebase-functions/v2/https');
const {normalizeBankSearch, normalizeBankRecord, searchBankDirectory} = require('./regional_local_bank_directory');

test('validates bank search filters and bounds result count', () => {
  assert.deepEqual(normalizeBankSearch({countryCode: 'sd', region: 'africa', institutionType: 'commercial', limit: 500}), {
    countryCode: 'SD', region: 'africa', institutionType: 'commercial', query: '', limit: 50,
  });
  assert.throws(() => normalizeBankSearch({countryCode: 'SUD'}), (e) => e instanceof HttpsError);
  assert.throws(() => normalizeBankSearch({region: 'planet-x'}), (e) => e instanceof HttpsError);
});

test('normalizes records with HTTPS-only official links and explicit verification caveat', () => {
  const bank = normalizeBankRecord('bank-1', {
    name: 'Example Local Bank', countryCode: 'SD', officialWebsite: 'http://unsafe.example',
    regulatorWebsite: 'https://cbos.gov.sd', institutionType: 'commercial', licenseStatus: 'licensed',
  });
  assert.equal(bank.name, 'Example Local Bank');
  assert.equal(bank.officialWebsite, null);
  assert.equal(bank.regulatorWebsite, 'https://cbos.gov.sd/');
  assert.equal(bank.verificationStatus, 'source_record_not_independently_verified');
  assert.equal(normalizeBankRecord('invalid', {name: 'No country'}), null);
});

test('searches only ingested records and applies country, type, and text filters', async () => {
  const docs = [
    {id: '1', data: () => ({name: 'Nile Commercial Bank', countryCode: 'SD', countryName: 'Sudan', region: 'north_africa', institutionType: 'commercial', officialWebsite: 'https://example.com'})},
    {id: '2', data: () => ({name: 'Regional Development Bank', countryCode: 'KE', region: 'east_africa', institutionType: 'development'})},
  ];
  const db = {collection: () => {
    const state = {filters: []};
    const ref = {
      where(field, op, value) { state.filters.push([field, op, value]); return ref; },
      limit() { return {get: async () => ({docs: docs.filter((doc) => state.filters.every(([field,,value]) => doc.data()[field] === value))})}; },
    };
    return ref;
  }};
  const result = await searchBankDirectory({countryCode: 'SD', query: 'nile', institutionType: 'commercial'}, db);
  assert.equal(result.count, 1);
  assert.equal(result.results[0].name, 'Nile Commercial Bank');
  assert.match(result.coverageNote, /official regulator\/bank sources/);
});
