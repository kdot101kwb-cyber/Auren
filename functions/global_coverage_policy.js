'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');

const GLOBAL_COVERAGE_DOMAINS = Object.freeze([
  'banks_and_finance',
  'businesses_and_manufacturers',
  'suppliers_exporters_importers',
  'investors_and_funding',
  'grants_and_opportunities',
  'jobs_and_education',
  'trade_and_markets',
  'travel_and_local_services',
  'health_and_accessibility',
  'content_and_communities',
]);

/**
 * Geographic scope is global unless the user explicitly chooses a country
 * or region. Never infer Sudan, Africa, or the device location as a filter.
 * This normalizes requested scope only; it does not imply complete source data.
 */
function normalizeGlobalScope(input = {}) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new TypeError('scope must be an object');
  }

  const requestedScope = String(input.scope || '').trim().toLowerCase();
  const rawCountry = String(input.countryCode || '').trim();
  const rawRegion = String(input.region || '').trim();

  if (rawCountry && !/^[a-z]{2}$/i.test(rawCountry)) {
    throw new TypeError('countryCode must be a two-letter ISO country code');
  }
  if (rawRegion.length > 80) {
    throw new TypeError('region must be 80 characters or fewer');
  }
  if (requestedScope && !['global', 'country', 'region'].includes(requestedScope)) {
    throw new TypeError('scope must be global, country, or region');
  }

  if (requestedScope === 'country' && !rawCountry) {
    throw new TypeError('countryCode is required for country scope');
  }
  if (requestedScope === 'region' && !rawRegion) {
    throw new TypeError('region is required for region scope');
  }

  // An explicit country or region narrows results; otherwise remain global.
  const scope = requestedScope || (rawRegion ? 'region' : rawCountry ? 'country' : 'global');
  if (scope === 'global') {
    return Object.freeze({scope: 'global', countryCode: null, region: null, includeGlobal: true});
  }
  if (scope === 'country') {
    return Object.freeze({
      scope: 'country',
      countryCode: rawCountry.toUpperCase(),
      region: rawRegion || null,
      includeGlobal: true,
    });
  }
  return Object.freeze({
    scope: 'region',
    countryCode: rawCountry ? rawCountry.toUpperCase() : null,
    region: rawRegion,
    includeGlobal: true,
  });
}

function getGlobalCoveragePolicy(input = {}) {
  return {
    status: 'ok',
    defaultScope: 'global',
    scope: normalizeGlobalScope(input),
    supportedDomains: [...GLOBAL_COVERAGE_DOMAINS],
    principles: [
      'Country and region are optional user-selected narrowing filters.',
      'Do not silently default to Sudan, Africa, device location, or a single provider region.',
      'Global scope means search across all available connected sources; it does not promise complete world coverage.',
      'Show source, last-checked date, availability, eligibility, and verification status when applicable.',
      'Never present an empty result as proof that no matching entity or opportunity exists.',
      'Use official regulator sources to verify licences; a legal-entity record alone is not proof of a licence.',
    ],
  };
}

exports.aurenGlobalCoveragePolicy = onCall(
  {region: 'us-central1', timeoutSeconds: 15, memory: '128MiB'},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in to view AUREN global coverage policy.');
    }
    let input;
    try {
      input = normalizeGlobalScope(request.data || {});
    } catch (error) {
      throw new HttpsError('invalid-argument', error.message);
    }
    return getGlobalCoveragePolicy(input);
  },
);

module.exports.normalizeGlobalScope = normalizeGlobalScope;
module.exports.getGlobalCoveragePolicy = getGlobalCoveragePolicy;
module.exports.GLOBAL_COVERAGE_DOMAINS = GLOBAL_COVERAGE_DOMAINS;
