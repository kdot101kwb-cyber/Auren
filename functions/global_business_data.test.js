'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeBusinessRecord,
  businessDocumentId,
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


test('rejects business records with non-HTTPS source URLs', () => {
  assert.throws(() => normalizeBusinessRecord({
    name: 'Sample Supplier',
    countryCode: 'SD',
    businessType: 'supplier',
    source: 'public directory',
    sourceUrl: 'http://example.com/list',
    license: 'terms permit display',
  }), /Business records require/);
});

test('rejects negative trade values and unsupported flow codes', () => {
  assert.equal(normalizeTradeObservation({
    reporterCode: '729',
    partnerCode: '0',
    cmdCode: 'TOTAL',
    flowCode: 'X',
    period: '2024',
    primaryValue: -1,
  }), null);
  assert.equal(normalizeTradeObservation({
    reporterCode: '729',
    partnerCode: '0',
    cmdCode: 'TOTAL',
    flowCode: 'Z',
    period: '2024',
    primaryValue: 1,
  }), null);
});

test('preserves zero as a valid aggregate trade value', () => {
  const row = normalizeTradeObservation({
    reporterCode: '729',
    partnerCode: '0',
    cmdCode: 'TOTAL',
    flowCode: 'M',
    period: '2024',
    primaryValue: 0,
  });
  assert.ok(row);
  assert.equal(row.tradeValue, 0);
});

test('hashes external source record IDs into safe stable Firestore document IDs', () => {
  const base = normalizeBusinessRecord({
    name: 'Sample Supplier',
    countryCode: 'SD',
    businessType: 'supplier',
    source: 'licensed directory',
    sourceUrl: 'https://example.com/suppliers',
    license: 'terms permit display',
    sourceRecordId: '../../unsafe/id',
  });
  const first = businessDocumentId(base);
  assert.match(first, /^[a-f0-9]{40}$/);
  assert.equal(first, businessDocumentId(base));
  assert.notEqual(first, businessDocumentId({...base, businessType: 'manufacturer'}));
});

test('supports official multi-character UN Comtrade trade flow codes', () => {
  for (const flowCode of ['RX', 'RM', 'MIP', 'XIP', 'MOP', 'XOP', 'DX', 'FM']) {
    const row = normalizeTradeObservation({
      reporterCode: '729',
      partnerCode: '0',
      cmdCode: 'TOTAL',
      flowCode,
      period: '2024',
      primaryValue: 10,
    });
    assert.ok(row, `expected ${flowCode} to be accepted`);
    assert.equal(row.flowCode, flowCode);
  }
});

test('does not allow imported source payloads to self-assert verified status', () => {
  const record = normalizeBusinessRecord({
    name: 'Claimed Verified Supplier',
    countryCode: 'SD',
    businessType: 'supplier',
    source: 'public directory',
    sourceUrl: 'https://example.com/suppliers',
    license: 'terms permit display',
    verificationStatus: 'verified',
  });
  assert.equal(record.verificationStatus, 'unverified');
});

test('rejects malformed reporter, partner, and commodity codes', () => {
  const base = {
    reporterCode: '729',
    partnerCode: '0',
    cmdCode: 'TOTAL',
    flowCode: 'X',
    period: '2024',
    primaryValue: 1,
  };
  assert.equal(normalizeTradeObservation({...base, reporterCode: 'SD'}), null);
  assert.equal(normalizeTradeObservation({...base, partnerCode: 'WORLD'}), null);
  assert.equal(normalizeTradeObservation({...base, cmdCode: 'NOT-A-CODE'}), null);
});
