'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {getDataSourceCatalog, summarizeReadiness} = require('./data_source_catalog');

test('catalog contains unique source IDs and explicit integration status', () => {
  const catalog = getDataSourceCatalog();
  assert.ok(catalog.length >= 8);
  assert.equal(new Set(catalog.map((item) => item.id)).size, catalog.length);
  for (const item of catalog) {
    assert.ok(item.name);
    assert.ok(item.category);
    assert.ok(['implemented', 'catalog_only'].includes(item.integrationStatus));
    assert.ok(Object.hasOwn(item, 'licenseReviewRequired'));
  }
});

test('catalog does not claim catalog-only providers are live integrations', () => {
  const ted = getDataSourceCatalog().find((item) => item.id === 'ted_europe');
  assert.equal(ted.integrationStatus, 'catalog_only');
  assert.match(ted.notes, /no tender records are shown/i);
});

test('readiness is false without a matching ingestion run', () => {
  const results = summarizeReadiness(getDataSourceCatalog(), []);
  assert.ok(results.every((item) => item.dataReady === false));
  assert.ok(results.every((item) => item.latestIngestion === null));
});

test('readiness requires implemented adapter and a source-keyed ingestion run', () => {
  const results = summarizeReadiness(getDataSourceCatalog(), [
    {sourceId: 'un_comtrade', status: 'completed', importedRows: 12, rejectedRows: 0},
    {sourceId: 'ted_europe', status: 'completed', importedRows: 8, rejectedRows: 0},
  ]);
  const comtrade = results.find((item) => item.id === 'un_comtrade');
  const ted = results.find((item) => item.id === 'ted_europe');
  assert.equal(comtrade.dataReady, true);
  assert.equal(comtrade.latestIngestion.importedRows, 12);
  assert.equal(ted.dataReady, false);
});

test('latest run wins when runs are newest-first', () => {
  const results = summarizeReadiness(getDataSourceCatalog(), [
    {sourceId: 'un_comtrade', status: 'failed', importedRows: 0},
    {sourceId: 'un_comtrade', status: 'completed', importedRows: 99},
  ]);
  assert.equal(results.find((item) => item.id === 'un_comtrade').latestIngestion.status, 'failed');
});


test('World Bank country intelligence is an implemented global source', () => {
  const source = getDataSourceCatalog().find((item) => item.id === 'world_bank_wdi');
  assert.ok(source);
  assert.equal(source.integrationStatus, 'implemented');
  for (const kind of ['country_registry', 'population', 'gdp', 'imports', 'exports', 'agriculture']) {
    assert.ok(source.dataKinds.includes(kind));
  }
});

test('readiness recognizes source IDs emitted by the global country ingestion job', () => {
  const results = summarizeReadiness(getDataSourceCatalog(), [
    {source: 'world_bank_wdi', status: 'completed', importedRows: 200},
  ]);
  const worldBank = results.find((item) => item.id === 'world_bank_wdi');
  assert.equal(worldBank.dataReady, true);
  assert.equal(worldBank.latestIngestion.importedRows, 200);
});

test('GLEIF entity search is listed as a live source without overstating verification', () => {
  const source = getDataSourceCatalog().find((item) => item.id === 'gleif_lei_records');
  assert.ok(source);
  assert.equal(source.integrationStatus, 'implemented');
  assert.equal(source.requiresCredentials, false);
  assert.match(source.notes, /does not prove a bank licence/i);
});

test('readiness recognizes GLEIF ingestion runs by source ID', () => {
  const results = summarizeReadiness(getDataSourceCatalog(), [
    {sourceId: 'gleif_lei_records', status: 'completed', importedRows: 5},
  ]);
  const gleif = results.find((item) => item.id === 'gleif_lei_records');
  assert.equal(gleif.dataReady, true);
  assert.equal(gleif.latestIngestion.importedRows, 5);
});
