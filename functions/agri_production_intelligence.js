const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const db = admin.firestore();

function auth(request) {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
}

function clean(v, max = 120) {
  return String(v ?? '').trim().slice(0, max);
}

function num(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(String(v).replace(/,/g, ''));
  return Number.isFinite(n) ? n : null;
}

function normalizeRow(row) {
  const pick = (...keys) => keys.map(k => row?.[k]).find(v => v !== undefined && v !== null && String(v).trim() !== '');
  const iso3 = clean(pick('iso3','ISO3','country_iso3','country_code_iso3'), 3).toUpperCase();
  const country = clean(pick('country','country_name','country_name_en','Area'), 160);
  const item = clean(pick('item','Item','commodity','crop','Item Name'), 160);
  const year = Number(pick('year','Year','period','Period'));
  const production = num(pick('production','Production','value','Value'));
  const yieldValue = num(pick('yield','Yield','yield_value'));
  const area = num(pick('area','Area','area_harvested','Area harvested'));
  const unit = clean(pick('unit','Unit','element_unit'), 60);
  return {iso3,country,item,year,production,yieldValue,area,unit,source:'FAOSTAT Production Crops and Livestock Products'};
}

function rowId(r) {
  return [r.iso3 || r.country,r.item,r.year].join('_').replace(/[^a-zA-Z0-9_-]/g,'_').slice(0,300);
}

exports.aurenAgriProductionHistoryUpsert = onCall(async request => {
  auth(request);
  const rows = Array.isArray(request.data?.rows) ? request.data.rows : [];
  if (!rows.length) throw new Error('rows is required.');
  const normalized = rows.map(normalizeRow).filter(r => r.item && Number.isFinite(r.year));
  const batch = db.batch();
  for (const r of normalized.slice(0, 2000)) {
    batch.set(db.collection('auren_agri_production_history').doc(rowId(r)), {
      ...r,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge:true});
  }
  if (normalized.length) await batch.commit();
  return {status:'cached', count:Math.min(normalized.length,2000), source:'FAOSTAT Production Crops and Livestock Products'};
});

exports.aurenAgriProductionHistory = onCall(async request => {
  auth(request);
  const iso3 = clean(request.data?.iso3 || request.data?.country, 3).toUpperCase();
  const item = clean(request.data?.item || request.data?.crop, 160).toLowerCase();
  const fromYear = Number(request.data?.fromYear || 0);
  const toYear = Number(request.data?.toYear || 9999);
  const limit = Math.min(Math.max(Number(request.data?.limit) || 100,1),500);
  let snap = await db.collection('auren_agri_production_history').limit(1000).get();
  let rows = snap.docs.map(d => ({id:d.id,...d.data()}));
  rows = rows.filter(r =>
    (!iso3 || String(r.iso3 || '').toUpperCase() === iso3) &&
    (!item || String(r.item || '').toLowerCase() === item) &&
    Number(r.year) >= fromYear && Number(r.year) <= toYear
  );
  rows.sort((a,b) => Number(a.year)-Number(b.year));
  return {status:rows.length ? 'ok':'no_data', rows:rows.slice(0,limit), count:rows.length};
});

exports.aurenAgriProductionSummary = onCall(async request => {
  auth(request);
  const iso3 = clean(request.data?.iso3 || request.data?.country,3).toUpperCase();
  const item = clean(request.data?.item || request.data?.crop,160).toLowerCase();
  const snap = await db.collection('auren_agri_production_history').limit(2000).get();
  const rows = snap.docs.map(d => d.data()).filter(r =>
    (!iso3 || String(r.iso3||'').toUpperCase()===iso3) &&
    (!item || String(r.item||'').toLowerCase()===item)
  ).sort((a,b)=>Number(b.year)-Number(a.year));
  const latest = rows[0] || null;
  return {
    status:latest?'ok':'no_data',
    latest,
    years:rows.length,
    minYear:rows.length?Math.min(...rows.map(r=>Number(r.year))):null,
    maxYear:rows.length?Math.max(...rows.map(r=>Number(r.year))):null
  };
});
