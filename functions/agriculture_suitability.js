'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

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
