'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

exports.aurenFeasibilityWithAgriEvidence = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const iso3 = String(request.data?.iso3 || '').trim().toUpperCase();
  const sector = String(request.data?.sector || 'agriculture').trim();
  const crop = String(request.data?.crop || '').trim();
  if (!/^[A-Z]{3}$/.test(iso3)) throw new Error('iso3 is required.');

  const refs = await Promise.all([
    db.collection('auren_global_data').doc(iso3).get(),
    db.collection('auren_faostat').doc(iso3 + '_QCL').get(),
    db.collection('auren_fao_agri_intelligence').doc(iso3).get(),
    crop ? db.collection('auren_agri_suitability').doc(iso3 + '_' + crop.toLowerCase().replace(/[^a-z0-9]+/g,'_')).get() : Promise.resolve(null)
  ]);

  const [worldBank, faostat, faoIntel, suitability] = refs;
  const evidence = {
    worldBank: worldBank.exists ? worldBank.data() : null,
    faostat: faostat.exists ? {available:true, source:faostat.data().source, domain:faostat.data().domain} : null,
    faoAgricultureIntelligence: faoIntel.exists ? faoIntel.data() : null,
    cropSuitability: suitability?.exists ? suitability.data() : null
  };

  const result = {
    status:'ok',
    iso3,
    sector,
    crop:crop || null,
    evidence,
    decisionInputs:[
      'site and land characteristics',
      'water availability and irrigation',
      'climate and seasonality',
      'soil constraints',
      'production capacity',
      'labor and equipment',
      'storage and post-harvest handling',
      'market access and sales channels',
      'CAPEX/OPEX and unit economics'
    ],
    evidenceQuality:{
      worldBank:!!evidence.worldBank,
      faostat:!!evidence.faostat,
      faoAgricultureIntelligence:!!evidence.faoAgricultureIntelligence,
      cropSuitability:!!evidence.cropSuitability
    },
    limitations:[
      'This is a preliminary evidence pack, not a certified feasibility study.',
      'Missing local field, laboratory, market-price and legal data must be validated before investment decisions.'
    ],
    generatedAt:admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection('auren_feasibility_evidence').add({
    uid:request.auth.uid,
    ...result
  });

  return result;
});
