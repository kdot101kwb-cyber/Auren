'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

function finite(v) {
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function cropSlug(crop) {
  return String(crop || '').toLowerCase().replace(/[^a-z0-9]+/g, '_');
}

function normalizeText(v) {
  return String(v || '').trim().toLowerCase().replace(/\s+/g, ' ');
}

function normalizeYieldEvidence(samples) {
  const accepted = [];
  for (const sample of Array.isArray(samples) ? samples : []) {
    const value = finite(sample?.value);
    const units = String(sample?.units || '').trim().toLowerCase();
    if (value == null || value < 0 || !units) continue;
    if (/^(t\/?ha|tonnes?\s*per\s*ha|tons?\s*per\s*ha)$/.test(units)
        || units.includes('ton/ha') || units.includes('t/ha')) {
      accepted.push({
        value,
        units: sample.units,
        resource: sample.resource || null
      });
    }
  }
  if (!accepted.length) return null;
  const value = accepted.reduce((sum, item) => sum + item.value, 0) / accepted.length;
  return {yieldTonsHa:value, unit:'t/ha', samples:accepted};
}

function extractProducerPrice(rows, crop) {
  const target = normalizeText(crop);
  const candidates = (Array.isArray(rows) ? rows : []).filter(row => {
    const item = normalizeText(row?.Item ?? row?.item ?? row?.Item_Name ?? row?.item_name);
    const element = normalizeText(row?.Element ?? row?.element);
    const unit = normalizeText(row?.Unit ?? row?.unit);
    return item
      && (item === target || item.includes(target) || target.includes(item))
      && (!element || element.includes('producer price') || element.includes('producer'))
      && (unit.includes('usd') || unit.includes('us$') || unit.includes('$'))
      && (unit.includes('/t') || unit.includes('ton') || unit.includes('tonne'));
  });

  const priced = candidates.map(row => ({
    value: finite(row?.Value ?? row?.value ?? row?.Price ?? row?.price),
    year: finite(row?.Year ?? row?.year),
    unit: row?.Unit ?? row?.unit ?? null,
    item: row?.Item ?? row?.item ?? null
  })).filter(x => x.value != null && x.value >= 0);

  priced.sort((a,b) => (b.year || 0) - (a.year || 0));
  return priced[0] || null;
}

async function getFaostatProducerPrice(iso3, crop) {
  const snap = await db.collection('auren_faostat').doc(iso3 + '_PP').get();
  if (!snap.exists) return {available:false, source:'FAOSTAT_PP', reason:'no_price_domain_ingested'};
  const data = snap.data() || {};
  const match = extractProducerPrice(data.data, crop);
  if (!match) return {available:false, source:'FAOSTAT_PP', reason:'no_explicit_usd_per_ton_match'};
  return {
    available:true,
    source:'FAOSTAT_producer_price',
    pricePerTon:match.value,
    currency:'USD',
    unit:match.unit,
    year:match.year,
    item:match.item
  };
}

async function getGaezYieldFromSuitability(iso3, crop) {
  const ref = db.collection('auren_agri_suitability').doc(iso3 + '_' + cropSlug(crop));
  const snap = await ref.get();
  if (!snap.exists) {
    return {available:false, source:'gaez_suitability_document', reason:'no_suitability_result'};
  }
  const data = snap.data() || {};
  const normalized = normalizeYieldEvidence(data.gaezEvidence?.samples);
  if (!normalized) {
    return {
      available:false,
      source:'gaez_suitability_document',
      reason:'units_not_explicitly_yield_per_hectare'
    };
  }
  return {available:true, source:'FAO_GAEZ_evidence', ...normalized};
}

async function getLogisticsEvidence(iso3) {
  const snap = await db.collection('auren_agri_logistics_evidence').doc(iso3).get();
  if (!snap.exists) {
    return {available:false, source:'World Bank Logistics Performance Index', reason:'no_logistics_evidence_ingested'};
  }
  const data = snap.data() || {};
  const items = Array.isArray(data.items) ? data.items : [];
  const accepted = items.filter(item =>
    item?.indicator
    && item?.code
    && finite(item?.value) != null
    && item?.source
  );
  return accepted.length
    ? {available:true, source:'World Bank Logistics Performance Index', items:accepted}
    : {available:false, source:'World Bank Logistics Performance Index', reason:'logistics_records_require_indicator_code_value_and_source'};
}

async function getCostEvidence(iso3, crop) {
  const snap = await db.collection('auren_agri_cost_evidence').doc(
    iso3 + '_' + cropSlug(crop)
  ).get();

  if (!snap.exists) {
    return {
      available:false,
      source:'auren_agri_cost_evidence',
      reason:'no_explicit_cost_evidence_ingested'
    };
  }

  const data = snap.data() || {};
  const items = Array.isArray(data.items) ? data.items : [];
  const accepted = items.filter(item =>
    finite(item?.value) != null
    && finite(item?.value) >= 0
    && item?.currency
    && item?.unit
    && item?.source
  );

  return accepted.length
    ? {available:true, source:'explicit_cost_evidence', items:accepted}
    : {
      available:false,
      source:'auren_agri_cost_evidence',
      reason:'cost_records_require_value_currency_unit_and_source'
    };
}

exports.aurenAgriFinancialFeasibility = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p = request.data || {};
  const iso3 = String(p.iso3 || '').trim().toUpperCase();
  const crop = String(p.crop || '').trim();
  if (!/^[A-Z]{3}$/.test(iso3) || !crop) {
    throw new Error('iso3 and crop are required.');
  }

  const areaHa = finite(p.areaHa);
  const manualYieldTonsHa = finite(p.yieldTonsHa);
  const gaezYield = manualYieldTonsHa == null
    ? await getGaezYieldFromSuitability(iso3, crop)
    : {available:false, source:'manual_override'};
  const yieldTonsHa = manualYieldTonsHa != null
    ? manualYieldTonsHa
    : (gaezYield.available ? gaezYield.yieldTonsHa : null);

  const manualPricePerTon = finite(p.pricePerTon);
  const faostatPrice = manualPricePerTon == null
    ? await getFaostatProducerPrice(iso3, crop)
    : {available:false, source:'manual_override'};
  const pricePerTon = manualPricePerTon != null
    ? manualPricePerTon
    : (faostatPrice.available ? faostatPrice.pricePerTon : null);

  const capex = finite(p.capex);
  const annualOpex = finite(p.annualOpex);
  const otherAnnualRevenue = finite(p.otherAnnualRevenue) || 0;
  const [costEvidence, logisticsEvidence] = await Promise.all([getCostEvidence(iso3, crop), getLogisticsEvidence(iso3)]);

  const missing = [];
  for (const [name, value] of Object.entries({
    areaHa, yieldTonsHa, pricePerTon, capex, annualOpex
  })) {
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
    annualRevenue != null && annualOpex != null
      ? annualRevenue - annualOpex : null;
  const simplePaybackYears =
    annualOperatingProfit != null && annualOperatingProfit > 0 && capex != null
      ? capex / annualOperatingProfit : null;
  const breakEvenPrice =
    annualProductionTons != null && annualProductionTons > 0 && annualOpex != null
      ? annualOpex / annualProductionTons : null;

  const evidenceSnap = await db.collection('auren_feasibility_evidence')
    .where('iso3','==',iso3)
    .orderBy('generatedAt','desc')
    .limit(1)
    .get();
  const evidence = evidenceSnap.empty ? null : evidenceSnap.docs[0].data();

  const scenarios = [0.8, 1.0, 1.2].map(multiplier => {
    const revenue = cropRevenue == null
      ? null : cropRevenue * multiplier + otherAnnualRevenue;
    const profit = revenue == null || annualOpex == null
      ? null : revenue - annualOpex;
    return {
      priceScenario: multiplier === 1 ? 'base' : multiplier < 1 ? 'downside' : 'upside',
      priceMultiplier: multiplier,
      annualRevenue: revenue,
      annualOperatingProfit: profit
    };
  });

  const result = {
    status: missing.length ? 'needs_inputs' : 'calculated',
    iso3,
    crop,
    inputs:{areaHa,yieldTonsHa,pricePerTon,capex,annualOpex,otherAnnualRevenue},
    yieldSource: manualYieldTonsHa != null
      ? 'manual'
      : (gaezYield.available ? gaezYield.source : null),
    yieldEvidence: gaezYield.available
      ? {unit:gaezYield.unit, samples:gaezYield.samples}
      : null,
    priceSource: manualPricePerTon != null
      ? 'manual'
      : (faostatPrice.available ? faostatPrice.source : null),
    priceEvidence: faostatPrice.available
      ? {
        currency:faostatPrice.currency,
        unit:faostatPrice.unit,
        year:faostatPrice.year,
        item:faostatPrice.item
      }
      : null,
    costEvidence,
    logisticsEvidence,
    costEvidenceLedger: {
      capex: {
        evidenceType: 'manual',
        value: capex,
        currency: p.capexCurrency || null,
        unit: p.capexUnit || null,
        source: p.capexSource || null,
        year: finite(p.capexYear),
        note: 'Manual project input unless replaced by explicit sourced cost evidence.'
      },
      opex: {
        evidenceType: 'manual',
        value: annualOpex,
        currency: p.opexCurrency || null,
        unit: p.opexUnit || null,
        source: p.opexSource || null,
        year: finite(p.opexYear),
        note: 'Manual project input unless replaced by explicit sourced cost evidence.'
      },
      logistics: {
        evidenceType: 'manual',
        value: finite(p.logisticsCost),
        currency: p.logisticsCurrency || null,
        unit: p.logisticsUnit || null,
        source: p.logisticsSource || null,
        year: finite(p.logisticsYear),
        note: 'LPI is evidence about logistics performance, not a monetary freight cost.'
      },
      sourcedItems: costEvidence.available ? costEvidence.items.map(item => ({
        evidenceType:'sourced',
        category:item.category || null,
        value:finite(item.value),
        currency:item.currency || null,
        unit:item.unit || null,
        source:item.source || null,
        year:finite(item.year ?? item.date)
      })) : []
    },
    missing,
    outputs:{
      annualProductionTons,
      cropRevenue,
      annualRevenue,
      annualOperatingProfit,
      simplePaybackYears,
      breakEvenPrice
    },
    scenarios,
    evidenceAvailable: !!evidence,
    evidenceSummary: evidence ? evidence.evidenceQuality : null,
    assumptions:[
      'Manual yieldTonsHa overrides GAEZ evidence. GAEZ yield is used only when stored evidence explicitly declares a yield-per-hectare unit.',
      'Manual pricePerTon overrides FAOSTAT. FAOSTAT price is used only when the ingested producer-price row explicitly provides a USD-per-ton unit; local-currency prices are not converted implicitly.',
      'CAPEX and OPEX remain manual unless an explicit cost-evidence record provides value, currency, unit and source.',
      'Logistics performance evidence from the World Bank LPI is reported separately and is not converted into a monetary cost. Monetary logistics costs remain manual unless an explicit logistics-cost record is supplied; farm-gate producer prices do not include transport beyond the farm gate.',
      'This is a preliminary screening model; taxes, financing, depreciation, working capital, logistics, FX, inflation and detailed cash flow are not included unless supplied.',
      'A positive simple operating profit does not guarantee investment viability.'
    ],
    generatedAt:admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection('auren_agri_financial_feasibility').add({
    uid:request.auth.uid,
    ...result
  });

  return result;
});
