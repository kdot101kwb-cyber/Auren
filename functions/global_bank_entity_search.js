'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');

const GLEIF_API = 'https://api.gleif.org/api/v1';
const COUNTRY_CODE = /^[A-Z]{2}$/;
const MAX_RESULTS = 10;
const BANK_TERMS = /\b(bank|banking|banco|banque|banca|banco|credit union|savings bank|building society|microfinance bank|islamic bank|central bank|commercial bank|development bank)\b/i;

function normalizeGlobalBankSearch(input) {
  const query = String(input?.query || '').trim().replace(/\s+/g, ' ');
  const countryCode = String(input?.countryCode || '').trim().toUpperCase();
  const limitValue = Number(input?.limit || 10);
  const limit = Number.isFinite(limitValue) ? Math.max(1, Math.min(MAX_RESULTS, Math.floor(limitValue))) : 10;
  if (query.length < 2 || query.length > 120) {
    throw new HttpsError('invalid-argument', 'Enter a bank or financial institution name with 2 to 120 characters.');
  }
  if (countryCode && !COUNTRY_CODE.test(countryCode)) {
    throw new HttpsError('invalid-argument', 'countryCode must be a two-letter ISO country code.');
  }
  return {query, countryCode, limit};
}

function normalizeGlobalBankEntity(record) {
  const attributes = record?.attributes || {};
  const entity = attributes.entity || {};
  const legalAddress = entity.legalAddress || {};
  const headquartersAddress = entity.headquartersAddress || {};
  const registration = attributes.registration || {};
  const legalName = String(entity.legalName?.name || '').trim();
  const lei = String(attributes.lei || record?.id || '').trim();
  if (!legalName || !lei || !BANK_TERMS.test(legalName)) return null;
  const countryCode = String(legalAddress.country || headquartersAddress.country || '').trim().toUpperCase() || null;
  return {
    lei,
    legalName,
    countryCode,
    entityStatus: String(entity.status || '').trim() || null,
    registrationStatus: String(registration.status || '').trim() || null,
    lastUpdateDate: String(registration.lastUpdateDate || '').trim() || null,
    source: 'Global Legal Entity Identifier Foundation (GLEIF)',
    sourceUrl: GLEIF_API + '/lei-records/' + encodeURIComponent(lei),
    institutionType: 'bank_name_match_not_regulatory_classification',
    verificationStatus: 'lei_reference_only_bank_licence_not_confirmed',
  };
}

async function searchGlobalBankEntities(input, fetchImpl = fetch) {
  const filters = normalizeGlobalBankSearch(input);
  const params = new URLSearchParams();
  params.set('filter[entity.legalName]', filters.query);
  if (filters.countryCode) params.set('filter[entity.legalAddress.country]', filters.countryCode);
  params.set('page[size]', String(filters.limit));
  params.set('page[number]', '1');
  const url = GLEIF_API + '/lei-records?' + params.toString();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetchImpl(url, {method: 'GET', headers: {accept: 'application/vnd.api+json, application/json'}, signal: controller.signal});
    if (!response.ok) throw new HttpsError('unavailable', 'Global bank entity search is temporarily unavailable.');
    const payload = await response.json();
    const records = Array.isArray(payload?.data) ? payload.data : [];
    const results = records.map(normalizeGlobalBankEntity).filter(Boolean);
    return {
      status: 'ok',
      query: filters.query,
      countryCode: filters.countryCode || null,
      count: results.length,
      results,
      source: 'GLEIF Global LEI Index',
      sourceUrl: url,
      retrievedAt: new Date().toISOString(),
      coverageNote: 'Global search across legal entities with LEI records whose names match bank-related terms. It is not a complete bank directory; LEI records do not prove a banking licence, deposit protection, solvency, or that the entity offers retail banking. Confirm status with the official national regulator.',
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', 'Could not retrieve global bank entity records. Please try again later.');
  } finally {
    clearTimeout(timeout);
  }
}

exports.aurenSearchGlobalBankEntities = onCall({region: 'us-central1', timeoutSeconds: 20, memory: '256MiB'}, async (request) => {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in to search global bank entities.');
  return searchGlobalBankEntities(request.data || {});
});

module.exports.normalizeGlobalBankSearch = normalizeGlobalBankSearch;
module.exports.normalizeGlobalBankEntity = normalizeGlobalBankEntity;
module.exports.searchGlobalBankEntities = searchGlobalBankEntities;
