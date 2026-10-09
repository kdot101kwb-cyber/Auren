'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');

const GLEIF_API = 'https://api.gleif.org/api/v1';
const MAX_RESULTS = 10;
const COUNTRY_CODE = /^[A-Z]{2}$/;

function normalizeSearchInput(input) {
  const query = String(input?.query || '').trim().replace(/\s+/g, ' ');
  const countryCode = String(input?.countryCode || '').trim().toUpperCase();
  const limitValue = Number(input?.limit || 5);
  const limit = Number.isFinite(limitValue)
    ? Math.max(1, Math.min(MAX_RESULTS, Math.floor(limitValue)))
    : 5;
  if (query.length < 2 || query.length > 120) {
    throw new HttpsError('invalid-argument', 'Enter an entity name with 2 to 120 characters.');
  }
  if (countryCode && !COUNTRY_CODE.test(countryCode)) {
    throw new HttpsError('invalid-argument', 'countryCode must be a two-letter ISO country code.');
  }
  return {query, countryCode, limit};
}

function firstAddressLine(address) {
  if (!address || typeof address !== 'object') return '';
  const lines = Array.isArray(address.addressLines) ? address.addressLines : [];
  return lines.map((line) => String(line || '').trim()).filter(Boolean).join(', ');
}

function normalizeGleifRecord(record) {
  const attributes = record?.attributes || {};
  const entity = attributes.entity || {};
  const legalAddress = entity.legalAddress || {};
  const headquartersAddress = entity.headquartersAddress || {};
  const registration = attributes.registration || {};
  const legalName = String(entity.legalName?.name || '').trim();
  const lei = String(attributes.lei || record?.id || '').trim();
  if (!legalName || !lei) return null;
  return {
    lei,
    legalName,
    entityStatus: String(entity.status || '').trim() || null,
    countryCode: String(legalAddress.country || headquartersAddress.country || '').trim() || null,
    legalAddress: {
      addressLines: firstAddressLine(legalAddress) || null,
      city: String(legalAddress.city || '').trim() || null,
      region: String(legalAddress.region || '').trim() || null,
      postalCode: String(legalAddress.postalCode || '').trim() || null,
      countryCode: String(legalAddress.country || '').trim() || null,
    },
    registrationStatus: String(registration.status || '').trim() || null,
    lastUpdateDate: String(registration.lastUpdateDate || '').trim() || null,
    sourceUrl: 'https://api.gleif.org/api/v1/lei-records/' + encodeURIComponent(lei),
    source: 'Global Legal Entity Identifier Foundation (GLEIF)',
    verificationMeaning: 'GLEIF LEI reference record only; it does not independently prove banking licence, investor activity, solvency, or willingness to fund.',
  };
}

async function searchGleifEntities(input, fetchImpl = fetch) {
  const {query, countryCode, limit} = normalizeSearchInput(input);
  const params = new URLSearchParams();
  params.set('filter[entity.legalName]', query);
  if (countryCode) params.set('filter[entity.legalAddress.country]', countryCode);
  params.set('page[size]', String(limit));
  params.set('page[number]', '1');
  const url = GLEIF_API + '/lei-records?' + params.toString();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetchImpl(url, {
      method: 'GET',
      headers: {accept: 'application/vnd.api+json, application/json'},
      signal: controller.signal,
    });
    if (!response.ok) {
      throw new HttpsError('unavailable', 'GLEIF entity search is temporarily unavailable.');
    }
    const payload = await response.json();
    const records = Array.isArray(payload?.data) ? payload.data : [];
    return {
      status: 'ok',
      query,
      countryCode: countryCode || null,
      count: records.length,
      results: records.map(normalizeGleifRecord).filter(Boolean),
      source: 'Global Legal Entity Identifier Foundation (GLEIF)',
      sourceUrl: url,
      retrievedAt: new Date().toISOString(),
      coverageNote: 'Results include only legal entities with available LEI records matching this search. This is not a complete directory of all banks, investors, or companies in every country.',
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', 'Could not retrieve GLEIF entity records. Please try again later.');
  } finally {
    clearTimeout(timeout);
  }
}

exports.aurenSearchGlobalLegalEntities = onCall({
  region: 'us-central1',
  timeoutSeconds: 20,
  memory: '256MiB',
}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in to search global legal entities.');
  }
  return searchGleifEntities(request.data || {});
});

module.exports.normalizeSearchInput = normalizeSearchInput;
module.exports.normalizeGleifRecord = normalizeGleifRecord;
module.exports.searchGleifEntities = searchGleifEntities;
