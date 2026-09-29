'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

exports.aurenCompleteAgriFeasibility = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p = request.data || {};
  const iso3 = String(p.iso3 || '').trim().toUpperCase();
  const crop = String(p.crop || '').trim();
  if (!/^[A-Z]{3}$/.test(iso3) || !crop) throw new Error('iso3 and crop are required.');

  const slug = crop.toLowerCase().replace(/[^a-z0-9]+/g, '_');
  const [evidence, suitability, financial, fiveYear] = await Promise.all([
    db.collection('auren_feasibility_evidence').where('iso3','==',iso3).orderBy('generatedAt','desc').limit(1).get(),
    db.collection('auren_agri_suitability').doc(iso3 + '_' + slug).get(),
    db.collection('auren_agri_financial_feasibility').where('iso3','==',iso3).where('crop','==',crop).orderBy('generatedAt','desc').limit(1).get(),
    db.collection('auren_agri_five_year_models').where('iso3','==',iso3).where('crop','==',crop).orderBy('generatedAt','desc').limit(1).get()
  ]);

  const ev = evidence.empty ? null : evidence.docs[0].data();
  const su = suitability.exists ? suitability.data() : null;
  const fi = financial.empty ? null : financial.docs[0].data();
  const fy = fiveYear.empty ? null : fiveYear.docs[0].data();

  const evidenceScore = [
    ev?.evidenceQuality?.worldBank,
    ev?.evidenceQuality?.faostat,
    ev?.evidenceQuality?.faoAgricultureIntelligence,
    !!su,
    !!fi,
    !!fy
  ].filter(Boolean).length;

  const report = {
    status:'ok',
    project:{iso3,crop,sector:'agriculture'},
    technical:{
      evidence:ev,
      suitability:su,
      evidenceCompleteness:Math.round(evidenceScore / 6 * 100)
    },
    financial:{
      oneYear:fi?.outputs || null,
      scenarios:fi?.scenarios || null,
      fiveYear:fy?.summary || null,
      fiveYearRows:fy?.years || null
    },
    market:{
      status:'requires_market_inputs',
      inputsProvided:{
        sellingPrice:fi?.inputs?.pricePerTon ?? null,
        otherAnnualRevenue:fi?.inputs?.otherAnnualRevenue ?? null
      },
      missing:['local demand','competitor/supply conditions','logistics cost','buyer/offtake terms','current local price validation']
    },
    risks:[
      'Climate and water variability',
      'Yield uncertainty',
      'Price and market volatility',
      'Input and logistics cost changes',
      'Currency/financing exposure',
      'Land, legal and permitting requirements',
      'Pests, diseases and post-harvest losses'
    ],
    decision:{
      recommendation:'requires_validation',
      reason:'The report combines available evidence and project assumptions but does not replace field, laboratory, legal or market due diligence.'
    },
    nextSteps:[
      'Validate soil and water conditions locally.',
      'Validate current local selling prices and buyer/offtake demand.',
      'Replace planning assumptions with sourced project data.',
      'Run downside/base/upside cases before investment decisions.'
    ],
    generatedAt:admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection('auren_complete_feasibility_reports').add({
    uid:request.auth.uid, ...report
  });

  return report;
});
