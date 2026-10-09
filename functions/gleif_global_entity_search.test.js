'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {HttpsError} = require('firebase-functions/v2/https');
const {
  normalizeSearchInput,
  normalizeGleifRecord,
  searchGleifEntities,
} = require('./gleif_global_entity_search');

test('validates query, country code, and caps result count', () => {
  assert.deepEqual(normalizeSearchInput({query: '  Example   Bank ', countryCode: 'sd', limit: 999}), {
    query: 'Example Bank', countryCode: 'SD', limit: 10,
  });
  assert.throws(() => normalizeSearchInput({query: 'x'}), (error) => error instanceof HttpsError);
  assert.throws(() => normalizeSearchInput({query: 'Example', countryCode: 'SUD'}), (error) => error instanceof HttpsError);
});

test('normalizes source-backed LEI records without overstating verification', () => {
  const result = normalizeGleifRecord({
    id: '549300EXAMPLE00000001',
    attributes: {
      lei: '549300EXAMPLE00000001',
      entity: {
        legalName: {name: 'Example Bank Ltd'},
        status: 'ACTIVE',
        legalAddress: {addressLines: ['1 Main Street', 'Suite 4'], city: 'Khartoum', country: 'SD'},
      },
      registration: {status: 'ISSUED', lastUpdateDate: '2026-01-01'},
    },
  });
  assert.equal(result.legalName, 'Example Bank Ltd');
  assert.equal(result.countryCode, 'SD');
  assert.equal(result.legalAddress.addressLines, '1 Main Street, Suite 4');
  assert.match(result.verificationMeaning, /does not independently prove banking licence/i);
});

test('search uses GLEIF API, filters country, and skips malformed records', async () => {
  let requestedUrl = '';
  const result = await searchGleifEntities({query: 'Example Bank', countryCode: 'SD', limit: 3}, async (url) => {
    requestedUrl = String(url);
    return {
      ok: true,
      json: async () => ({
        data: [
          {id: '549300EXAMPLE00000001', attributes: {lei: '549300EXAMPLE00000001', entity: {legalName: {name: 'Example Bank'}}}},
          {id: 'invalid', attributes: {entity: {}}},
        ],
      }),
    };
  });
  assert.match(requestedUrl, /api\.gleif\.org\/api\/v1\/lei-records/);
  assert.match(requestedUrl, /filter%5Bentity.legalAddress.country%5D=SD/);
  assert.equal(result.count, 1);
  assert.equal(result.results[0].legalName, 'Example Bank');
  assert.equal(result.countryCode, 'SD');
});
