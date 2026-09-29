'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const FAO_DSP = 'https://api-digital.apps.fao.org/api/v2';

async function getJson(url) {
  const res = await fetch(url, {headers:{accept:'application/json'}});
  if (!res.ok) throw new Error('FAO DSP request failed: ' + res.status);
  return res.json();
}

exports.aurenFaoAgriIntelligence = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const iso3 = String(request.data?.iso3 || '').trim().toUpperCase();
  if (!/^[A-Z]{3}$/.test(iso3)) throw new Error('iso3 is required.');

  const result = {iso3, source:'FAO_DSP', collectedAt:new Date().toISOString()};

  const endpoints = {
    districts: FAO_DSP + '/districts/' + iso3,
    profile: FAO_DSP + '/profile/' + iso3 + '/step',
    cities: FAO_DSP + '/meteo/' + iso3 + '/cities'
  };

  for (const [key,url] of Object.entries(endpoints)) {
    try {
      result[key] = await getJson(url);
    } catch (e) {
      result[key] = {error:String(e.message || e)};
    }
  }

  await db.collection('auren_fao_agri_intelligence').doc(iso3).set({
    iso3,
    source:'FAO_DSP',
    data:result,
    updatedAt:admin.firestore.FieldValue.serverTimestamp()
  }, {merge:true});

  return {status:'ok', iso3, stored:true, available:Object.keys(result).filter(k => k !== 'iso3' && k !== 'source' && k !== 'collectedAt')};
});
