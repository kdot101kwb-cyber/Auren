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
  const [evidence, suitability, financial, fiveYear, logistics, gaezRows] = await Promise.all([
    db.collection('auren_feasibility_evidence').where('iso3','==',iso3).orderBy('generatedAt','desc').limit(1).get(),
    db.collection('auren_agri_suitability').doc(iso3 + '_' + slug).get(),
    db.collection('auren_agri_financial_feasibility').where('iso3','==',iso3).where('crop','==',crop).orderBy('generatedAt','desc').limit(1).get(),
    db.collection('auren_agri_five_year_models').where('iso3','==',iso3).where('crop','==',crop).orderBy('generatedAt','desc').limit(1).get(),
    db.collection('auren_agri_logistics_evidence').doc(iso3).get(),
    db.collection('auren_gaez_v5_crop_summary_rows').where('countryKey','==',iso3).limit(500).get()
  ]);

  const ev = evidence.empty ? null : evidence.docs[0].data();
  const su = suitability.exists ? suitability.data() : null;
  const fi = financial.empty ? null : financial.docs[0].data();
  const fy = fiveYear.empty ? null : fiveYear.docs[0].data();
  const lg = logistics.exists ? logistics.data() : null;
  const gaezGlobalRows = gaezRows.docs.map(doc => doc.data() || {}).filter(row => {
    const item = String(row.row?.crop ?? row.row?.Crop ?? row.row?.crop_name ?? row.row?.Crop_Name ?? '').trim().toLowerCase();
    return !item || item === crop.toLowerCase() || item.includes(crop.toLowerCase()) || crop.toLowerCase().includes(item);
  });

  const evidenceScore = [
    ev?.evidenceQuality?.worldBank,
    ev?.evidenceQuality?.faostat,
    ev?.evidenceQuality?.faoAgricultureIntelligence,
    !!su,
    !!fi,
    !!fy
  ].filter(Boolean).length;

  const priceSource = fi?.priceSource || null;
  const yieldSource = fi?.yieldSource || null;
  const evidenceTrace = {
    yield: {
      source: yieldSource,
      evidence: fi?.yieldEvidence || null,
      input: fi?.inputs?.yieldTonsHa ?? null
    },
    price: {
      source: priceSource,
      evidence: fi?.priceEvidence || null,
      input: fi?.inputs?.pricePerTon ?? null
    },
    costs: fi?.costEvidenceLedger || null,
    logistics: {
      status: fi?.logisticsEvidence?.available ? 'world_bank_lpi_loaded' : 'requires_logistics_evidence',
      source: fi?.logisticsEvidence?.source || lg?.source || null,
      evidence: fi?.logisticsEvidence?.items || lg?.items || [],
      monetaryCost: fi?.costEvidenceLedger?.logistics || null,
      note: 'World Bank LPI is a logistics-performance signal and is not a freight-cost amount.'
    }
  };

  const report = {
    status:'ok',
    project:{iso3,crop,sector:'agriculture'},
    technical:{
      evidence:ev,
      suitability:su,
      evidenceCompleteness:Math.round(evidenceScore / 6 * 100),
      gaezV5CropSummary:{
        source:'FAO GAEZ v5 Crop Summary Data',
        country:iso3,
        crop,
        importedRows:gaezGlobalRows.length,
        available:gaezGlobalRows.length > 0
      }
    },
    financial:{
      oneYear:fi?.outputs || null,
      evidenceTrace,
      scenarios:fi?.scenarios || null,
      fiveYear:fy?.summary || null,
      fiveYearRows:fy?.years || null,
      evidenceCompleteness: {
        yield: !!yieldSource,
        price: !!priceSource,
        costs: !!fi?.costEvidence?.available,
        logisticsPerformance: !!(fi?.logisticsEvidence?.available || lg),
        sourcedCostItems: fi?.costEvidenceLedger?.sourcedItems?.length || 0,
        marketEvidenceItems: fi?.marketEvidence?.length || 0
      }
    },
    market:{
      status:priceSource === 'FAOSTAT_producer_price' ? 'faostat_producer_price_loaded' : 'requires_market_inputs',
      inputsProvided:{
        sellingPrice:fi?.inputs?.pricePerTon ?? null,
        otherAnnualRevenue:fi?.inputs?.otherAnnualRevenue ?? null
      },
      priceEvidence:fi?.priceEvidence || null,
      missing:['local demand','competitor/supply conditions','monetary logistics cost','buyer/offtake terms','current local price validation'],
      evidenceStatus:{
        producerPrice:!!fi?.priceEvidence,
        marketEvidence:!!(fi?.marketEvidence?.length),
        logisticsPerformance:!!(fi?.logisticsEvidence?.available || lg),
        sourcedCosts:!!fi?.costEvidence?.available
      },
      evidence:fi?.marketEvidence || []
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
      evidenceStatus:{yieldSource,priceSource},
      reason:'The report combines available evidence and project assumptions but does not replace field, laboratory, legal or market due diligence.'
    },
    nextSteps:[
      'Validate soil and water conditions locally.',
      'Validate current local selling prices and buyer/offtake demand.',
      'Replace planning assumptions with sourced project data, with source/year/currency/unit recorded for each material cost.',
      'Run downside/base/upside cases before investment decisions.'
    ],
    generatedAt:admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection('auren_complete_feasibility_reports').add({
    uid:request.auth.uid, ...report
  });

  return report;
});
