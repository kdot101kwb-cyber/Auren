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
      countryIso3:String(row.iso3 || row.country_iso3 || row.iso3_code || '').toUpperCase(),
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
// FPMA data may be reported in different native units/currencies. Preserve the
// native observation and only populate a canonical USD/tonne value when an
// explicit conversion is supplied; never invent FX or unit factors.
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
  const iso3 = String(pick('iso3','ISO3','country_iso3','country_code_iso3') || '').trim().toUpperCase();
  const item = String(pick('item','commodity','Commodity','commodity_name','item_name') || '').trim();
  const market = String(pick('market','Market','market_name') || '').trim();
  const region = String(pick('region','Region','state','province') || '').trim();
  const city = String(pick('city','City','town','market_city') || '').trim();
  const date = String(pick('date','Date','period','Period','month') || '').trim();
  const price = numberOrNull(pick('price','Price','value','Value','price_lcu','price_local'));
  const unit = String(pick('unit','Unit','measure_unit') || '').trim();
  const currency = String(pick('currency','Currency','currency_code') || '').trim().toUpperCase();
  const frequency = String(pick('frequency','Frequency') || 'monthly').trim().toLowerCase();
  const unitKey = unit.toLowerCase().replace(/\\s+/g, ' ').trim();
  const tonneFactor = ({
    't': 1, 'tonne': 1, 'tonnes': 1, 'metric ton': 1, 'metric tons': 1,
    'kg': 1000, 'kilogram': 1000, 'kilograms': 1000,
    'g': 1000000, 'gram': 1000000, 'grams': 1000000,
    'lb': 2204.62262185, 'lbs': 2204.62262185, 'pound': 2204.62262185, 'pounds': 2204.62262185,
    'quintal': 10, 'quintals': 10, 'q': 10
  })[unitKey] ?? null;
  const priceLCUTonne = price !== null && tonneFactor !== null ? price * tonneFactor : null;
  const nativeUnitCanonical = tonneFactor !== null ? 'tonne' : unit;
  const usdPrice = numberOrNull(pick('price_usd_tonne','price_usd_per_tonne','usd_per_tonne','price_usd'));
  return {
    countryName, iso3, item, market, region, city, date,
    priceLCU: price, unit, nativeUnitCanonical, priceLCUTonne, currency, frequency,
    priceUSDTonne: currency === 'USD' && priceLCUTonne !== null ? priceLCUTonne : usdPrice,
    conversionStatus: currency === 'USD' && priceLCUTonne !== null ? 'unit_converted' : usdPrice !== null ? 'source_usd' : 'currency_not_converted',
    source: 'FAO GIEWS FPMA'
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
    (!country || normalizeText(r.countryName) === country || normalizeText(r.iso3) === country) &&
    (!crop || normalizeText(r.item) === crop)
  );
  const batch = db.batch();
  let written = 0;
  for (const row of filtered.slice(-2000)) {
    const id = [row.iso3 || row.countryName,row.item,row.market,row.city,row.date,row.unit]
      .join('_').replace(/[^a-zA-Z0-9_-]/g,'_').slice(0, 300);
    batch.set(db.collection('auren_agri_local_market_prices').doc(id), {
      ...row,
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

    
// FAOSTAT exchange-rate bridge.
// FX is sourced only from FAOSTAT-provided observations when the caller supplies
// an official machine-readable export URL. No third-party FX provider is used.
const FAOSTAT_FX_DATA_URL = process.env.FAOSTAT_FX_DATA_URL || '';

function officialFaostatFxUrl(value) {
  const u = new URL(value);
  const allowed = new Set(['fenixservices.fao.org','faostat.fao.org','api.fao.org','api.data.apps.fao.org','data.apps.fao.org']);
  if (!['https:','http:'].includes(u.protocol) || !allowed.has(u.hostname)) {
    throw new Error('Only official FAOSTAT resources are allowed for FX.');
  }
  return u;
}

function normalizeFxRow(row) {
  const pick=(...keys)=>{ for(const k of keys){ if(row[k]!==undefined && row[k]!==null && String(row[k]).trim()!=='') return row[k]; } return ''; };
  const rate=Number(String(pick('rate','exchange_rate','Exchange Rate','value','Value')).replace(/,/g,''));
  return {
    countryName:String(pick('country_name_en','country','Country','area_name')||'').trim(),
    iso3:String(pick('iso3','ISO3','country_iso3','area_code_iso3')||'').trim().toUpperCase(),
    currency:String(pick('currency','Currency','currency_code')||'').trim().toUpperCase(),
    date:String(pick('date','Date','year','Year','period','Period')||'').trim(),
    usdPerLocalUnit:Number.isFinite(rate) ? rate : null,
    source:'FAOSTAT Exchange Rates'
  };
}

async function fetchFaostatFxRows() {
  if (!FAOSTAT_FX_DATA_URL) throw new Error('FAOSTAT_FX_DATA_URL is not configured.');
  const url=officialFaostatFxUrl(FAOSTAT_FX_DATA_URL);
  const res=await fetch(url,{headers:{accept:'text/csv,application/json,text/plain'},signal:AbortSignal.timeout(60000)});
  const body=await res.text();
  if(!res.ok) throw new Error('FAOSTAT FX request failed: '+res.status);
  let rows;
  try { rows=JSON.parse(body); if(!Array.isArray(rows)) rows=rows.data||rows.rows||[]; }
  catch(_) { rows=parseCsv(body); }
  if(!Array.isArray(rows)) throw new Error('FAOSTAT FX response is not a supported table.');
  return rows.map(normalizeFxRow).filter(r=>r.iso3 && r.currency && r.usdPerLocalUnit!==null);
}

exports.aurenAgriFxStatus = onCall(async (request)=>{
  if(!request.auth?.uid) throw new Error('Authentication is required.');
  return {source:'FAOSTAT Exchange Rates',configured:Boolean(FAOSTAT_FX_DATA_URL),cached:!(await db.collection('auren_agri_fx_rates').limit(1).get()).empty};
});

exports.aurenAgriFxIngest = onCall(async (request)=>{
  if(!request.auth?.uid) throw new Error('Authentication is required.');
  const rows=await fetchFaostatFxRows();
  const batch=db.batch();
  for(const row of rows.slice(-5000)) {
    const id=[row.iso3,row.currency,row.date].join('_').replace(/[^a-zA-Z0-9_-]/g,'_');
    batch.set(db.collection('auren_agri_fx_rates').doc(id),{...row,importedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
  }
  if(rows.length) await batch.commit();
  return {status:rows.length?'cached':'no_data',count:rows.length,source:'FAOSTAT Exchange Rates'};
});

function convertLocalPriceToUsdPerTonne(row, fxByIso3) {
  const localTonne=Number(row.priceLCUTonne);
  if(!Number.isFinite(localTonne)) return {usd:null,status:'unit_not_normalized'};
  if(String(row.currency||'').toUpperCase()==='USD') return {usd:localTonne,status:'unit_converted'};
  const fx=fxByIso3[String(row.iso3||'').toUpperCase()];
  if(!fx || !Number.isFinite(fx.usdPerLocalUnit)) return {usd:null,status:'fx_unavailable'};
  return {usd:localTonne*fx.usdPerLocalUnit,status:'fx_converted'};
}

// Global commodity benchmark layer.
// This is intentionally separate from local/producer prices: the provider may
// expose a market/futures benchmark with its own unit. AUREN never silently
// converts units or currencies.
const GLOBAL_COMMODITIES = Object.freeze([
  {key:'wheat', name:'Wheat', providerName:'wheat', category:'grains'},
  {key:'corn', name:'Corn', providerName:'corn', category:'grains'},
  {key:'soybean', name:'Soybean', providerName:'soybean', category:'oilseeds'},
  {key:'coffee', name:'Coffee', providerName:'coffee', category:'beverages'},
  {key:'cocoa', name:'Cocoa', providerName:'cocoa', category:'beverages'},
  {key:'sugar', name:'Sugar', providerName:'sugar', category:'food'},
  {key:'cotton', name:'Cotton', providerName:'cotton', category:'fiber'},
  {key:'rough_rice', name:'Rough Rice', providerName:'rough_rice', category:'grains'},
  {key:'live_cattle', name:'Live Cattle', providerName:'live_cattle', category:'livestock'}
]);

async function fetchGlobalCommodityBenchmark(item) {
  const url='https://www.omkar.cloud/api/commodity-price?name='+encodeURIComponent(item.providerName);
  const res=await fetch(url,{headers:{accept:'application/json'},signal:AbortSignal.timeout(15000)});
  const body=await res.text();
  let data={};
  try { data=JSON.parse(body); } catch (_) {}
  if (!res.ok) throw new Error(item.key+': provider HTTP '+res.status);
  const price=Number(data.price_usd);
  if (!Number.isFinite(price)) return null;
  return {
    id:item.key,
    market:'global_benchmark',
    commodity:item.name,
    category:item.category,
    price,
    currency:'USD',
    unit:String(data.unit || 'provider_unit'),
    exchange:String(data.exchange || 'global benchmark').slice(0,120),
    observedAt:String(data.updated_at || new Date().toISOString()),
    source:'Omkar Commodity Price API',
    sourceUrl:'https://www.omkar.cloud/tools/commodity-price-api',
    providerStatus:'live'
  };
}

async function fetchGlobalCommodityBenchmarks() {
  const settled=await Promise.allSettled(GLOBAL_COMMODITIES.map(fetchGlobalCommodityBenchmark));
  return settled.filter(x=>x.status==='fulfilled' && x.value).map(x=>x.value);
}

exports.aurenAgriGlobalCommodityPrices = onCall(async (request)=>{
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const requested=normalizeText(request.data?.commodity);
  const rows=await fetchGlobalCommodityBenchmarks();
  const filtered=requested
    ? rows.filter(r=>normalizeText(r.commodity)===requested || r.id===requested)
    : rows;
  return {
    status:filtered.length?'ok':'no_data',
    asOf:new Date().toISOString(),
    source:'Omkar Commodity Price API',
    sourceUrl:'https://www.omkar.cloud/tools/commodity-price-api',
    data:filtered
  };
});

exports.aurenAgriGlobalCommodityPriceCache = onCall(async (request)=>{
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const rows=await fetchGlobalCommodityBenchmarks();
  const batch=db.batch();
  for (const row of rows) {
    const ref=db.collection('auren_agri_global_commodity_prices').doc(row.id);
    batch.set(ref,{...row,updatedAt:admin.firestore.FieldValue.serverTimestamp()},{merge:true});
    batch.set(db.collection('auren_agri_market_price_history').doc(),{
      ...row,observedAt:admin.firestore.FieldValue.serverTimestamp(),historyType:'global_benchmark'
    });
  }
  if (rows.length) await batch.commit();
  return {status:rows.length?'cached':'no_data',count:rows.length};
});

    
exports.aurenAgricultureMarketPrices = onCall(async (request)=>{
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const country=String(request.data?.country || 'ALL').trim().toUpperCase();
  if (country !== 'ALL' && !/^[A-Z]{3}$/.test(country)) {
    throw new Error('country must be a valid ISO3 code or ALL.');
  }
  const state=normalizeText(request.data?.state);
  const city=normalizeText(request.data?.city);
  const commodity=normalizeText(request.data?.commodity);
  const limit=Math.min(Math.max(Number(request.data?.limit)||25,1),100);

  const [global, primarySnap, legacySnap]=await Promise.all([
    fetchGlobalCommodityBenchmarks(),
    db.collection('auren_agri_local_market_prices').limit(country==='ALL'?1000:400).get(),
    db.collection('agri_local_market_prices').limit(country==='ALL'?1000:400).get().catch(()=>({docs:[]}))
  ]);

  const local=[];
  const seen=new Set();
  for (const snap of [primarySnap,legacySnap]) {
    for (const doc of snap.docs) {
      const d=doc.data()||{};
      const iso=String(d.iso3 || d.countryCode || '').toUpperCase();
      const item=String(d.item || d.commodity || '').trim();
      const row={
        id:doc.id,
        market:'local',
        country:d.countryName || d.country || '',
        countryCode:iso,
        state:d.region || d.state || '',
        city:d.city || '',
        commodity:item,
        category:d.category || 'agriculture',
        price:Number(d.priceLCU ?? d.price),
        currency:d.currency || '',
        unit:d.unit || '',
        marketName:d.market || d.marketName || '',
        source:d.source || 'FAO GIEWS FPMA',
        sourceUrl:d.sourceUrl || null,
        verified:Boolean(d.verified),
        observedAt:d.date || d.observedAt || d.updatedAt || null
      };
      if (country!=='ALL' && iso!==country) continue;
      if (state && normalizeText(row.state)!==state) continue;
      if (city && normalizeText(row.city)!==city) continue;
      if (commodity && normalizeText(item)!==commodity) continue;
      const key=[iso,normalizeText(item),normalizeText(row.state),normalizeText(row.city),normalizeText(row.marketName),String(row.observedAt)].join('|');
      if (seen.has(key)) continue;
      seen.add(key);
      if (Number.isFinite(row.price) && row.price>=0) local.push(row);
    }
  }
  local.sort((a,b)=>String(b.observedAt).localeCompare(String(a.observedAt)));
  return {
    status:(global.length||local.length)?'ok':'no_data',
    asOf:new Date().toISOString(),
    country,
    global:global.slice(0,50),
    local:local.slice(0,limit),
    sources:{
      global:'Omkar Commodity Price API',
      local:'FAO GIEWS FPMA / AUREN local imports'
    }
  };
});
