const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const db = admin.firestore();

const FAO_PP_SQL_URL =
  'https://data.apps.fao.org/catalog/dataset/ab62e545-a3ce-44d7-ab0d-9728cb638cc2/resource/d30487a2-82f2-4f97-a711-935d64eab444/download/prices-pp-producer-prices-query.sql';
const FAO_PP_API_BASE = 'https://api.data.apps.fao.org/api/v2/bigquery';

const COMMON_FAOSTAT_ITEM_CODES = Object.freeze({
  sorghum: 83,
  maize: 56,
  wheat: 15,
  rice: 27,
  millet: 79,
  barley: 44,
  soybean: 236,
  groundnut: 242,
  sesame: 244,
  cotton: 328,
  sugarcane: 156,
  tomato: 388,
  onion: 403,
  potato: 116,
  cassava: 125,
});

function officialUrl(value) {
  const u = new URL(value);
  if (!['https:', 'http:'].includes(u.protocol) ||
      !['api.data.apps.fao.org', 'data.apps.fao.org'].includes(u.hostname)) {
    throw new Error('Only official FAO price resources are allowed.');
  }
  return u;
}

function normalizeText(v) {
  return String(v || '').trim().toLowerCase();
}

function parseCsv(text) {
  const lines = String(text || '').split(/\r?\n/).filter(Boolean);
  if (!lines.length) return [];
  const parseLine = (line) => {
    const out=[]; let cur=''; let quoted=false;
    for (let i=0;i<line.length;i++) {
      const ch=line[i];
      if (ch === '"') {
        if (quoted && line[i+1] === '"') { cur+='"'; i++; }
        else quoted=!quoted;
      } else if (ch === ',' && !quoted) { out.push(cur); cur=''; }
      else cur+=ch;
    }
    out.push(cur);
    return out;
  };
  const header=parseLine(lines[0]).map(v=>v.trim());
  return lines.slice(1).map(line=>{
    const values=parseLine(line);
    const row={};
    header.forEach((h,i)=>{ row[h]=values[i] ?? ''; });
    return row;
  });
}

async function fetchProducerPrices({itemCode, frequency='monthly', country=''}={}) {
  const u=officialUrl(FAO_PP_API_BASE);
  u.searchParams.set('download','true');
  u.searchParams.set('frequency',frequency);
  if (itemCode) u.searchParams.set('item_code',String(itemCode));
  u.searchParams.set('sql_url',FAO_PP_SQL_URL);

  const res=await fetch(u, {
    headers:{accept:'text/csv,text/plain,application/json'},
    signal:AbortSignal.timeout(60000)
  });
  const body=await res.text();
  if (!res.ok) throw new Error('FAO producer-price request failed: '+res.status);

  const rows=parseCsv(body);
  const wanted=normalizeText(country);
  const filtered=wanted
    ? rows.filter(r=>normalizeText(r.country_name_en)===wanted)
    : rows;

  return {
    source:'FAOSTAT Agricultural Producer Prices',
    catalogUrl:'https://data.fao.org/catalog/dataset/47c17894-8ca1-4bd0-ba4d-6078e919e9b1',
    frequency,
    itemCode:itemCode ? Number(itemCode) : null,
    country:country || null,
    rows:filtered
  };
}

exports.aurenAgriProducerPrices = onCall(async (request)=>{
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p=request.data||{};
  const crop=normalizeText(p.crop);
  const itemCode=Number(p.itemCode) || COMMON_FAOSTAT_ITEM_CODES[crop] || null;
  if (!itemCode) {
    throw new Error('Provide itemCode or a supported crop name.');
  }

  const result=await fetchProducerPrices({
    itemCode,
    frequency:String(p.frequency||'monthly').toLowerCase()==='annual'?'annual':'monthly',
    country:String(p.country||'')
  });

  return {
    status:result.rows.length?'ok':'no_matching_rows',
    ...result,
    latest:result.rows.slice().sort((a,b)=>String(b.date||'').localeCompare(String(a.date||''))).slice(0,12)
  };
});

exports.aurenAgriProducerPriceCache = onCall(async (request)=>{
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const p=request.data||{};
  const crop=normalizeText(p.crop);
  const itemCode=Number(p.itemCode) || COMMON_FAOSTAT_ITEM_CODES[crop] || null;
  if (!itemCode) throw new Error('Provide itemCode or a supported crop name.');

  const result=await fetchProducerPrices({
    itemCode,
    frequency:String(p.frequency||'monthly').toLowerCase()==='annual'?'annual':'monthly',
    country:String(p.country||'')
  });

  const batch=db.batch();
  for (const row of result.rows.slice(-1000)) {
    const id=[row.m49_code,row.item_code,row.date,row.frequency].join('_').replace(/[^a-zA-Z0-9_-]/g,'_');
    batch.set(db.collection('auren_agri_producer_prices').doc(id), {
      source:result.source,
      countryKey:String(row.m49_code||''),
      countryName:String(row.country_name_en||''),
      itemCode:Number(row.item_code||itemCode),
      item:String(row.item||''),
      date:String(row.date||''),
      frequency:String(row.frequency||''),
      priceLCUTonne:row.producer_price_lcu_tonne_lcu===''?null:Number(row.producer_price_lcu_tonne_lcu),
      priceUSDTonne:row.producer_price_usd_tonne_usd===''?null:Number(row.producer_price_usd_tonne_usd),
      priceIndex:row.producer_price_index_20142016_100_===''?null:Number(row.producer_price_index_20142016_100_),
      importedAt:admin.firestore.FieldValue.serverTimestamp()
    },{merge:true});
  }
  if (result.rows.length) await batch.commit();

  return {status:'cached',source:result.source,itemCode,resultRows:result.rows.length};
});


// FPMA/GIEWS local-market adapter.
// The FPMA web application is dynamic; keep the machine-readable source configurable
// and restricted to official FAO hosts until FAO exposes a stable public export URL.
const FPMA_DATA_URL = process.env.FPMA_DATA_URL || '';

function officialFpmaUrl(value) {
  const u = new URL(value);
  const allowed = new Set(['fpma.fao.org', 'www.fao.org']);
  if (!['https:', 'http:'].includes(u.protocol) || !allowed.has(u.hostname)) {
    throw new Error('Only official FAO/FPMA resources are allowed.');
  }
  return u;
}

function normalizeFpmaRow(row) {
  const pick = (...keys) => {
    for (const key of keys) {
      if (row[key] !== undefined && row[key] !== null && String(row[key]).trim() !== '') return row[key];
    }
    return '';
  };
  const numberOrNull = (v) => {
    if (v === '' || v === null || v === undefined) return null;
    const n = Number(String(v).replace(/,/g, ''));
    return Number.isFinite(n) ? n : null;
  };
  const countryName = String(pick('country_name_en','country','Country','country_name') || '').trim();
  const item = String(pick('item','commodity','Commodity','commodity_name','item_name') || '').trim();
  const market = String(pick('market','Market','market_name') || '').trim();
  const date = String(pick('date','Date','period','Period','month') || '').trim();
  const price = numberOrNull(pick('price','Price','value','Value','price_lcu','price_local'));
  const unit = String(pick('unit','Unit','measure_unit') || '').trim();
  const currency = String(pick('currency','Currency','currency_code') || '').trim();
  const frequency = String(pick('frequency','Frequency') || 'monthly').trim().toLowerCase();
  return {
    countryName, item, market, date, priceLCU: price, unit, currency,
    frequency, source: 'FAO GIEWS FPMA'
  };
}

async function fetchFpmaRows() {
  if (!FPMA_DATA_URL) {
    throw new Error('FPMA_DATA_URL is not configured. Configure an official FAO/FPMA CSV or JSON export URL before ingestion.');
  }
  const url = officialFpmaUrl(FPMA_DATA_URL);
  const res = await fetch(url, {
    headers: {accept:'text/csv,application/json,text/plain'},
    signal: AbortSignal.timeout(60000)
  });
  const body = await res.text();
  if (!res.ok) throw new Error('FPMA request failed: ' + res.status);
  let rows;
  try {
    rows = JSON.parse(body);
    if (!Array.isArray(rows)) rows = rows.data || rows.rows || [];
  } catch (_) {
    rows = parseCsv(body);
  }
  if (!Array.isArray(rows)) throw new Error('FPMA response is not a supported CSV/JSON table.');
  return rows.map(normalizeFpmaRow).filter(r => r.countryName && r.item && r.date);
}

exports.aurenAgriLocalMarketPriceIngest = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const rows = await fetchFpmaRows();
  const country = normalizeText(request.data?.country);
  const crop = normalizeText(request.data?.crop);
  const filtered = rows.filter(r =>
    (!country || normalizeText(r.countryName) === country) &&
    (!crop || normalizeText(r.item) === crop)
  );
  const batch = db.batch();
  let written = 0;
  for (const row of filtered.slice(-2000)) {
    const id = [row.countryName,row.item,row.market,row.date,row.unit]
      .join('_').replace(/[^a-zA-Z0-9_-]/g,'_').slice(0, 300);
    batch.set(db.collection('auren_agri_local_market_prices').doc(id), {
      ...row,
      priceUSDTonne: null,
      importedAt: admin.firestore.FieldValue.serverTimestamp()
    }, {merge:true});
    written++;
  }
  if (written) await batch.commit();
  return {
    status: written ? 'cached' : 'no_matching_rows',
    source: 'FAO GIEWS FPMA',
    configured: true,
    fetchedRows: rows.length,
    writtenRows: written
  };
});

exports.aurenAgriLocalMarketPriceStatus = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const snap = await db.collection('auren_agri_local_market_prices').limit(1).get();
  return {
    source: 'FAO GIEWS FPMA',
    configured: Boolean(FPMA_DATA_URL),
    cached: !snap.empty,
    officialTool: 'https://fpma.fao.org/'
  };
});
