'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore} = require('firebase-admin/firestore');

const BANK_COLLECTION = 'auren_banking_institutions';
const COUNTRY_CODE = /^[A-Z]{2}$/;
const REGIONS = new Set(['africa', 'east_africa', 'west_africa', 'central_africa', 'southern_africa', 'north_africa', 'middle_east', 'europe', 'asia', 'south_asia', 'east_asia', 'southeast_asia', 'north_america', 'latin_america', 'caribbean', 'oceania', 'global']);
const TYPES = new Set(['commercial', 'microfinance', 'cooperative', 'islamic', 'development', 'savings', 'central_bank', 'regional_bank', 'digital_bank', 'other']);

function normalizeBankSearch(input) {
  const countryCode = String(input?.countryCode || '').trim().toUpperCase();
  const region = String(input?.region || '').trim().toLowerCase();
  const institutionType = String(input?.institutionType || '').trim().toLowerCase();
  const query = String(input?.query || '').trim().replace(/\s+/g, ' ').slice(0, 100);
  const limitValue = Number(input?.limit || 20);
  const limit = Number.isFinite(limitValue) ? Math.max(1, Math.min(50, Math.floor(limitValue))) : 20;
  if (countryCode && !COUNTRY_CODE.test(countryCode)) {
    throw new HttpsError('invalid-argument', 'countryCode must be a two-letter ISO country code.');
  }
  if (region && !REGIONS.has(region)) throw new HttpsError('invalid-argument', 'Unsupported region filter.');
  if (institutionType && !TYPES.has(institutionType)) throw new HttpsError('invalid-argument', 'Unsupported bank type filter.');
  return {countryCode, region, institutionType, query, limit};
}

function normalizeBankRecord(id, data) {
  const name = String(data?.name || '').trim();
  const countryCode = String(data?.countryCode || '').trim().toUpperCase();
  const officialWebsite = String(data?.officialWebsite || '').trim();
  if (!name || !COUNTRY_CODE.test(countryCode)) return null;
  let website = null;
  try {
    const parsed = new URL(officialWebsite);
    if (parsed.protocol === 'https:') website = parsed.toString();
  } catch (_) {}
  return {
    id,
    name,
    countryCode,
    countryName: String(data.countryName || '').trim() || null,
    region: REGIONS.has(String(data.region || '').trim().toLowerCase()) ? String(data.region).trim().toLowerCase() : null,
    institutionType: TYPES.has(String(data.institutionType || '').trim().toLowerCase()) ? String(data.institutionType).trim().toLowerCase() : 'other',
    officialWebsite: website,
    regulatorName: String(data.regulatorName || '').trim() || null,
    regulatorWebsite: normalizeHttpsUrl(data.regulatorWebsite),
    sourceName: String(data.sourceName || '').trim() || null,
    sourceUrl: normalizeHttpsUrl(data.sourceUrl),
    licenseStatus: ['licensed', 'unconfirmed', 'revoked', 'unknown'].includes(String(data.licenseStatus || '').toLowerCase()) ? String(data.licenseStatus).toLowerCase() : 'unknown',
    verificationStatus: 'source_record_not_independently_verified',
    lastVerifiedAt: data.lastVerifiedAt || null,
  };
}

function normalizeHttpsUrl(value) {
  try {
    const url = new URL(String(value || '').trim());
    return url.protocol === 'https:' ? url.toString() : null;
  } catch (_) {
    return null;
  }
}

async function searchBankDirectory(input, db = getFirestore()) {
  const filters = normalizeBankSearch(input);
  let query = db.collection(BANK_COLLECTION);
  if (filters.countryCode) query = query.where('countryCode', '==', filters.countryCode);
  if (filters.region) query = query.where('region', '==', filters.region);
  if (filters.institutionType) query = query.where('institutionType', '==', filters.institutionType);
  const snapshot = await query.limit(Math.min(250, filters.limit * 5)).get();
  const q = filters.query.toLowerCase();
  const results = snapshot.docs
    .map((doc) => normalizeBankRecord(doc.id, doc.data()))
    .filter(Boolean)
    .filter((bank) => !q || [bank.name, bank.countryName, bank.countryCode, bank.regulatorName, bank.institutionType].some((value) => String(value || '').toLowerCase().includes(q)))
    .slice(0, filters.limit);
  return {
    status: 'ok',
    count: results.length,
    filters,
    results,
    sourceCollection: BANK_COLLECTION,
    coverageNote: 'Regional and local bank records appear only after ingestion from official regulator/bank sources with provenance. Missing records do not mean a country has no banks. Listing is not a banking licence or creditworthiness guarantee.',
    retrievedAt: new Date().toISOString(),
  };
}

exports.aurenSearchRegionalLocalBanks = onCall({
  region: 'us-central1',
  timeoutSeconds: 15,
  memory: '256MiB',
}, async (request) => {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in to search banks.');
  return searchBankDirectory(request.data || {});
});

module.exports.normalizeBankSearch = normalizeBankSearch;
module.exports.normalizeBankRecord = normalizeBankRecord;
module.exports.searchBankDirectory = searchBankDirectory;
