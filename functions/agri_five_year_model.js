'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

function n(v, fallback=0) {
  const x = Number(v);
  return Number.isFinite(x) ? x : fallback;
}

function npv(rate, cashflows) {
  return cashflows.reduce((sum, cf, t) => sum + cf / Math.pow(1 + rate, t), 0);
}

function irr(cashflows) {
  let lo = -0.99, hi = 5;
  if (npv(lo, cashflows) * npv(hi, cashflows) > 0) return null;
  for (let i = 0; i < 100; i++) {
    const mid = (lo + hi) / 2;
    if (npv(mid, cashflows) > 0) lo = mid; else hi = mid;
  }
  return (lo + hi) / 2;
}

exports.aurenAgriFiveYearModel = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p = request.data || {};
  const iso3 = String(p.iso3 || '').trim().toUpperCase();
  const crop = String(p.crop || '').trim();
  if (!/^[A-Z]{3}$/.test(iso3) || !crop) throw new Error('iso3 and crop are required.');

  const areaHa = n(p.areaHa);
  const yieldTonsHa = n(p.yieldTonsHa);
  const pricePerTon = n(p.pricePerTon);
  const capex = n(p.capex);
  const opexYear1 = n(p.annualOpex);
  const priceGrowth = n(p.priceGrowth, 0);
  const opexGrowth = n(p.opexGrowth, 0);
  const yieldGrowth = n(p.yieldGrowth, 0);
  const inflation = n(p.inflation, 0);
  const taxRate = Math.min(Math.max(n(p.taxRate, 0), 0), 1);
  const discountRate = Math.max(n(p.discountRate, 0.1), 0.0001);
  const financingRate = Math.max(n(p.financingRate, 0), 0);
  const debtShare = Math.min(Math.max(n(p.debtShare, 0), 0), 1);
  const workingCapital = n(p.workingCapital);

  const rows = [];
  let totalProfit = 0;
  let cumulativeCash = -capex - workingCapital;

  for (let year = 1; year <= 5; year++) {
    const production = areaHa * yieldTonsHa * Math.pow(1 + yieldGrowth, year - 1);
    const price = pricePerTon * Math.pow(1 + priceGrowth, year - 1);
    const revenue = production * price;
    const opex = opexYear1 * Math.pow(1 + opexGrowth + inflation, year - 1);
    const interest = capex * debtShare * financingRate;
    const taxable = Math.max(0, revenue - opex - interest);
    const tax = taxable * taxRate;
    const operatingProfit = revenue - opex - interest - tax;
    cumulativeCash += operatingProfit;
    totalProfit += operatingProfit;
    rows.push({year, production, price, revenue, opex, interest, tax, operatingProfit, cumulativeCash});
  }

  const cashflows = [-capex - workingCapital, ...rows.map(r => r.operatingProfit)];
  const projectNpv = npv(discountRate, cashflows);
  const projectIrr = irr(cashflows);
  const paybackYear = rows.find(r => r.cumulativeCash >= 0)?.year || null;

  const result = {
    status:'calculated',
    iso3, crop,
    inputs:{areaHa,yieldTonsHa,pricePerTon,capex,opexYear1,priceGrowth,opexGrowth,yieldGrowth,inflation,taxRate,discountRate,financingRate,debtShare,workingCapital},
    years:rows,
    summary:{
      totalOperatingProfit:totalProfit,
      npv:projectNpv,
      irr:projectIrr,
      simplePaybackYear:paybackYear
    },
    scenarios:[
      {name:'downside', priceMultiplier:0.8, yieldMultiplier:0.8},
      {name:'base', priceMultiplier:1, yieldMultiplier:1},
      {name:'upside', priceMultiplier:1.2, yieldMultiplier:1.1}
    ],
    notes:[
      'Model is a planning calculation, not investment advice or a certified financial model.',
      'Tax, financing, inflation and working-capital assumptions are user inputs unless independently sourced.',
      'NPV/IRR are sensitive to the supplied discount rate, price, yield and cost assumptions.'
    ],
    generatedAt:admin.firestore.FieldValue.serverTimestamp()
  };

  await db.collection('auren_agri_five_year_models').add({uid:request.auth.uid, ...result});
  return result;
});
