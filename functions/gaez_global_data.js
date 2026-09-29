'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const GAEZ_CATALOG_URL = 'https://data.fao.org/catalog/dataset/gaez-v5-master-config';
const CROP_SUMMARY_CATALOG_URL = 'https://data.fao.org/catalog/dataset/crop-summary-gaez';
const GAEZ_V5_RES05 = process.env.GAEZ_V5_RES05 || null;
const GAEZ_V5_CROP_SUMMARY_URL = process.env.GAEZ_V5_CROP_SUMMARY_URL || null;

const THEMES = [
  'land_water_resources',
  'agro_climatic_resources',
  'suitability_attainable_yield',
  'actual_yields_production',
  'yield_production_gaps',
  'crop_summary'
];

exports.aurenGaezCatalog = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  return {
    status:'ok',
    source:'FAO GAEZ v5',
    catalogUrl:GAEZ_CATALOG_URL,
    cropSummaryUrl:CROP_SUMMARY_CATALOG_URL,
    themes:THEMES,
    resolution:{
      standard:'5 arc-minute (~10 km at equator)',
      selected:'30 arc-second (~1 km at equator)'
    },
    endpointStatus: process.env.GAEZ_V5_RES05 ? 'configured_not_yet_proven' : 'missing',
    note:'GAEZ v5 was launched by FAO in 2025; this deployment only treats a configured endpoint as verified and never labels the default endpoint as v5 without validation.'
  };
});

async function getJson(url) {
  const res = await fetch(url, {
    headers:{accept:'application/json'},
    signal:AbortSignal.timeout(30000)
  });
  if (!res.ok) throw new Error('GAEZ request failed: ' + res.status);
  return res.json();
}

exports.aurenGaezV5HealthCheck = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const configuredEndpoint = process.env.GAEZ_V5_RES05 || null;
  let catalogReachable = false;
  let catalogText = '';
  try {
    const res = await fetch(GAEZ_CATALOG_URL, {signal:AbortSignal.timeout(30000)});
    catalogText = await res.text();
    catalogReachable = res.ok && /GAEZ v5|gaez-v5/i.test(catalogText);
  } catch (_) {}
  return {
    status: catalogReachable && configuredEndpoint ? 'ready_for_endpoint_validation' : 'configuration_required',
    source:'FAO GAEZ v5',
    catalogUrl:GAEZ_CATALOG_URL,
    configuredEndpoint,
    catalogReachable,
    endpointStatus:configuredEndpoint ? 'configured_not_yet_proven' : 'missing',
    next:'Configure GAEZ_V5_RES05 only with a verified FAO GAEZ v5 resource; do not infer v5 from a v4-compatible service URL.'
  };
});

exports.aurenGaezSuitabilityCatalog = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const crop = String(request.data?.crop || '').trim();
  const waterSupply = String(request.data?.waterSupply || '').trim();
  const inputLevel = String(request.data?.inputLevel || '').trim();

  const where = [];
  if (crop) where.push("crop = '" + crop.replace(/'/g, "''") + "'");
  if (waterSupply) where.push("water_supply = '" + waterSupply.replace(/'/g, "''") + "'");
  if (inputLevel) where.push("input_level = '" + inputLevel.replace(/'/g, "''") + "'");

  const params = new URLSearchParams({
    where: where.length ? where.join(' AND ') : '1=1',
    outFields:'objectid,name,variable,year,model,rcp,crop,water_supply,input_level,units,download_url,file_id',
    returnGeometry:'false',
    resultRecordCount:'1000',
    f:'json'
  });

  if (!GAEZ_V5_RES05) throw new Error('GAEZ_V5_RES05 is not configured with a verified FAO GAEZ v5 endpoint.');
  const payload = await getJson(GAEZ_V5_RES05 + '/query?' + params.toString());
  const items = payload.features || [];

  return {
    status:'ok',
    source:'FAO GAEZ v5',
    endpointStatus:process.env.GAEZ_V5_RES05 ? 'configured' : 'not_verified',
    service:GAEZ_V5_RES05,
    count:items.length,
    items:items.map(x => x.attributes || {})
  };
});


function assertOfficialFaoResource(url) {
  let parsed;
  try { parsed = new URL(String(url)); } catch (_) { throw new Error('Invalid GAEZ resource URL.'); }
  if (parsed.protocol !== 'https:' || !['data.apps.fao.org','data.fao.org'].includes(parsed.hostname)) {
    throw new Error('GAEZ resource must be an official FAO data.apps.fao.org or data.fao.org HTTPS URL.');
  }
  return parsed;
}

function parseCsvLine(line) {
  const cells=[]; let cell=''; let quoted=false;
  for (let i=0;i<line.length;i++) {
    const ch=line[i];
    if (ch === '"') {
      if (quoted && line[i+1] === '"') { cell+='"'; i++; }
      else quoted=!quoted;
    } else if (ch === ',' && !quoted) { cells.push(cell); cell=''; }
    else cell+=ch;
  }
  cells.push(cell);
  return cells;
}

function parseCsv(text) {
  const lines=String(text||'').replace(/^\\uFEFF/,'').split(/\\r?\\n/).filter(line=>line.trim());
  if (!lines.length) return [];
  const headers=parseCsvLine(lines[0]).map(v=>v.trim());
  return lines.slice(1).map(line => {
    const values=parseCsvLine(line);
    return Object.fromEntries(headers.map((h,i)=>[h, values[i] ?? '']));
  });
}

function normalizeGaezRows(rows) {
  return rows.slice(0,5000).map(row => {
    const out={};
    for (const [key,value] of Object.entries(row)) {
      const clean=String(value ?? '').trim();
      if (clean === '') continue;
      const num=Number(clean.replace(/,/g,''));
      out[key]=Number.isFinite(num) && /^-?\\d+(?:[.,]\\d+)?$/.test(clean) ? num : clean;
    }
    return out;
  }).filter(row => Object.keys(row).length);
}

exports.aurenGaezV5CropSummaryHealth = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  if (!GAEZ_V5_CROP_SUMMARY_URL) {
    return {status:'configuration_required', source:'FAO GAEZ v5 Crop Summary', catalogUrl:CROP_SUMMARY_CATALOG_URL};
  }
  const parsed=assertOfficialFaoResource(GAEZ_V5_CROP_SUMMARY_URL);
  const res=await fetch(parsed.toString(), {headers:{accept:'text/csv,application/json,text/plain'},signal:AbortSignal.timeout(30000)});
  const body=await res.text();
  const contentType=String(res.headers.get('content-type')||'');
  return {
    status:res.ok ? 'reachable_official_fao_resource' : 'resource_error',
    httpStatus:res.status,
    source:'FAO GAEZ v5 Crop Summary',
    endpoint:parsed.toString(),
    contentType,
    bytes:Buffer.byteLength(body,'utf8'),
    csvDetected:/text\\/(csv|plain)|,/.test(contentType) || /,/.test(body.slice(0,1000)),
    note:'The official FAO catalog identifies this resource as GAEZ v5 Crop Summary Data. AUREN does not mark agronomic values as verified v5 until the configured resource passes this reachability check and its imported rows retain source/version metadata.'
  };
});

exports.aurenGaezV5CropSummaryIngest = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const url=String(request.data?.url || GAEZ_V5_CROP_SUMMARY_URL || '').trim();
  if (!url) throw new Error('GAEZ_V5_CROP_SUMMARY_URL is not configured.');
  const parsed=assertOfficialFaoResource(url);
  const res=await fetch(parsed.toString(), {headers:{accept:'text/csv,application/json,text/plain'},signal:AbortSignal.timeout(60000)});
  if (!res.ok) throw new Error('GAEZ resource request failed: ' + res.status);
  const body=await res.text();
  const contentType=String(res.headers.get('content-type')||'');
  let rows;
  if (/json/i.test(contentType)) {
    const payload=JSON.parse(body);
    rows=Array.isArray(payload) ? payload : (Array.isArray(payload.data) ? payload.data : (Array.isArray(payload.rows) ? payload.rows : []));
  } else {
    rows=parseCsv(body);
  }
  const normalized=normalizeGaezRows(rows);
  if (!normalized.length) throw new Error('No tabular GAEZ rows were found in the official resource.');
  const ref=db.collection('auren_gaez_v5_crop_summary').doc();
  await ref.set({
    source:'FAO GAEZ v5 Crop Summary Data',
    catalogUrl:CROP_SUMMARY_CATALOG_URL,
    resourceUrl:parsed.toString(),
    version:'GAEZ v5',
    status:'imported',
    rowCount:normalized.length,
    rows:normalized,
    importedBy:request.auth.uid,
    importedAt:admin.firestore.FieldValue.serverTimestamp()
  });
  return {status:'imported',id:ref.id,rowCount:normalized.length,source:'FAO GAEZ v5 Crop Summary Data',resourceUrl:parsed.toString()};
});

exports.aurenGaezV5CropSummary = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  if (!GAEZ_V5_CROP_SUMMARY_URL) {
    return {status:'configuration_required', source:'FAO GAEZ v5 Crop Summary', catalogUrl:CROP_SUMMARY_CATALOG_URL, reason:'GAEZ_V5_CROP_SUMMARY_URL is not configured'};
  }
  const p=request.data||{};
  const params=new URLSearchParams();
  for (const key of ['country','crop','climateSource','ssp','period','waterSupply','management']) {
    if (p[key]) params.set(key,String(p[key]));
  }
  const url=GAEZ_V5_CROP_SUMMARY_URL + (GAEZ_V5_CROP_SUMMARY_URL.includes('?')?'&':'?') + params.toString();
  const payload=await getJson(url);
  return {status:'ok',source:'FAO GAEZ v5 Crop Summary',endpoint:url.split('?')[0],filters:Object.fromEntries(params.entries()),data:payload};
});

exports.aurenGaezCropQuery = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const country = String(request.data?.country || '').trim();
  const crop = String(request.data?.crop || '').trim();
  const climateSource = String(request.data?.climateSource || '').trim();
  const ssp = String(request.data?.ssp || '').trim();
  const period = String(request.data?.period || '').trim();
  const waterSupply = String(request.data?.waterSupply || '').trim();
  const management = String(request.data?.management || '').trim();

  const query = {
    country: country || null,
    crop: crop || null,
    climateSource: climateSource || null,
    ssp: ssp || null,
    period: period || null,
    waterSupply: waterSupply || null,
    management: management || null
  };

  const ref = db.collection('auren_gaez_queries').doc();
  await ref.set({
    query,
    source:'FAO GAEZ v5 Crop Summary',
    catalogUrl:CROP_SUMMARY_CATALOG_URL,
    gaezV5SuitabilityService:GAEZ_V5_RES05,
    status:'queued',
    createdBy:request.auth.uid,
    createdAt:admin.firestore.FieldValue.serverTimestamp()
  });

  return {
    status:'queued',
    id:ref.id,
    query,
    source:'FAO GAEZ v5',
    next:'connect the validated FAO catalog resource/query endpoint before returning agronomic values'
  };
});
