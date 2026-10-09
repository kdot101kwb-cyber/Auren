'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeInput, normalizeTradeRecord, searchUNComtrade} = require('./un_comtrade_trade_data');

test('validates required global reporter and period inputs', () => {
  assert.throws(() => normalizeInput({period: '2023'}), /reporterCode/);
  assert.throws(() => normalizeInput({reporterCode: '156', period: '20x3'}), /four-digit year/);
  assert.deepEqual(normalizeInput({reporterCode: '156', period: '2023'}), {
    reporterCode: '156', period: '2023', flowCode: 'X', partnerCode: '0', cmdCode: 'TOTAL', limit: 25,
  });
});

test('validates supported trade flows and caps requested result size', () => {
  assert.throws(() => normalizeInput({reporterCode: '156', period: '2023', flowCode: 'bad'}), /flowCode/);
  assert.equal(normalizeInput({reporterCode: '156', period: '2023', flowCode: 'RX', limit: 999}).limit, 100);
});

test('normalizes official trade statistics with provenance', () => {
  const row = normalizeTradeRecord({reporterCode: 156, reporterDesc: 'China', partnerCode: 0, partnerDesc: 'World', cmdCode: 'TOTAL', cmdDesc: 'All Commodities', flowCode: 'X', flowDesc: 'Export', period: 2023, primaryValue: 1234});
  assert.equal(row.reporter, 'China');
  assert.equal(row.tradeValueUsd, 1234);
  assert.equal(row.source, 'United Nations Statistics Division — UN Comtrade');
  assert.equal(row.verificationStatus, 'official_reported_trade_statistics_not_company_verification');
});

test('calls the public preview endpoint with filters and returns normalized rows', async () => {
  let requestedUrl = '';
  const result = await searchUNComtrade({reporterCode: '156', period: '2023', flowCode: 'X'}, {
    fetchImpl: async (url) => {
      requestedUrl = url;
      return {ok: true, status: 200, json: async () => ({count: 1, data: [{reporterCode: 156, reporterDesc: 'China', partnerCode: 0, partnerDesc: 'World', cmdCode: 'TOTAL', cmdDesc: 'All Commodities', flowCode: 'X', flowDesc: 'Export', period: 2023, primaryValue: 100}]})};
    },
  });
  assert.match(requestedUrl, /reportercode=156/);
  assert.match(requestedUrl, /period=2023/);
  assert.match(requestedUrl, /includeDesc=true/);
  assert.equal(result.count, 1);
  assert.equal(result.results[0].reporter, 'China');
});
