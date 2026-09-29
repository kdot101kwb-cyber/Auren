'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const GAEZ_RES05 = 'https://gaez-services.fao.org/server/rest/services/res05/ImageServer';

function num(v) {
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function rangeScore(value, min, max) {
  if (value == null || min == null || max == null) return null;
  if (value >= min && value <= max) return 1;
  const distance = value < min ? min - value : value - max;
  const span = Math.max(max - min, 1);
  return Math.max(0, 1 - distance / span);
}

async function getJson(url) {
  const res = await fetch(url, {
    headers:{accept:'application/json'},
    signal:AbortSignal.timeout(30000)
  });
  if (!res.ok) throw new Error('GAEZ request failed: ' + res.status);
  return res.json();
}

async function getGaezYieldEvidence({crop, waterSupply, inputLevel, latitude, longitude}) {
  const catalog = await getGaezCatalog(crop, waterSupply, inputLevel);
  if (!latitude || !longitude || !catalog.length) return {catalog, samples:[]};

  const samples = [];
  for (const item of catalog.slice(0, 5)) {
    const objectId = item.objectid;
    if (!objectId) continue;
    const params = new URLSearchParams({
      geometry: JSON.stringify({x:Number(longitude), y:Number(latitude), spatialReference:{wkid:4326}}),
      geometryType:'esriGeometryPoint',
      returnGeometry:'false',
      returnCatalogItems:'true',
      returnAllPixelValues:'false',
      mosaicRule: JSON.stringify({where:"OBJECTID = " + Number(objectId)}),
      outFields:'*',
      f:'json'
    });
    try {
      const payload = await getJson(GAEZ_RES05 + '/identify?' + params.toString());
      samples.push({resource:item, identify:payload});
    } catch (e) {
      samples.push({resource:item, error:String(e.message || e)});
    }
  }
  return {catalog, samples};
}

async function getGaezCatalog(crop, waterSupply, inputLevel) {
  const where = ["crop = '" + crop.replace(/'/g, "''") + "'"];
  if (waterSupply) where.push("water_supply = '" + waterSupply.replace(/'/g, "''") + "'");
  if (inputLevel) where.push("input_level = '" + inputLevel.replace(/'/g, "''") + "'");
  const params = new URLSearchParams({
    where:where.join(' AND '),
    outFields:'objectid,name,sub_theme_name,variable,file_description,year,model,rcp,crop,water_supply,input_level,units,download_url,file_id',
    returnGeometry:'false',
    resultRecordCount:'1000',
    f:'json'
  });
  const payload = await getJson(GAEZ_RES05 + '/query?' + params.toString());
  return (payload.features || []).map(x => x.attributes || {});
}

exports.aurenAgricultureSuitability = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const iso3 = String(request.data?.iso3 || '').trim().toUpperCase();
  const crop = String(request.data?.crop || '').trim();
  if (!/^[A-Z]{3}$/.test(iso3) || !crop) {
    throw new Error('iso3 and crop are required.');
  }

  const [countrySnap, faoSnap, intelSnap] = await Promise.all([
    db.collection('auren_global_data').doc(iso3).get(),
    db.collection('auren_faostat').doc(iso3 + '_QCL').get(),
    db.collection('auren_fao_agri_intelligence').doc(iso3).get()
  ]);

  const country = countrySnap.exists ? countrySnap.data() : {};
  const fao = faoSnap.exists ? faoSnap.data() : {};
  const intel = intelSnap.exists ? intelSnap.data() : {};

  const indicators = country.indicators || {};
  const inputs = request.data?.inputs || {};
  const rainfall = num(inputs.rainfallMm);
  const temperature = num(inputs.temperatureC);
  const soilScore = num(inputs.soilScore);
  const waterAccess = num(inputs.waterAccessScore);

  const criteria = [
    {name:'rainfall', score:rangeScore(rainfall, num(inputs.rainfallMinMm), num(inputs.rainfallMaxMm))},
    {name:'temperature', score:rangeScore(temperature, num(inputs.temperatureMinC), num(inputs.temperatureMaxC))},
    {name:'soil', score:soilScore == null ? null : Math.max(0, Math.min(1, soilScore))},
    {name:'water', score:waterAccess == null ? null : Math.max(0, Math.min(1, waterAccess))}
  ].filter(x => x.score != null);

  const score = criteria.length
    ? Math.round(criteria.reduce((a,b) => a + b.score, 0) / criteria.length * 100)
    : null;

  const result = {
    iso3,
    crop,
    score,
    status: score == null ? 'insufficient_data' : score >= 70 ? 'potentially_suitable' : score >= 45 ? 'needs_validation' : 'potential_constraints',
    criteria,
    gaezEvidence,
    evidence: {
      worldBankIndicators: indicators,
      faostatAvailable: faoSnap.exists,
      faoIntelligenceAvailable: intelSnap.exists
    },
    limitations: [
      'This is a screening result, not a agronomic certification.',
      'Crop-specific thresholds must be supplied or sourced before treating the score as crop suitability.',
      'Field soil tests, local water availability, pests, market access and current costs require separate validation.'
    ],
    generatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection('auren_agri_suitability').doc(iso3 + '_' + crop.toLowerCase().replace(/[^a-z0-9]+/g,'_')).set(result, {merge:true});
  return result;
});
