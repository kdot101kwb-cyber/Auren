'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const FAO_API = 'https://faostat.org/api/v1';
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

exports.aurenFaostatCatalog = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  return {
    status:'ok',
    source:'FAOSTAT',
    apiBase:FAO_API,
    domains:DOMAINS,
    coverage:'245+ countries and territories; availability varies by domain and country'
  };
});

exports.aurenFaostatCountryData = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const iso3 = String(request.data?.iso3 || '').trim().toUpperCase();
  const domainKey = String(request.data?.domain || 'crops_livestock').trim();
  const domain = DOMAINS[domainKey];
  if (!/^[A-Z]{3}$/.test(iso3)) throw new Error('iso3 is required.');
  if (!domain) throw new Error('Unsupported FAOSTAT domain.');

  const url = FAO_API + '/data/' + domain + '?area_code=' + encodeURIComponent(iso3) + '&page_size=100';
  const payload = await getJson(url);

  await db.collection('auren_faostat').doc(iso3 + '_' + domain).set({
    iso3,
    domain:domainKey,
    domainCode:domain,
    data:payload,
    source:'FAOSTAT',
    updatedAt:admin.firestore.FieldValue.serverTimestamp()
  }, {merge:true});

  return {status:'ok', iso3, domain:domainKey, stored:true};
});
