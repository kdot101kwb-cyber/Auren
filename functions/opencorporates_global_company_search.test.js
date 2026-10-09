'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {HttpsError} = require('firebase-functions/v2/https');
const {
  normalizeSearchInput,
  normalizeCompanyResult,
  searchOpenCorporatesCompanies,
} = require('./opencorporates_global_company_search');

test('global company search requires a useful query and validates optional country', () => {
  assert.throws(() => normalizeSearchInput({query: 'x'}), /between 2 and 100/i);
  assert.throws(() => normalizeSearchInput({query: 'company', countryCode: 'KEN'}), /two-letter ISO/i);
  assert.deepEqual(normalizeSearchInput({query: '  textile   group  ', limit: 100}), {
    query: 'textile group', countryCode: '', limit: 25,
  });
});

test('normalizes company registry results with provenance and caution', () => {
  const hit = normalizeCompanyResult({company: {
    name: 'Example Textile Ltd',
    company_number: '12345',
    jurisdiction_code: 'gb',
    current_status: 'Active',
    registered_address_in_full: 'London, UK',
    opencorporates_url: 'https://opencorporates.com/companies/gb/12345',
  }});
  assert.equal(hit.name, 'Example Textile Ltd');
  assert.equal(hit.jurisdictionCode, 'gb');
  assert.equal(hit.verificationStatus, 'registry_record_not_independently_verified');
  assert.match(hit.licenceNote, /not proof/i);
});

test('fails clearly when the API token is not configured', async () => {
  await assert.rejects(
    searchOpenCorporatesCompanies({query: 'textile'}, {apiToken: ''}),
    (error) => error instanceof HttpsError && error.code === 'failed-precondition',
  );
});

test('calls OpenCorporates globally and normalizes returned companies', async () => {
  let requestedUrl;
  let requestedHeaders;
  const result = await searchOpenCorporatesCompanies({query: 'textile group', limit: 5}, {
    apiToken: 'test-token',
    fetchImpl: async (url, options) => {
      requestedUrl = new URL(url);
      requestedHeaders = options.headers;
      return {
        ok: true,
        status: 200,
        json: async () => ({results: {
          companies: [{company: {
            name: 'Example Textile Group', jurisdiction_code: 'gb',
            opencorporates_url: 'https://opencorporates.com/companies/gb/123',
          }}],
          total_count: 125,
          page: {current_page: 1},
        }}),
      };
    },
  });
  assert.equal(requestedUrl.searchParams.get('q'), 'textile group');
  assert.equal(requestedUrl.searchParams.has('jurisdiction_code'), false);
  assert.equal(requestedHeaders['X-API-TOKEN'], 'test-token');
  assert.equal(result.scope, 'global');
  assert.equal(result.totalCount, 125);
  assert.equal(result.results[0].name, 'Example Textile Group');
});

test('optional country filter narrows returned jurisdictions', async () => {
  const result = await searchOpenCorporatesCompanies({query: 'manufacturer', countryCode: 'GB'}, {
    apiToken: 'test-token',
    fetchImpl: async () => ({
      ok: true, status: 200,
      json: async () => ({results: {companies: [
        {company: {name: 'UK Maker', jurisdiction_code: 'gb'}},
        {company: {name: 'US Maker', jurisdiction_code: 'us_de'}},
      ]}}),
    }),
  });
  assert.deepEqual(result.results.map((company) => company.name), ['UK Maker']);
  assert.equal(result.scope, 'country');
});
