'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const FAOSTAT_BASE = 'https://faostat-app-lb.fao.org/api/v1';
const DOMAINS = {
  crops_livestock: 'QCL',
  land_use: 'RL',
  trade: 'TCL',
  food_balances: 'FB',
  prices: 'PP',
  fertilizers: 'RF'
};

async function getJson(url) {
  const res = await fetch(url, {headers:{accept:'application/json'}});
  if (!res.ok) throw new Error('FAOSTAT request failed: ' + res.status);
  return res.json();
}

exports.aurenFaostatBulkIngest = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const limit = Math.min(Math.max(Number(request.data?.limit) || 10, 1), 50);
  const domainKey = String(request.data?.domain || 'crops_livestock');
  const domain = DOMAINS[domainKey];
  if (!domain) throw new Error('Unsupported FAOSTAT domain.');

  const countries = await db.collection('auren_global_countries').limit(limit).get();
  let processed = 0;
  let failed = 0;

  for (const country of countries.docs) {
    const iso3 = country.id;
    try {
      const url = FAOSTAT_BASE + '/data/' + domain +
        '?area_code=' + encodeURIComponent(iso3) + '&page_size=100';
      const payload = await getJson(url);

      await db.collection('auren_faostat').doc(iso3 + '_' + domain).set({
        iso3,
        domain:domainKey,
        domainCode:domain,
        data:payload,
        source:'FAOSTAT',
        ingestedBy:'aurenFaostatBulkIngest',
        updatedAt:admin.firestore.FieldValue.serverTimestamp()
      }, {merge:true});

      processed++;
    } catch (e) {
      failed++;
      await db.collection('auren_faostat_ingest_errors').doc(iso3 + '_' + domain).set({
        iso3,
        domain:domainKey,
        error:String(e.message || e),
        updatedAt:admin.firestore.FieldValue.serverTimestamp()
      }, {merge:true});
    }
  }

  return {
    status:'ok',
    domain:domainKey,
    requested:limit,
    processed,
    failed,
    next:'repeat with a larger batch/cursor to continue country coverage'
  };
});

exports.aurenFaostatIngestStatus = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const domainKey = String(request.data?.domain || 'crops_livestock');
  const domain = DOMAINS[domainKey];
  if (!domain) throw new Error('Unsupported FAOSTAT domain.');

  const snap = await db.collection('auren_faostat')
    .where('domainCode','==',domain)
    .limit(1000)
    .get();

  const countries = [...new Set(snap.docs.map(d => d.data().iso3).filter(Boolean))];
  return {
    status:'ok',
    domain:domainKey,
    countriesStored:countries.length,
    source:'FAOSTAT'
  };
});
