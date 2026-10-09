'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');

const WB_COUNTRY_API = 'https://api.worldbank.org/v2/country';
const MAX_PAGES = 10;
const PAGE_SIZE = 100;
const MAX_RESULTS = 350;

function normalizeText(value, field, maxLength = 100) {
  if (value === undefined || value === null || value === '') return '';
  if (typeof value !== 'string') {
    throw new TypeError(field + ' must be text');
  }
  const normalized = value.trim();
  if (normalized.length > maxLength) {
    throw new TypeError(field + ' must be ' + maxLength + ' characters or fewer');
  }
  return normalized;
}

function normalizeCountry(country) {
  return {
    iso2: country.iso2Code || null,
    iso3: country.id || country.iso3Code || null,
    name: String(country.name || '').trim(),
    region: country.region?.value || null,
    regionCode: country.region?.id || null,
    incomeLevel: country.incomeLevel?.value || null,
    incomeLevelCode: country.incomeLevel?.id || null,
    lendingType: country.lendingType?.value || null,
    capitalCity: country.capitalCity || null,
    source: 'World Bank Country API',
    sourceUrl: 'https://api.worldbank.org/v2/country/' +
      encodeURIComponent(country.iso2Code || country.id || ''),
  };
}

function filterGlobalCountries(countries, input = {}) {
  const query = normalizeText(input.query, 'query', 100).toLocaleLowerCase();
  const region = normalizeText(input.region, 'region', 100).toLocaleLowerCase();
  const incomeLevel = normalizeText(input.incomeLevel, 'incomeLevel', 80).toLocaleLowerCase();
  const countryCode = normalizeText(input.countryCode, 'countryCode', 3).toUpperCase();
  if (countryCode && !/^[A-Z]{2}$/.test(countryCode)) {
    throw new TypeError('countryCode must be a two-letter ISO country code');
  }

  return countries.filter((country) => {
    if (!country.name || !country.iso2 || country.region?.value === 'Aggregates') return false;
    if (countryCode && country.iso2.toUpperCase() !== countryCode) return false;
    if (region && !String(country.region?.value || '').toLocaleLowerCase().includes(region)) return false;
    if (incomeLevel && !String(country.incomeLevel?.value || '').toLocaleLowerCase().includes(incomeLevel)) return false;
    if (query) {
      const searchable = [
        country.name, country.iso2Code, country.id, country.capitalCity,
        country.region?.value, country.incomeLevel?.value,
      ].filter(Boolean).join(' ').toLocaleLowerCase();
      if (!searchable.includes(query)) return false;
    }
    return true;
  }).map(normalizeCountry)
    .sort((a, b) => a.name.localeCompare(b.name))
    .slice(0, MAX_RESULTS);
}

async function fetchCountryPage(page) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  try {
    const url = WB_COUNTRY_API + '?format=json&per_page=' + PAGE_SIZE + '&page=' + page;
    const response = await fetch(url, {
      signal: controller.signal,
      headers: {'accept': 'application/json', 'user-agent': 'AUREN-Global-Discovery/1.0'},
    });
    if (!response.ok) {
      throw new HttpsError('unavailable', 'World Bank country directory returned HTTP ' + response.status + '.');
    }
    const payload = await response.json();
    if (!Array.isArray(payload) || !payload[0] || !Array.isArray(payload[1])) {
      throw new HttpsError('unavailable', 'World Bank country directory returned an invalid response.');
    }
    return {metadata: payload[0], countries: payload[1]};
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', 'Unable to retrieve the global country directory right now.');
  } finally {
    clearTimeout(timer);
  }
}

exports.aurenListGlobalCountries = onCall(
  {region: 'us-central1', timeoutSeconds: 60, memory: '256MiB'},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in to browse AUREN global countries.');
    }

    let filters;
    try {
      filters = {
        query: normalizeText(request.data?.query, 'query', 100),
        region: normalizeText(request.data?.region, 'region', 100),
        incomeLevel: normalizeText(request.data?.incomeLevel, 'incomeLevel', 80),
        countryCode: normalizeText(request.data?.countryCode, 'countryCode', 3),
      };
      if (filters.countryCode && !/^[A-Za-z]{2}$/.test(filters.countryCode)) {
        throw new TypeError('countryCode must be a two-letter ISO country code');
      }
    } catch (error) {
      throw new HttpsError('invalid-argument', error.message);
    }

    const firstPage = await fetchCountryPage(1);
    const pageCount = Math.min(Number(firstPage.metadata.pages) || 1, MAX_PAGES);
    const pages = [firstPage.countries];
    for (let page = 2; page <= pageCount; page++) {
      const result = await fetchCountryPage(page);
      pages.push(result.countries);
    }

    const allCountries = pages.flat();
    const results = filterGlobalCountries(allCountries, filters);
    return {
      status: 'ok',
      scope: 'global',
      countries: results,
      count: results.length,
      totalSourceRecordsRead: allCountries.length,
      source: 'World Bank Country API',
      sourceUrl: WB_COUNTRY_API,
      retrievedAt: new Date().toISOString(),
      filters: {
        query: filters.query || null,
        region: filters.region || null,
        incomeLevel: filters.incomeLevel || null,
        countryCode: filters.countryCode ? filters.countryCode.toUpperCase() : null,
      },
      hasMoreSourcePages: (Number(firstPage.metadata.pages) || 1) > MAX_PAGES,
      note: 'Global country discovery uses World Bank country metadata. Region and country are optional filters. Economies without ISO alpha-2 codes may be omitted; this directory is not a bank, business, or service directory.',
    };
  },
);

module.exports.filterGlobalCountries = filterGlobalCountries;
module.exports.normalizeCountry = normalizeCountry;
