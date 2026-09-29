'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const GAEZ_CATALOG_URL = 'https://data.fao.org/catalog/dataset/gaez-v5-master-config';
const CROP_SUMMARY_CATALOG_URL = 'https://data.fao.org/catalog/dataset/crop-summary-gaez';
const GAEZ_V5_RES05 = process.env.GAEZ_V5_RES05 || null;
const GAEZ_V5_CROP_SUMMARY_URL = process.env.GAEZ_V5_CROP_SUMMARY_URL || null;

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
    endpointStatus: process.env.GAEZ_V5_RES05 ? 'configured_not_yet_proven' : 'missing',
    note:'GAEZ v5 was launched by FAO in 2025; this deployment only treats a configured endpoint as verified and never labels the default endpoint as v5 without validation.'
  };
});

async function getJson(url) {
  const res = await fetch(url, {
    headers:{accept:'application/json'},
    signal:AbortSignal.timeout(30000)
  });
  if (!res.ok) throw new Error('GAEZ request failed: ' + res.status);
  return res.json();
}

exports.aurenGaezV5HealthCheck = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const configuredEndpoint = process.env.GAEZ_V5_RES05 || null;
  let catalogReachable = false;
  let catalogText = '';
  try {
    const res = await fetch(GAEZ_CATALOG_URL, {signal:AbortSignal.timeout(30000)});
    catalogText = await res.text();
    catalogReachable = res.ok && /GAEZ v5|gaez-v5/i.test(catalogText);
  } catch (_) {}
  return {
    status: catalogReachable && configuredEndpoint ? 'ready_for_endpoint_validation' : 'configuration_required',
    source:'FAO GAEZ v5',
    catalogUrl:GAEZ_CATALOG_URL,
    configuredEndpoint,
    catalogReachable,
    endpointStatus:configuredEndpoint ? 'configured_not_yet_proven' : 'missing',
    next:'Configure GAEZ_V5_RES05 only with a verified FAO GAEZ v5 resource; do not infer v5 from a v4-compatible service URL.'
  };
});

exports.aurenGaezSuitabilityCatalog = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const crop = String(request.data?.crop || '').trim();
  const waterSupply = String(request.data?.waterSupply || '').trim();
  const inputLevel = String(request.data?.inputLevel || '').trim();

  const where = [];
  if (crop) where.push("crop = '" + crop.replace(/'/g, "''") + "'");
  if (waterSupply) where.push("water_supply = '" + waterSupply.replace(/'/g, "''") + "'");
  if (inputLevel) where.push("input_level = '" + inputLevel.replace(/'/g, "''") + "'");

  const params = new URLSearchParams({
    where: where.length ? where.join(' AND ') : '1=1',
    outFields:'objectid,name,variable,year,model,rcp,crop,water_supply,input_level,units,download_url,file_id',
    returnGeometry:'false',
    resultRecordCount:'1000',
    f:'json'
  });

  if (!GAEZ_V5_RES05) throw new Error('GAEZ_V5_RES05 is not configured with a verified FAO GAEZ v5 endpoint.');
  const payload = await getJson(GAEZ_V5_RES05 + '/query?' + params.toString());
  const items = payload.features || [];

  return {
    status:'ok',
    source:'FAO GAEZ v5',
    endpointStatus:process.env.GAEZ_V5_RES05 ? 'configured' : 'not_verified',
    service:GAEZ_V5_RES05,
    count:items.length,
    items:items.map(x => x.attributes || {})
  };
});

exports.aurenGaezV5CropSummary = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  if (!GAEZ_V5_CROP_SUMMARY_URL) {
    return {status:'configuration_required', source:'FAO GAEZ v5 Crop Summary', catalogUrl:CROP_SUMMARY_CATALOG_URL, reason:'GAEZ_V5_CROP_SUMMARY_URL is not configured'};
  }
  const p=request.data||{};
  const params=new URLSearchParams();
  for (const key of ['country','crop','climateSource','ssp','period','waterSupply','management']) {
    if (p[key]) params.set(key,String(p[key]));
  }
  const url=GAEZ_V5_CROP_SUMMARY_URL + (GAEZ_V5_CROP_SUMMARY_URL.includes('?')?'&':'?') + params.toString();
  const payload=await getJson(url);
  return {status:'ok',source:'FAO GAEZ v5 Crop Summary',endpoint:url.split('?')[0],filters:Object.fromEntries(params.entries()),data:payload};
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
    gaezV5SuitabilityService:GAEZ_V5_RES05,
    status:'queued',
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
