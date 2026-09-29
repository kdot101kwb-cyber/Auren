'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

function finite(v) { const n = Number(v); return Number.isFinite(n) ? n : null; }

function cropSlug(crop) {
  return String(crop || '').toLowerCase().replace(/[^a-z0-9]+/g, '_');
}

function normalizeYieldEvidence(samples) {
  const accepted = [];
  for (const sample of Array.isArray(samples) ? samples : []) {
    const value = finite(sample?.value);
    const units = String(sample?.units || '').trim().toLowerCase();
    if (value == null || value < 0 || !units) continue;
    if (/^(t\\/?ha|tonnes?\\s*per\\s*ha|tons?\\s*per\\s*ha)$/.test(units) || units.includes('ton/ha') || units.includes('t/ha')) {
      accepted.push({value, units: sample.units, resource: sample.resource || null});
    }
  }
  if (!accepted.length) return null;
  const value = accepted.reduce((sum, item) => sum + item.value, 0) / accepted.length;
  return {yieldTonsHa:value, unit:'t/ha', samples:accepted};
}

async function getGaezYieldFromSuitability(iso3, crop) {
  const ref = db.collection('auren_agri_suitability').doc(iso3 + '_' + cropSlug(crop));
  const snap = await ref.get();
  if (!snap.exists) return {available:false, source:'gaez_suitability_document', reason:'no_suitability_result'};
  const data = snap.data() || {};
  const normalized = normalizeYieldEvidence(data.gaezEvidence?.samples);
  if (!normalized) return {available:false, source:'gaez_suitability_document', reason:'units_not_explicitly_yield_per_hectare'};
  return {available:true, source:'FAO_GAEZ_evidence', ...normalized};
}

exports.aurenAgriFinancialFeasibility = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p = request.data || {};
  const iso3 = String(p.iso3 || '').trim().toUpperCase();
  const crop = String(p.crop || '').trim();
  if (!/^[A-Z]{3}$/.test(iso3) || !crop) throw new Error('iso3 and crop are required.');

  const areaHa = finite(p.areaHa);
  const manualYieldTonsHa = finite(p.yieldTonsHa);
  const gaezYield = manualYieldTonsHa == null ? await getGaezYieldFromSuitability(iso3, crop) : {available:false, source:'manual_override'};
  const yieldTonsHa = manualYieldTonsHa != null ? manualYieldTonsHa : (gaezYield.available ? gaezYield.yieldTonsHa : null);
  const pricePerTon = finite(p.pricePerTon);
  const capex = finite(p.capex);
  const annualOpex = finite(p.annualOpex);
  const otherAnnualRevenue = finite(p.otherAnnualRevenue) || 0;

  const missing = [];
  for (const [name, value] of Object.entries({areaHa,yieldTonsHa,pricePerTon,capex,annualOpex})) {
    if (value == null || value < 0) missing.push(name);
  }

  const annualProductionTons =
    areaHa != null && yieldTonsHa != null ? areaHa * yieldTonsHa : null;
  const cropRevenue =
    annualProductionTons != null && pricePerTon != null
      ? annualProductionTons * pricePerTon : null;
  const annualRevenue =
    cropRevenue != null ? cropRevenue + otherAnnualRevenue : null;
  const annualOperatingProfit =
    annualRevenue != null && annualOpex != null ? annualRevenue - annualOpex : null;
  const simplePaybackYears =
    annualOperatingProfit != null && annualOperatingProfit > 0 && capex != null
      ? capex / annualOperatingProfit : null;
  const breakEvenPrice =
    annualProductionTons != null && annualProductionTons > 0 && annualOpex != null
      ? annualOpex / annualProductionTons : null;

  const evidenceSnap = await db.collection('auren_feasibility_evidence')
    .where('iso3','==',iso3).orderBy('generatedAt','desc').limit(1).get();
  const evidence = evidenceSnap.empty ? null : evidenceSnap.docs[0].data();

  const scenarios = [0.8, 1.0, 1.2].map(multiplier => {
    const revenue = cropRevenue == null ? null : cropRevenue * multiplier + otherAnnualRevenue;
    const profit = revenue == null || annualOpex == null ? null : revenue - annualOpex;
    return {
      priceScenario: multiplier === 1 ? 'base' : multiplier < 1 ? 'downside' : 'upside',
      priceMultiplier: multiplier,
      annualRevenue: revenue,
      annualOperatingProfit: profit
    };
  });

  const result = {
    status: missing.length ? 'needs_inputs' : 'calculated',
    iso3, crop, inputs:{areaHa,yieldTonsHa,pricePerTon,capex,annualOpex,otherAnnualRevenue},
    yieldSource: manualYieldTonsHa != null ? 'manual' : (gaezYield.available ? gaezYield.source : null),
    yieldEvidence: gaezYield.available ? {unit:gaezYield.unit, samples:gaezYield.samples} : null,
    missing,
    outputs:{annualProductionTons,cropRevenue,annualRevenue,annualOperatingProfit,simplePaybackYears,breakEvenPrice},
    scenarios,
    evidenceAvailable: !!evidence,
    evidenceSummary: evidence ? evidence.evidenceQuality : null,
    assumptions: [
      'Manual yieldTonsHa overrides GAEZ evidence. GAEZ yield is used only when stored evidence explicitly declares a yield-per-hectare unit.',
      'This is a preliminary screening model; taxes, financing, depreciation, working capital, logistics, FX, inflation and detailed cash flow are not included unless supplied.',
      'A positive simple operating profit does not guarantee investment viability.'
    ],
    generatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection('auren_agri_financial_feasibility').add({
    uid:request.auth.uid, ...result
  });

  return result;
});
