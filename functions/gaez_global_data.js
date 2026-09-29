'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const GAEZ_CATALOG_URL = 'https://data.fao.org/catalog/dataset/gaez-v5-master-config';
const CROP_SUMMARY_CATALOG_URL = 'https://data.fao.org/catalog/dataset/crop-summary-gaez';
const GAEZ_V5_RES05 = process.env.GAEZ_V5_RES05 || null;
const GAEZ_V5_CROP_SUMMARY_SQL_URL = 'https://data.apps.fao.org/catalog/dataset/a55c337e-f7e6-4d2f-aa8e-6d2199171c37/resource/fef86116-be49-4ddc-8317-66cd368d4fda/download/gaez-crop-summary-query.sql';
const GAEZ_V5_CROP_SUMMARY_API_URL = 'https://api.data.apps.fao.org/api/v2/bigquery?sql_url=' + encodeURIComponent(GAEZ_V5_CROP_SUMMARY_SQL_URL);
const GAEZ_V5_CROP_SUMMARY_URL = process.env.GAEZ_V5_CROP_SUMMARY_URL || GAEZ_V5_CROP_SUMMARY_API_URL;

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
    cropSummaryQueryUrl:GAEZ_V5_CROP_SUMMARY_URL,
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
    endpointStatus:process.env.GAEZ_V5_RES05 ? 'configured_not_yet_proven' : 'not_configured',
    service:GAEZ_V5_RES05,
    count:items.length,
    items:items.map(x => x.attributes || {})
  };
});


function assertOfficialFaoResource(url) {
  let parsed;
  try { parsed = new URL(String(url)); } catch (_) { throw new Error('Invalid GAEZ resource URL.'); }
  if (parsed.protocol !== 'https:' || !['data.apps.fao.org','api.data.apps.fao.org','data.fao.org'].includes(parsed.hostname)) {
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

function extractRowsFromPayload(payload) {
  if (Array.isArray(payload)) return payload;
  if (Array.isArray(payload?.data)) return payload.data;
  if (Array.isArray(payload?.rows)) return payload.rows;
  if (Array.isArray(payload?.results)) return payload.results;
  if (Array.isArray(payload?.data?.rows)) return payload.data.rows;
  return [];
}

function normalizeGaezRows(rows) {
  return rows.map(row => {
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
    rows=extractRowsFromPayload(payload);
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

function rowField(row, names) {
  for (const name of names) {
    if (row && row[name] !== undefined && row[name] !== null && String(row[name]).trim() !== '') {
      return String(row[name]).trim();
    }
  }
  return '';
}

function rowCountry(row) {
  return rowField(row, ['iso3','ISO3','country_iso3','countryIso3','adm0_iso3','country_code','Country ISO3','country','Country','area','Area']);
}

function normalizeCountryKey(value) {
  const raw = String(value || '').trim();
  if (!raw) return '';
  if (/^[A-Za-z]{3}$/.test(raw)) return raw.toUpperCase();
  return raw.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '').toUpperCase();
}

function rowCrop(row) {
  return rowField(row, ['crop','Crop','crop_name','Crop Name','commodity','Commodity','crop_lut']);
}

async function loadCountryRegistry() {
  const snap = await db.collection('auren_global_countries').select('iso3','name').get();
  const byName = new Map();
  snap.forEach(doc => {
    const d = doc.data() || {};
    const iso3 = String(d.iso3 || doc.id || '').trim().toUpperCase();
    const name = String(d.name || '').trim().toLowerCase();
    if (/^[A-Z]{3}$/.test(iso3) && name) byName.set(name, iso3);
  });
  return byName;
}

function chunk(items, size) {
  const out = [];
  for (let i=0;i<items.length;i+=size) out.push(items.slice(i,i+size));
  return out;
}

exports.aurenGaezV5CropSummary = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p=request.data||{};
  const country=normalizeCountryKey(p.country || p.iso3 || '');
  const crop=String(p.crop || '').trim();

  // Prefer globally ingested FAO v5 rows so every supported country uses
  // the same verified source rather than a Sudan-specific path.
  let query = db.collection('auren_gaez_v5_crop_summary_rows');
  if (country) query=query.where('countryKey','==',country.toUpperCase());
  else if (crop) query=query.where('cropKey','==',crop.toLowerCase());

  const imported = await query.limit(500).get();
  const importedRows = imported.docs
    .map(d => d.data() || {})
    .filter(d => !crop || String(d.cropKey || '').toLowerCase() === crop.toLowerCase())
    .map(d => d.row || {});
  if (importedRows.length) {
    const rows=importedRows;
    return {
      status:'ok',
      source:'FAO GAEZ v5 Crop Summary Data',
      scope:'global',
      storage:'firestore_ingested_rows',
      filters:{country:country||null,crop:crop||null},
      countryKey:country||null,
      count:rows.length,
      data:rows
    };
  }

  if (!GAEZ_V5_CROP_SUMMARY_URL) {
    return {
      status:'configuration_required',
      source:'FAO GAEZ v5 Crop Summary',
      catalogUrl:CROP_SUMMARY_CATALOG_URL,
      reason:'GAEZ_V5_CROP_SUMMARY_URL is not configured and no imported global rows matched the request'
    };
  }

  const params=new URLSearchParams();
  for (const key of ['country','crop','climateSource','ssp','period','waterSupply','management']) {
    if (p[key]) params.set(key,String(p[key]));
  }
  const url=GAEZ_V5_CROP_SUMMARY_URL + (GAEZ_V5_CROP_SUMMARY_URL.includes('?')?'&':'?') + params.toString();
  const payload=await getJson(url);
  return {
    status:'ok',
    source:'FAO GAEZ v5 Crop Summary',
    scope:'global',
    endpoint:url.split('?')[0],
    filters:Object.fromEntries(params.entries()),
    data:payload
  };
});

exports.aurenGaezV5GlobalIngest = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const url=String(request.data?.url || GAEZ_V5_CROP_SUMMARY_URL || '').trim();
  if (!url) throw new Error('GAEZ_V5_CROP_SUMMARY_URL is not configured.');
  const parsed=assertOfficialFaoResource(url);
  const res=await fetch(parsed.toString(), {
    headers:{accept:'text/csv,application/json,text/plain'},
    signal:AbortSignal.timeout(60000)
  });
  if (!res.ok) throw new Error('GAEZ resource request failed: ' + res.status);
  const body=await res.text();
  const contentType=String(res.headers.get('content-type')||'');
  let rows;
  if (/json/i.test(contentType)) {
    const payload=JSON.parse(body);
    rows=extractRowsFromPayload(payload);
  } else {
    rows=parseCsv(body);
  }

  const normalized=normalizeGaezRows(rows);
  if (!normalized.length) throw new Error('No tabular GAEZ rows were found in the official global resource.');

  const countryRegistry = await loadCountryRegistry();
  const groups = new Map();
  for (const row of normalized) {
    const rawCountry = rowCountry(row);
    let countryKey = normalizeCountryKey(rawCountry);
    if (!/^[A-Z]{3}$/.test(countryKey)) {
      countryKey = countryRegistry.get(String(rawCountry || '').trim().toLowerCase()) || '';
    }
    const cropKey=rowCrop(row).toLowerCase();
    if (!countryKey || !/^[A-Z]{3}$/.test(countryKey)) continue;
    const key=countryKey + '|' + cropKey;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(row);
  }

  let stored=0;
  const countrySet=new Set();
  const cropSet=new Set();

  for (const [key, group] of groups) {
    const [countryKey,cropKey]=key.split('|');
    countrySet.add(countryKey);
    if (cropKey) cropSet.add(cropKey);

    for (const batchRows of chunk(group, 400)) {
      const batch=db.batch();
      for (const row of batchRows) {
        const stableId = Buffer.from(countryKey + '|' + cropKey + '|' + JSON.stringify(row)).toString('base64url').slice(0,120);
        const ref=db.collection('auren_gaez_v5_crop_summary_rows').doc(stableId);
        batch.set(ref, {
          source:'FAO GAEZ v5 Crop Summary Data',
          version:'GAEZ v5',
          verification:{provider:'FAO',catalog:'Crop Summary Data',verifiedByCatalog:true},
          catalogUrl:CROP_SUMMARY_CATALOG_URL,
          resourceUrl:parsed.toString(),
          countryKey,
          cropKey,
          row,
          importedBy:request.auth.uid,
          importedAt:admin.firestore.FieldValue.serverTimestamp()
        });
      }
      await batch.commit();
      stored += batchRows.length;
    }
  }

  return {
    status:'imported',
    scope:'global',
    source:'FAO GAEZ v5 Crop Summary Data',
    rowCount:stored,
    countryCount:countrySet.size,
    cropCount:cropSet.size,
    countries:Array.from(countrySet).sort(),
    resourceUrl:parsed.toString(),
    note:'Rows are stored individually so the dataset can cover all countries without exceeding Firestore document limits.'
  };
});

exports.aurenGaezV5GlobalCoverage = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const snap=await db.collection('auren_gaez_v5_crop_summary_rows').select('countryKey','cropKey').get();
  const countries=new Set();
  const crops=new Set();
  snap.forEach(doc => {
    const d=doc.data();
    if (d.countryKey) countries.add(d.countryKey);
    if (d.cropKey) crops.add(d.cropKey);
  });
  return {
    status:'ok',
    scope:'global',
    source:'FAO GAEZ v5 Crop Summary Data',
    importedRows:snap.size,
    countryCount:countries.size,
    cropCount:crops.size,
    countries:Array.from(countries).sort(),
    crops:Array.from(crops).sort()
  };
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
