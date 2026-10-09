'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {HttpsError} = require('firebase-functions/v2/https');
const {
  normalizeGrantSearch,
  normalizeGrantOpportunity,
  searchGrantsGov,
} = require('./grants_gov_opportunity_search');

test('validates keyword, bounds page size, and restricts statuses', () => {
  assert.deepEqual(normalizeGrantSearch({keyword: '  climate   resilience ', rows: 999, startRecordNum: -1, oppStatuses: 'posted|nonsense|forecasted'}), {
    keyword: 'climate resilience', rows: 25, startRecordNum: 0, oppStatuses: 'posted|forecasted',
  });
  assert.throws(() => normalizeGrantSearch({keyword: 'x'}), (error) => error instanceof HttpsError);
  assert.throws(() => normalizeGrantSearch({keyword: 'health', oppStatuses: 'invalid'}), (error) => error instanceof HttpsError);
});

test('normalizes a source listing with clear eligibility and geography caveats', () => {
  const result = normalizeGrantOpportunity({
    id: '12345',
    number: 'ABC-2026-01',
    title: 'Community Energy Innovation',
    agencyCode: 'DOE',
    agencyName: 'Department of Energy',
    openDate: '10/01/2026',
    closeDate: '12/01/2026',
    oppStatus: 'posted',
  });
  assert.equal(result.opportunityId, '12345');
  assert.equal(result.status, 'posted');
  assert.match(result.sourceUrl, /ABC-2026-01/);
  assert.match(result.eligibilityNote, /Confirm applicant eligibility/i);
});

test('calls official Grants.gov endpoint and normalizes returned opportunities', async () => {
  let request = null;
  const result = await searchGrantsGov({keyword: 'energy', rows: 5}, async (url, options) => {
    request = {url: String(url), options};
    return {
      ok: true,
      json: async () => ({
        errorcode: 0,
        data: {
          hitCount: 2,
          oppHits: [
            {id: '1', number: 'DOE-1', title: 'Energy Research', agencyName: 'DOE', oppStatus: 'posted'},
            {id: '2', number: 'DOE-2', title: 'Solar Innovation', agencyName: 'DOE', oppStatus: 'forecasted'},
            {id: '3'},
          ],
        },
      }),
    };
  });
  assert.equal(request.url, 'https://api.grants.gov/v1/api/search2');
  assert.equal(request.options.method, 'POST');
  assert.equal(JSON.parse(request.options.body).keyword, 'energy');
  assert.equal(result.count, 2);
  assert.equal(result.totalMatches, 2);
  assert.equal(result.results[0].source, 'Grants.gov');
});
