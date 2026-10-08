'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeBusinessRecord,
  normalizeTradeObservation,
} = require('./global_business_data');

test('normalizes business records with provenance and safe verification defaults', () => {
  const record = normalizeBusinessRecord({
    companyName: '  Nile Foods  ',
    countryCode: 'sd',
    type: 'exporter',
    source: 'official trade directory',
    sourceUrl: 'https://example.gov.sd/exporters',
    license: 'public directory terms permit display',
    products: ['sesame', ' sesame ', '', 'gum arabic'],
  });
  assert.equal(record.name, 'Nile Foods');
  assert.equal(record.countryCode, 'SD');
  assert.equal(record.businessType, 'exporter');
  assert.equal(record.verificationStatus, 'unverified');
  assert.deepEqual(record.products, ['sesame', 'gum arabic']);
  assert.equal(record.source, 'official trade directory');
  assert.ok(record.lastCheckedAt);
});

test('rejects business records without source and licence provenance', () => {
  assert.throws(() => normalizeBusinessRecord({
    name: 'Unknown Company',
    countryCode: 'SD',
    businessType: 'importer',
  }), /Business records require/);
});

test('normalizes aggregate trade statistics without mislabeling them as company leads', () => {
  const row = normalizeTradeObservation({
    reporterCode: '729',
    partnerCode: '0',
    cmdCode: 'TOTAL',
    flowCode: 'X',
    period: '2024',
    primaryValue: 123456,
  });
  assert.equal(row.tradeValue, 123456);
  assert.equal(row.dataKind, 'aggregate_trade_statistics');
  assert.equal(row.isCompanyLead, false);
  assert.equal(row.source, 'UN Comtrade');
});

test('rejects malformed aggregate trade rows', () => {
  assert.equal(normalizeTradeObservation({reporterCode: '729', flowCode: 'X', period: '20', primaryValue: 3}), null);
});
