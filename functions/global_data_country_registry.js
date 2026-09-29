'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const WB = 'https://api.worldbank.org/v2';
const CORE = [
  'SP.POP.TOTL',
  'NY.GDP.MKTP.CD',
  'NY.GDP.PCAP.CD',
  'SP.URB.TOTL.IN.ZS',
  'SL.UEM.TOTL.ZS',
  'AG.LND.AGRI.ZS',
  'AG.LND.ARBL.ZS'
];

async function getJson(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error('Upstream request failed: ' + res.status);
  return res.json();
}

exports.aurenGlobalCountryRegistry = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

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
        longitude: c.longitude ? Number(c.longitude) : null,
        latitude: c.latitude ? Number(c.latitude) : null,
        source: 'world_bank_wdi',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
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

exports.aurenGlobalDataIngest = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const limit = Math.min(Math.max(Number(request.data?.limit) || 25, 1), 250);
  const snap = await db.collection('auren_global_countries').limit(limit).get();
  let processed = 0;

  for (const doc of snap.docs) {
    const iso3 = doc.id;
    const values = {};
    for (const indicator of CORE) {
      const data = await getJson(
        WB + '/country/' + iso3 + '/indicator/' + indicator +
        '?format=json&per_page=1'
      );
      const latest = Array.isArray(data) && Array.isArray(data[1]) ? data[1][0] : null;
      if (latest && latest.value != null) {
        values[indicator] = {
          value: Number(latest.value),
          year: latest.date,
          indicatorName: latest.indicator?.value || indicator
        };
      }
    }

    await db.collection('auren_global_data').doc(iso3).set({
      iso3,
      indicators: values,
      source: 'world_bank_wdi',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, {merge:true});
    processed++;
  }

  return {status:'ok', countriesProcessed:processed, indicators:CORE.length, source:'world_bank_wdi'};
});
