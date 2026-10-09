'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { validateCatalog, loadAndValidateAll } = require('./validate_country_source_catalogs');

test('batches 8–12 have valid structure and expected record counts', () => {
  const results = loadAndValidateAll();
  assert.equal(results.length, 5);
  for (const result of results) {
    assert.deepEqual(result.errors, [], `batch ${result.batch}: ${(result.errors || []).join('; ')}`);
    assert.equal(result.count, 50);
  }
});

test('rejects non-HTTPS and duplicate source identifiers', () => {
  const catalog = {
    batch: 8, country_count: 10, source_count: 50,
    countries: Array.from({ length: 10 }, (_, i) => ({ name: `Country ${i}`, iso2: String.fromCharCode(65+i, 65+i) })),
    sources: Array.from({ length: 50 }, (_, i) => ({
      id: i < 2 ? 'duplicate' : `id${i}`, country: 'Country 0', country_code: 'AA',
      category: 'registry', name: `Source ${i}`, url: i === 0 ? 'http://example.com' : `https://example${i}.com`,
      integration_status: 'catalog_only'
    }))
  };
  const errors = validateCatalog(catalog, 8);
  assert.ok(errors.some(e => e.includes('non-HTTPS URL')));
  assert.ok(errors.some(e => e.includes('duplicate source id')));
});

test('allows different source records to share the same official portal URL', () => {
  const catalog = {
    batch: 8, country_count: 10, source_count: 50,
    countries: Array.from({ length: 10 }, (_, i) => ({ name: `Country ${i}`, iso2: String.fromCharCode(65+i, 65+i) })),
    sources: Array.from({ length: 50 }, (_, i) => ({
      id: `id${i}`, country: 'Country 0', country_code: 'AA',
      category: 'registry', name: `Source ${i}`, url: i < 2 ? 'https://example.com/official-portal' : `https://example${i}.com`,
      integration_status: 'catalog_only'
    }))
  };
  assert.deepEqual(validateCatalog(catalog, 8), []);
});
