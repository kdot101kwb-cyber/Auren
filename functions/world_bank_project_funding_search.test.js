'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {HttpsError} = require('firebase-functions/v2/https');
const {
  normalizeProjectSearch,
  normalizeWorldBankProject,
  searchWorldBankProjects,
} = require('./world_bank_project_funding_search');

test('validates country and bounds pagination and result size', () => {
  assert.deepEqual(normalizeProjectSearch({countryCode: 'sd', query: '  water   supply ', page: 0, limit: 999}), {
    countryCode: 'SD', query: 'water supply', page: 1, limit: 25,
  });
  assert.throws(() => normalizeProjectSearch({countryCode: 'SUD'}), (error) => error instanceof HttpsError);
});

test('normalizes source-backed project data and describes funding limitations', () => {
  const result = normalizeWorldBankProject({
    id: 'P123456',
    project_name: 'Example Water Project',
    countrycode: 'SD',
    countryname: 'Sudan',
    status: 'Active',
    boardapprovaldate: '2025-01-01',
    totalamt: 1200000,
    url: 'https://projects.worldbank.org/en/projects-operations/project-detail/P123456',
  });
  assert.equal(result.name, 'Example Water Project');
  assert.equal(result.financingAmount, 1200000);
  assert.equal(result.source, 'World Bank Projects & Operations');
  assert.match(result.fundingNote, /not an open grant/i);
});

test('queries official country projects endpoint and filters results safely', async () => {
  let requestedUrl = '';
  const result = await searchWorldBankProjects({countryCode: 'SD', query: 'water', limit: 5}, async (url) => {
    requestedUrl = String(url);
    return {
      ok: true,
      json: async () => [
        {page: 1, pages: 2, total: 40},
        [
          {id: 'P1', project_name: 'Water Supply Project', countrycode: 'SD', totalamt: '1000'},
          {id: 'P2', project_name: 'Road Project', countrycode: 'SD'},
          {id: 'P3'},
        ],
      ],
    };
  });
  assert.match(requestedUrl, /api\.worldbank\.org\/v2\/country\/SD\/projects/);
  assert.equal(result.pageCount, 2);
  assert.equal(result.sourceRecordCount, 40);
  assert.equal(result.count, 1);
  assert.equal(result.results[0].projectId, 'P1');
});
