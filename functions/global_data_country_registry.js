'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const WB = 'https://api.worldbank.org/v2';
// Broad country profile: demographics, economy, trade, agriculture, digital access,
// infrastructure, investment and environment. Missing upstream values remain absent.
const CORE = [
  'SP.POP.TOTL',
  'SP.POP.GROW',
  'SP.URB.TOTL.IN.ZS',
  'SP.DYN.LE00.IN',
  'NY.GDP.MKTP.CD',
  'NY.GDP.PCAP.CD',
  'NY.GDP.MKTP.KD.ZG',
  'FP.CPI.TOTL.ZG',
  'SL.UEM.TOTL.ZS',
  'NE.EXP.GNFS.CD',
  'NE.IMP.GNFS.CD',
  'BX.KLT.DINV.CD.WD',
  'IT.NET.USER.ZS',
  'EG.ELC.ACCS.ZS',
  'NV.AGR.TOTL.ZS',
  'AG.LND.AGRI.ZS',
  'AG.LND.ARBL.ZS',
  'EG.FEC.RNEW.ZS'
];

const INDICATOR_CATEGORIES = {
  'SP.POP.TOTL': 'demographics',
  'SP.POP.GROW': 'demographics',
  'SP.URB.TOTL.IN.ZS': 'demographics',
  'SP.DYN.LE00.IN': 'health',
  'NY.GDP.MKTP.CD': 'economy',
  'NY.GDP.PCAP.CD': 'economy',
  'NY.GDP.MKTP.KD.ZG': 'economy',
  'FP.CPI.TOTL.ZG': 'economy',
  'SL.UEM.TOTL.ZS': 'employment',
  'NE.EXP.GNFS.CD': 'trade',
  'NE.IMP.GNFS.CD': 'trade',
  'BX.KLT.DINV.CD.WD': 'investment',
  'IT.NET.USER.ZS': 'digital_access',
  'EG.ELC.ACCS.ZS': 'infrastructure',
  'NV.AGR.TOTL.ZS': 'agriculture',
  'AG.LND.AGRI.ZS': 'agriculture',
  'AG.LND.ARBL.ZS': 'agriculture',
  'EG.FEC.RNEW.ZS': 'environment'
};

function coordinate(value) {
  if (value === null || value === undefined || value === '') return null;
  const number = Number(value);
  return Number.isFinite(number) && number >= -180 && number <= 180 ? number : null;
}

async function getJson(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 15000);
  try {
    const res = await fetch(url, {
      signal: controller.signal,
      headers: {'user-agent': 'AUREN-Global-Data/1.0'}
    });
    if (!res.ok) throw new HttpsError('unavailable', 'World Bank data source returned HTTP ' + res.status + '.');
    return await res.json();
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', 'World Bank data request failed or timed out.');
  } finally {
    clearTimeout(timer);
  }
}

function requireAdmin(request) {
  if (!request.auth || request.auth.token?.admin !== true) {
    throw new HttpsError('permission-denied', 'Administrator access is required.');
  }
}

exports.aurenGlobalCountryRegistry = onCall({region: 'us-central1', timeoutSeconds: 120, memory: '256MiB'}, async (request) => {
  requireAdmin(request);

  const rows = [];
  for (let page = 1; page <= 6; page++) {
    const data = await getJson(
      WB + '/country?format=json&per_page=100&page=' + page
    );
    if (!Array.isArray(data) || !Array.isArray(data[1])) break;
    for (const c of data[1]) {
      if (!c.id || !c.iso3Code || c.region?.value === 'Aggregates') continue;
      rows.push({
        iso2: c.iso2Code || null,
        iso3: c.iso3Code,
        name: c.name,
        region: c.region?.value || null,
        incomeLevel: c.incomeLevel?.value || null,
        lendingType: c.lendingType?.value || null,
        capitalCity: c.capitalCity || null,
        longitude: coordinate(c.longitude),
        latitude: coordinate(c.latitude),
        source: 'world_bank_wdi',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  }

  if (rows.length === 0) {
    throw new HttpsError('unavailable', 'World Bank country registry returned no usable countries.');
  }

  const batchSize = 400;
  for (let i = 0; i < rows.length; i += batchSize) {
    const batch = db.batch();
    for (const row of rows.slice(i, i + batchSize)) {
      batch.set(db.collection('auren_global_countries').doc(row.iso3), row, {merge: true});
    }
    await batch.commit();
  }

  return {status:'ok', countriesProcessed:rows.length, source:'world_bank_wdi'};
});

exports.aurenGlobalDataIngest = onCall({region: 'us-central1', timeoutSeconds: 120, memory: '256MiB'}, async (request) => {
  requireAdmin(request);

  const limit = Math.min(Math.max(Number(request.data?.limit) || 25, 1), 25);
  const snap = await db.collection('auren_global_countries').limit(limit).get();
  let processed = 0;
  let indicatorsStored = 0;
  let failedIndicators = 0;
  let countriesWithNoIndicators = 0;

  const countryChunkSize = 5;
  for (let i = 0; i < snap.docs.length; i += countryChunkSize) {
    const countryChunk = snap.docs.slice(i, i + countryChunkSize);
    const results = await Promise.all(countryChunk.map(async (doc) => {
      const iso3 = doc.id;
      const entries = await Promise.all(CORE.map(async (indicator) => {
        try {
          const data = await getJson(
            WB + '/country/' + iso3 + '/indicator/' + indicator +
            '?format=json&per_page=1'
          );
          const latest = Array.isArray(data) && Array.isArray(data[1]) ? data[1][0] : null;
          if (!latest || latest.value == null) return {indicator, value: null};
          const value = Number(latest.value);
          if (!Number.isFinite(value)) return {indicator, value: null};
          return {indicator, value: {
            value,
            year: latest.date,
            indicatorName: latest.indicator?.value || indicator,
            category: INDICATOR_CATEGORIES[indicator] || 'other'
          }};
        } catch (_) {
          return {indicator, value: null, failed: true};
        }
      }));
      const values = Object.fromEntries(entries.filter((entry) => entry.value).map((entry) => [entry.indicator, entry.value]));
      const failedIndicators = entries.filter((entry) => entry.failed).length;
      await db.collection('auren_global_data').doc(iso3).set({
        iso3,
        indicators: values,
        indicatorCount: Object.keys(values).length,
        failedIndicators,
        source: 'world_bank_wdi',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, {merge:true});
      return {iso3, indicatorCount: Object.keys(values).length, failedIndicators};
    }));
    processed += results.length;
    for (const result of results) {
      indicatorsStored += result.indicatorCount;
      failedIndicators += result.failedIndicators;
      if (result.indicatorCount === 0) countriesWithNoIndicators++;
    }
  }

  return {
    status: failedIndicators > 0 || countriesWithNoIndicators > 0 ? 'partial' : 'ok',
    countriesProcessed: processed,
    indicatorsConfigured: CORE.length,
    indicatorValuesStored: indicatorsStored,
    failedIndicatorRequests: failedIndicators,
    countriesWithNoIndicators,
    source: 'world_bank_wdi'
  };
});
