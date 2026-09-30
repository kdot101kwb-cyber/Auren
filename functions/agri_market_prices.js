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
