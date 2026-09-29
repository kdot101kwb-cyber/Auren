'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const GAEZ_CATALOG_URL = 'https://data.fao.org/catalog/dataset/gaez-v5-master-config';
const CROP_SUMMARY_CATALOG_URL = 'https://data.fao.org/catalog/dataset/crop-summary-gaez';

const THEMES = [
  'land_water_resources',
  'agro_climatic_resources',
  'suitability_attainable_yield',
  'actual_yields_production',
  'yield_production_gaps',
  'crop_summary'
];

exports.aurenGaezCatalog = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  return {
    status:'ok',
    source:'FAO GAEZ v5',
    catalogUrl:GAEZ_CATALOG_URL,
    cropSummaryUrl:CROP_SUMMARY_CATALOG_URL,
    themes:THEMES,
    resolution:{
      standard:'5 arc-minute (~10 km at equator)',
      selected:'30 arc-second (~1 km at equator)'
    },
    note:'This catalog layer intentionally does not fabricate a raster/API endpoint. Data download/query endpoints should be added only after validating the current FAO catalog resource.'
  };
});

exports.aurenGaezCropQuery = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const country = String(request.data?.country || '').trim();
  const crop = String(request.data?.crop || '').trim();
  const climateSource = String(request.data?.climateSource || '').trim();
  const ssp = String(request.data?.ssp || '').trim();
  const period = String(request.data?.period || '').trim();
  const waterSupply = String(request.data?.waterSupply || '').trim();
  const management = String(request.data?.management || '').trim();

  const query = {
    country: country || null,
    crop: crop || null,
    climateSource: climateSource || null,
    ssp: ssp || null,
    period: period || null,
    waterSupply: waterSupply || null,
    management: management || null
  };

  const ref = db.collection('auren_gaez_queries').doc();
  await ref.set({
    query,
    source:'FAO GAEZ v5 Crop Summary',
    catalogUrl:CROP_SUMMARY_CATALOG_URL,
    status:'pending_data_connector',
    createdBy:request.auth.uid,
    createdAt:admin.firestore.FieldValue.serverTimestamp()
  });

  return {
    status:'queued',
    id:ref.id,
    query,
    source:'FAO GAEZ v5',
    next:'connect the validated FAO catalog resource/query endpoint before returning agronomic values'
  };
});
