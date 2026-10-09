'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');

const OPENCORPORATES_API_TOKEN = defineSecret('OPENCORPORATES_API_TOKEN');
const API_BASE = 'https://api.opencorporates.com/v0.4/companies/search';
const MAX_RESULTS = 25;

function normalizeSearchInput(input = {}) {
  const query = typeof input.query === 'string' ? input.query.trim().replace(/\s+/g, ' ') : '';
  const countryCode = typeof input.countryCode === 'string' ? input.countryCode.trim().toUpperCase() : '';
  const limitValue = Number(input.limit ?? 10);
  const limit = Number.isFinite(limitValue) ? Math.max(1, Math.min(MAX_RESULTS, Math.floor(limitValue))) : 10;
  if (query.length < 2 || query.length > 100) {
    throw new HttpsError('invalid-argument', 'query must be between 2 and 100 characters.');
  }
  if (countryCode && !/^[A-Z]{2}$/.test(countryCode)) {
    throw new HttpsError('invalid-argument', 'countryCode must be a two-letter ISO country code.');
  }
  return {query, countryCode, limit};
}

function normalizeCompanyResult(item) {
  const company = item?.company || item;
  if (!company || typeof company !== 'object' || !company.name) return null;
  const address = company.registered_address || {};
  const jurisdictionCode = String(company.jurisdiction_code || '').trim().toLowerCase() || null;
  return {
    name: String(company.name).trim(),
    companyNumber: String(company.company_number || '').trim() || null,
    jurisdictionCode,
    companyType: String(company.company_type || '').trim() || null,
    currentStatus: String(company.current_status || '').trim() || null,
    incorporationDate: String(company.incorporation_date || '').trim() || null,
    dissolutionDate: String(company.dissolution_date || '').trim() || null,
    registeredAddress: String(company.registered_address_in_full || address.in_full || '').trim() || null,
    registryUrl: String(company.registry_url || '').trim() || null,
    opencorporatesUrl: String(company.opencorporates_url || '').trim() || null,
    source: 'OpenCorporates',
    sourceUrl: String(company.opencorporates_url || '').trim() || null,
    provenanceStatus: 'aggregated_public_registry_data',
    verificationStatus: 'registry_record_not_independently_verified',
    licenceNote: 'Company registry listing is not proof of current operating status, regulatory licence, solvency, or willingness to trade.',
  };
}

async function searchOpenCorporatesCompanies(input, options = {}) {
  const filters = normalizeSearchInput(input);
  const token = String(options.apiToken || '').trim();
  if (!token) {
    throw new HttpsError('failed-precondition', 'OpenCorporates is not configured. Set the OPENCORPORATES_API_TOKEN secret before enabling this source.');
  }
  const fetchImpl = options.fetchImpl || fetch;
  const url = new URL(API_BASE);
  url.searchParams.set('q', filters.query);
  url.searchParams.set('per_page', String(Math.min(50, filters.limit)));
  url.searchParams.set('page', '1');

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);
  let response;
  try {
    response = await fetchImpl(url.toString(), {
      method: 'GET',
      headers: {'X-API-TOKEN': token, accept: 'application/json'},
      signal: controller.signal,
    });
  } catch (error) {
    throw new HttpsError('unavailable', error?.name === 'AbortError' ? 'OpenCorporates request timed out.' : 'OpenCorporates is temporarily unavailable.');
  } finally {
    clearTimeout(timeout);
  }
  if (response.status === 401 || response.status === 403) {
    throw new HttpsError('failed-precondition', 'OpenCorporates rejected the API credentials or request quota.');
  }
  if (!response.ok) {
    throw new HttpsError('unavailable', 'OpenCorporates returned HTTP ' + response.status + '.');
  }
  let payload;
  try {
    payload = await response.json();
  } catch (_) {
    throw new HttpsError('data-loss', 'OpenCorporates returned an invalid JSON response.');
  }
  const raw = Array.isArray(payload?.results?.companies) ? payload.results.companies : [];
  let results = raw.map(normalizeCompanyResult).filter(Boolean);
  if (filters.countryCode) {
    const prefix = filters.countryCode.toLowerCase();
    results = results.filter((company) => company.jurisdictionCode === prefix || company.jurisdictionCode?.startsWith(prefix + '_'));
  }
  return {
    status: 'ok',
    scope: filters.countryCode ? 'country' : 'global',
    query: filters.query,
    countryCode: filters.countryCode || null,
    count: results.length,
    results: results.slice(0, filters.limit),
    source: 'OpenCorporates API v0.4',
    sourceUrl: 'https://opencorporates.com/',
    sourceTermsUrl: 'https://opencorporates.com/legal/licence/',
    retrievedAt: new Date().toISOString(),
    page: Number(payload?.results?.page?.current_page || 1),
    totalCount: Number.isFinite(Number(payload?.results?.total_count)) ? Number(payload.results.total_count) : null,
    coverageNote: 'Global search over OpenCorporates records available to the configured API plan; not every legal entity or jurisdiction is necessarily covered. Country filtering uses jurisdiction-code prefixes and may not map perfectly for every subnational registry. A registry listing is not proof of licensing, solvency, or active trading.',
  };
}

exports.aurenSearchOpenCorporatesCompanies = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB', secrets: [OPENCORPORATES_API_TOKEN]},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in to search global company records.');
    }
    return searchOpenCorporatesCompanies(request.data || {}, {
      apiToken: OPENCORPORATES_API_TOKEN.value(),
    });
  },
);

module.exports.normalizeSearchInput = normalizeSearchInput;
module.exports.normalizeCompanyResult = normalizeCompanyResult;
module.exports.searchOpenCorporatesCompanies = searchOpenCorporatesCompanies;
