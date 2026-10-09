'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');

const WORLD_BANK_API = 'https://api.worldbank.org/v2';
const FINANCIAL_INDICATORS = Object.freeze({
  domestic_credit_private_sector_gdp: {
    code: 'FS.AST.PRVT.GD.ZS',
    label: 'Domestic credit to private sector (% of GDP)',
  },
  commercial_bank_branches_per_100k: {
    code: 'FB.CBK.BRCH.P5',
    label: 'Commercial bank branches per 100,000 adults',
  },
  account_ownership_adults: {
    code: 'FX.OWN.TOTL.ZS',
    label: 'Account ownership (% of adults)',
  },
  domestic_credit_financial_sector_gdp: {
    code: 'FS.AST.DOMS.GD.ZS',
    label: 'Domestic credit provided by financial sector (% of GDP)',
  },
});

function normalizeCountryCode(value) {
  const code = String(value || '').trim().toUpperCase();
  return /^[A-Z]{2,3}$/.test(code) ? code : '';
}

function normalizeIndicatorKeys(value) {
  if (value == null) return Object.keys(FINANCIAL_INDICATORS);
  if (!Array.isArray(value) || value.length === 0 || value.length > 4) return null;
  const keys = [...new Set(value.map((v) => String(v || '').trim()))];
  return keys.every((key) => Object.hasOwn(FINANCIAL_INDICATORS, key)) ? keys : null;
}

function normalizeWorldBankResponse(payload, requestedKeys, countryCode) {
  if (!Array.isArray(payload) || !Array.isArray(payload[1])) {
    return {countryCode, source: 'World Bank', sourceUrl: 'https://api.worldbank.org/v2/', observations: []};
  }
  const requestedCodes = new Map(requestedKeys.map((key) => [FINANCIAL_INDICATORS[key].code, key]));
  const observations = payload[1].filter((row) => row && requestedCodes.has(row.indicator?.id) && row.value != null)
    .map((row) => {
      const key = requestedCodes.get(row.indicator.id);
      return {
        indicatorKey: key,
        indicatorCode: row.indicator.id,
        indicatorName: FINANCIAL_INDICATORS[key].label,
        countryCode: row.countryiso3code || countryCode,
        countryName: row.country?.value || null,
        year: String(row.date || ''),
        value: Number(row.value),
        unit: row.unit || null,
        sourceName: 'World Bank',
        sourceUrl: 'https://api.worldbank.org/v2/',
        verificationStatus: 'source_published_not_independently_verified',
      };
    });
  return {
    countryCode,
    source: 'World Bank',
    sourceUrl: 'https://api.worldbank.org/v2/',
    retrievedAt: new Date().toISOString(),
    observations,
  };
}

exports.aurenWorldBankFinancialIndicators = onCall({
  region: 'us-central1',
  timeoutSeconds: 30,
  memory: '256MiB',
}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in to view financial indicators.');
  }
  const countryCode = normalizeCountryCode(request.data?.countryCode);
  if (!countryCode) {
    throw new HttpsError('invalid-argument', 'Provide a valid two- or three-letter country code.');
  }
  const keys = normalizeIndicatorKeys(request.data?.indicators);
  if (!keys) {
    throw new HttpsError('invalid-argument', 'Choose up to four supported financial indicators.');
  }
  const codes = keys.map((key) => FINANCIAL_INDICATORS[key].code).join(';');
  const url = new URL(`${WORLD_BANK_API}/country/${encodeURIComponent(countryCode)}/indicator/${encodeURIComponent(codes)}`);
  url.searchParams.set('format', 'json');
  url.searchParams.set('mrnev', '5');
  url.searchParams.set('per_page', '100');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 20000);
  try {
    const response = await fetch(url, {
      headers: {'accept': 'application/json'},
      signal: controller.signal,
    });
    if (!response.ok) {
      throw new HttpsError('unavailable', 'The World Bank data service is temporarily unavailable.');
    }
    const payload = await response.json();
    if (!Array.isArray(payload) || (payload[0] && typeof payload[0].message === 'string')) {
      throw new HttpsError('unavailable', 'The World Bank did not return usable indicator data.');
    }
    return normalizeWorldBankResponse(payload, keys, countryCode);
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', 'Unable to retrieve financial indicators right now.');
  } finally {
    clearTimeout(timeout);
  }
});

module.exports.FINANCIAL_INDICATORS = FINANCIAL_INDICATORS;
module.exports.normalizeCountryCode = normalizeCountryCode;
module.exports.normalizeIndicatorKeys = normalizeIndicatorKeys;
module.exports.normalizeWorldBankResponse = normalizeWorldBankResponse;
