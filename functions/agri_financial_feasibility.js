'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

function finite(v) { const n = Number(v); return Number.isFinite(n) ? n : null; }

exports.aurenAgriFinancialFeasibility = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p = request.data || {};
  const iso3 = String(p.iso3 || '').trim().toUpperCase();
  const crop = String(p.crop || '').trim();
  if (!/^[A-Z]{3}$/.test(iso3) || !crop) throw new Error('iso3 and crop are required.');

  const areaHa = finite(p.areaHa);
  const yieldTonsHa = finite(p.yieldTonsHa);
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
    missing,
    outputs:{annualProductionTons,cropRevenue,annualRevenue,annualOperatingProfit,simplePaybackYears,breakEvenPrice},
    scenarios,
    evidenceAvailable: !!evidence,
    evidenceSummary: evidence ? evidence.evidenceQuality : null,
    assumptions: [
      'Yield, selling price, CAPEX and OPEX are user/project inputs unless sourced separately.',
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
