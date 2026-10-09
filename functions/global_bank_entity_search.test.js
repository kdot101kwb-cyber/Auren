'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {HttpsError} = require('firebase-functions/v2/https');
const {normalizeGlobalBankSearch, normalizeGlobalBankEntity, searchGlobalBankEntities} = require('./global_bank_entity_search');

test('validates global bank search input and country filter', () => {
  assert.deepEqual(normalizeGlobalBankSearch({query: '  Bank of Africa ', countryCode: 'sd', limit: 99}), {query: 'Bank of Africa', countryCode: 'SD', limit: 10});
  assert.throws(() => normalizeGlobalBankSearch({query: 'x'}), (error) => error instanceof HttpsError);
  assert.throws(() => normalizeGlobalBankSearch({query: 'Bank', countryCode: 'SUD'}), (error) => error instanceof HttpsError);
});

test('keeps bank-name matching separate from licence verification', () => {
  const bank = normalizeGlobalBankEntity({id: 'LEI-1', attributes: {lei: 'LEI-1', entity: {legalName: {name: 'Example Commercial Bank'}, legalAddress: {country: 'SD', city: 'Khartoum'}, status: 'ACTIVE'}, registration: {status: 'ISSUED'}}});
  assert.equal(bank.legalName, 'Example Commercial Bank');
  assert.equal(bank.countryCode, 'SD');
  assert.equal(bank.verificationStatus, 'lei_reference_only_bank_licence_not_confirmed');
  assert.equal(normalizeGlobalBankEntity({id: 'LEI-2', attributes: {lei: 'LEI-2', entity: {legalName: {name: 'Example Software Company'}}}}), null);
});

test('queries official GLEIF API and returns matching global bank entities', async () => {
  let requestedUrl = '';
  const result = await searchGlobalBankEntities({query: 'Bank of Africa', countryCode: 'SD'}, async (url) => {
    requestedUrl = String(url);
    return {ok: true, json: async () => ({data: [
      {id: '1', attributes: {lei: '1', entity: {legalName: {name: 'Bank of Africa Limited'}, legalAddress: {country: 'SD'}}}},
      {id: '2', attributes: {lei: '2', entity: {legalName: {name: 'Africa Technology Limited'}}}},
    ]})};
  });
  assert.match(requestedUrl, /api\.gleif\.org\/api\/v1\/lei-records/);
  assert.match(requestedUrl, /filter%5Bentity.legalAddress.country%5D=SD/);
  assert.equal(result.count, 1);
  assert.equal(result.results[0].countryCode, 'SD');
  assert.match(result.coverageNote, /not a complete bank directory/i);
});
