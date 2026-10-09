'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeGlobalScope,
  getGlobalCoveragePolicy,
  GLOBAL_COVERAGE_DOMAINS,
} = require('./global_coverage_policy');

test('global is the default and does not infer Sudan or Africa', () => {
  assert.deepEqual(normalizeGlobalScope(), {
    scope: 'global', countryCode: null, region: null, includeGlobal: true,
  });
  assert.deepEqual(normalizeGlobalScope({}), normalizeGlobalScope());
});

test('explicit country narrows scope and normalizes ISO country code', () => {
  assert.deepEqual(normalizeGlobalScope({countryCode: 'sd'}), {
    scope: 'country', countryCode: 'SD', region: null, includeGlobal: true,
  });
});

test('explicit region narrows scope without requiring a country', () => {
  assert.deepEqual(normalizeGlobalScope({region: 'West Africa'}), {
    scope: 'region', countryCode: null, region: 'West Africa', includeGlobal: true,
  });
});

test('region can be narrowed further by an explicitly selected country', () => {
  assert.deepEqual(normalizeGlobalScope({scope: 'region', countryCode: 'ke', region: 'East Africa'}), {
    scope: 'region', countryCode: 'KE', region: 'East Africa', includeGlobal: true,
  });
});

test('invalid scope and malformed country codes are rejected', () => {
  assert.throws(() => normalizeGlobalScope({scope: 'continent'}), /scope must be global/i);
  assert.throws(() => normalizeGlobalScope({countryCode: 'SUD'}), /two-letter ISO/i);
  assert.throws(() => normalizeGlobalScope({scope: 'country'}), /countryCode is required/i);
  assert.throws(() => normalizeGlobalScope({scope: 'region'}), /region is required/i);
});

test('policy identifies global-by-default domains and warns that coverage is source-dependent', () => {
  const policy = getGlobalCoveragePolicy();
  assert.equal(policy.defaultScope, 'global');
  assert.equal(policy.scope.scope, 'global');
  assert.ok(GLOBAL_COVERAGE_DOMAINS.includes('banks_and_finance'));
  assert.ok(GLOBAL_COVERAGE_DOMAINS.includes('suppliers_exporters_importers'));
  assert.ok(policy.principles.some((line) => /does not promise complete world coverage/i.test(line)));
  assert.ok(policy.principles.some((line) => /empty result/i.test(line)));
});
