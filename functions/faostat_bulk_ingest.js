'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const DOMAINS = {
  crops_livestock: 'QCL',
  land_use: 'RL',
  trade: 'TCL',
  food_balances: 'FB',
  prices: 'PP',
  fertilizers: 'RF'
};

const {fetchFaostatCountryDomain} = require('./faostat_global_data');

async function ingestFaostatCountryInternal(iso3, domainKey, options = {}) {
  const domain = DOMAINS[domainKey];
  if (!domain) throw new Error('Unsupported FAOSTAT domain.');

  const result = await fetchFaostatCountryDomain(iso3, domainKey, options);

  await db.collection('auren_faostat').doc(iso3 + '_' + domain).set({
    iso3,
    domain:domainKey,
    domainCode:domain,
    data:result.data,
    pagesFetched:result.pagesFetched,
    pageSize:result.pageSize,
    truncated:result.truncated,
    source:'FAOSTAT',
    ingestedBy:'aurenFaostatBulkIngest',
    updatedAt:admin.firestore.FieldValue.serverTimestamp()
  }, {merge:true});

  return result;
}

exports.ingestFaostatCountryInternal = ingestFaostatCountryInternal;

exports.aurenFaostatBulkIngest = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const limit = Math.min(Math.max(Number(request.data?.limit) || 10, 1), 50);
  const domainKey = String(request.data?.domain || 'crops_livestock');
  if (!DOMAINS[domainKey]) throw new Error('Unsupported FAOSTAT domain.');

  const countries = await db.collection('auren_global_countries')
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(limit)
    .get();

  let processed = 0;
  let failed = 0;

  for (const country of countries.docs) {
    const iso3 = country.id;
    try {
      await ingestFaostatCountryInternal(iso3, domainKey, {
        pageSize: request.data?.pageSize,
        maxPages: request.data?.maxPages
      });
      processed++;
    } catch (e) {
      failed++;
      await db.collection('auren_faostat_ingest_errors').doc(iso3 + '_' + DOMAINS[domainKey]).set({
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
    note:'Use the scheduled cursor ingestion for full country coverage.'
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
