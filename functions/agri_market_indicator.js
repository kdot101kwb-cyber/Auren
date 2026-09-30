const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const db = admin.firestore();

function num(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function pct(a,b) {
  if (a === null || b === null || b === 0) return null;
  return ((a-b)/b)*100;
}

function firstMetric(row, patterns) {
  const entries = Object.entries(row || {});
  for (const [key, value] of entries) {
    const k = String(key).toLowerCase().replace(/[^a-z0-9]+/g, '_');
    if (!patterns.some(re => re.test(k))) continue;
    const n = num(value);
    if (n !== null) return {key, value:n};
  }
  return null;
}

function firstText(row, patterns) {
  for (const [key, value] of Object.entries(row || {})) {
    const k = String(key).toLowerCase().replace(/[^a-z0-9]+/g, '_');
    if (patterns.some(re => re.test(k)) && value !== null && value !== undefined && String(value).trim()) {
      return {key, value:String(value).trim()};
    }
  }
  return null;
}

function buildGaezMetrics(rows, fallbackCrop) {
  const samples = rows.slice(0, 20).map(r => {
    const row = r.row || {};
    const suitability = firstText(row, [/suitability_class/, /suitability.*class/, /class.*suitability/]);
    const land = firstMetric(row, [/suitable.*land/, /suitable.*area/, /suitability.*area/, /area.*suitable/]);
    const yieldMetric = firstMetric(row, [/attainable.*yield/, /yield.*attainable/, /agro.*ecological.*yield/]);
    const production = firstMetric(row, [/potential.*production/, /production.*potential/]);
    const crop = firstText(row, [/^crop$/, /crop_name/, /commodity/]);
    const country = firstText(row, [/^country$/, /country_name/, /area_name/]);
    return {
      country: country?.value || r.countryKey || null,
      crop: crop?.value || fallbackCrop,
      suitabilityClass: suitability?.value || null,
      suitableLandHa: land?.value ?? null,
      attainableYield: yieldMetric?.value ?? null,
      potentialProduction: production?.value ?? null
    };
  });
  const nonNull = key => samples.filter(x => x[key] !== null).length;
  return {
    sampleMetrics: samples.filter(x =>
      x.suitabilityClass !== null ||
      x.suitableLandHa !== null ||
      x.attainableYield !== null ||
      x.potentialProduction !== null
    ),
    fieldCoverage: {
      suitabilityClass: nonNull('suitabilityClass'),
      suitableLandHa: nonNull('suitableLandHa'),
      attainableYield: nonNull('attainableYield'),
      potentialProduction: nonNull('potentialProduction')
    }
  };
}

function trend(rows, valueKey) {
  const values = rows.map(r => num(r[valueKey])).filter(v => v !== null);
  if (values.length < 2) return {direction:'unknown', changePct:null};
  const previous = values[values.length-2];
  const latest = values[values.length-1];
  const changePct = pct(latest, previous);
  return {
    direction: changePct === null ? 'unknown' : changePct > 1 ? 'up' : changePct < -1 ? 'down' : 'stable',
    changePct
  };
}

async function buildGlobalLocalMarketSnapshot({crop='', iso3='', limit=500}={}) {
  let q = db.collection('auren_agri_local_market_prices').limit(Math.min(Math.max(Number(limit)||500,1),1000));
  const snap = await q.get();
  const rows = snap.docs.map(d => d.data()).filter(r =>
    (!crop || String(r.item||'').toLowerCase() === crop.toLowerCase()) &&
    (!iso3 || String(r.iso3||'').toUpperCase() === iso3.toUpperCase())
  );
  const byCountry = new Map();
  const globalMarkets = new Set();
  for (const r of rows) {
    const key = String(r.iso3 || r.countryName || 'UNKNOWN').toUpperCase();
    const bucket = byCountry.get(key) || {
      iso3:r.iso3||null,
      countryName:r.countryName||null,
      markets:0,
      rows:0,
      nativePrices:0,
      convertedPrices:0,
      latestDate:null,
      latestNativePrice:null,
      latestNativePricePerTonne:null,
      latestUnit:null,
      latestCurrency:null,
      latestConversionStatus:null
    };
    bucket.rows++;
    if (r.market) {
      bucket._marketKeys ||= new Set();
      bucket._marketKeys.add(String(r.market).trim().toLowerCase());
      globalMarkets.add(key + '|' + String(r.market).trim().toLowerCase());
    }
    if (num(r.priceLCU) !== null) bucket.nativePrices++;
    if (num(r.priceUSDTonne) !== null) bucket.convertedPrices++;
    if (!bucket.latestDate || String(r.date||'') > String(bucket.latestDate)) {
      bucket.latestDate = r.date || null;
      bucket.latestNativePrice = num(r.priceLCU);
      bucket.latestNativePricePerTonne = num(r.priceLCUTonne);
      bucket.latestUnit = r.nativeUnitCanonical || r.unit || null;
      bucket.latestCurrency = r.currency || null;
      bucket.latestConversionStatus = r.conversionStatus || (bucket.latestNativePricePerTonne !== null ? 'unit_converted' : 'not_converted');
    }
    byCountry.set(key,bucket);
  }
  const countries=[...byCountry.values()].map(bucket => {
    bucket.markets = bucket._marketKeys ? bucket._marketKeys.size : 0;
    delete bucket._marketKeys;
    return bucket;
  }).sort((a,b)=>String(a.countryName||a.iso3).localeCompare(String(b.countryName||b.iso3)));
  return {
    countries,
    totalRows:rows.length,
    countriesCovered:byCountry.size,
    marketsCovered:globalMarkets.size,
    nativePriceRows:rows.filter(r=>num(r.priceLCU)!==null).length,
    convertedRows:rows.filter(r=>num(r.priceUSDTonne)!==null).length,
    conversionCoveragePct:rows.length ? Math.round((rows.filter(r=>num(r.priceUSDTonne)!==null).length/rows.length)*10000)/100 : 0,
    source:'FAO GIEWS FPMA'
  };
}

exports.aurenAgriGlobalLocalMarketSnapshot = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const p=request.data||{};
  const snapshot=await buildGlobalLocalMarketSnapshot({crop:String(p.crop||''),iso3:String(p.iso3||''),limit:p.limit});
  return {status:snapshot.totalRows?'ok':'no_data', source:'FAO GIEWS FPMA', ...snapshot};
});

exports.aurenAgriAgricultureDashboard = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const p = request.data || {};
  const crop = String(p.crop || 'Sorghum').trim();
  const iso3 = String(p.iso3 || '').trim().toUpperCase();
  const country = String(p.country || '').trim();

  const snapshot = await buildGlobalLocalMarketSnapshot({
    crop,
    iso3,
    limit: p.limit
  });

  const gaezSnap = await db.collection('auren_gaez_v5_crop_summary_rows')
    .where('cropKey', '==', crop.toLowerCase())
    .limit(100)
    .get()
    .catch(() => ({docs:[]}));
  const gaezRows = gaezSnap.docs.map(d => d.data() || {}).filter(r =>
    !iso3 || String(r.countryKey || '').toUpperCase() === iso3
  );
  const gaezEvidence = gaezRows.map(r => r.row || {}).filter(r => Object.keys(r).length).slice(0, 20);
  const gaezMetrics = buildGaezMetrics(gaezRows, crop);

  const producerSnap = await db.collection('auren_agri_producer_prices')
    .where('item', '==', crop)
    .limit(60)
    .get();

  const producerRows = producerSnap.docs.map(d => d.data()).filter(r =>
    (!iso3 || String(r.iso3 || r.countryIso3 || '').toUpperCase() === iso3) &&
    (!country || String(r.countryName || '').toLowerCase() === country.toLowerCase())
  );

  const latestProducer = producerRows.sort((a,b) =>
    String(b.date || '').localeCompare(String(a.date || ''))
  )[0] || null;

  return {
    status: snapshot.totalRows || latestProducer ? 'ok' : 'no_data',
    generatedAt: new Date().toISOString(),
    crop,
    iso3: iso3 || null,
    country: country || null,
    globalLocalMarket: snapshot,
    gaez: {
      status: gaezRows.length ? 'ok' : 'no_data',
      source: 'FAO GAEZ v5 Crop Summary Data',
      rows: gaezRows.length,
      countriesCovered: new Set(gaezRows.map(r => String(r.countryKey || '').toUpperCase()).filter(Boolean)).size,
      evidence: gaezEvidence,
      metrics: gaezMetrics
    },
    producer: {
      latest: latestProducer,
      source: latestProducer?.source || 'FAOSTAT'
    },
    sources: ['FAO GAEZ v5 Crop Summary Data', 'FAO GIEWS FPMA', 'FAOSTAT Agricultural Producer Prices'],
    readiness: {
      globalAggregation: true,
      dashboardApi: true,
      fpmaLiveFeedConfigured: Boolean(process.env.FPMA_DATA_URL),
      usdTonneConversion: snapshot.convertedRows > 0,
      contractVersion: 'agriculture-dashboard.v1'
    }
  };
});

exports.aurenAgriMarketIndicator = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p = request.data || {};
  const country = String(p.country || 'Sudan').trim();
  const iso3 = String(p.iso3 || '').trim().toUpperCase();
  const crop = String(p.crop || 'Sorghum').trim();

  const producerSnap = await db.collection('auren_agri_producer_prices')
    .where('item', '==', crop)
    .limit(60)
    .get();

  const producer = producerSnap.docs.map(d => d.data()).filter(r => !iso3 || String(r.iso3 || r.countryIso3 || '').toUpperCase() === iso3 || String(r.countryName || '').toLowerCase() === country.toLowerCase()).sort((a,b) => String(a.date||'').localeCompare(String(b.date||''))).slice(-24);

  // Optional local-market feed. A future GIEWS/market adapter can write the same schema.
  const localSnap = await db.collection('auren_agri_local_market_prices')
    .where('item', '==', crop)
    .limit(60)
    .get().catch(() => ({docs:[]}));

  const local = localSnap.docs.map(d => d.data()).filter(r => !iso3 || String(r.iso3 || '').toUpperCase() === iso3 || String(r.countryName || '').toLowerCase() === country.toLowerCase()).sort((a,b) => String(a.date||'').localeCompare(String(b.date||''))).slice(-24);

  const latestProducer = producer.length ? producer[producer.length-1] : null;
  const latestLocal = local.length ? local[local.length-1] : null;

  const producerUsd = latestProducer ? num(latestProducer.priceUSDTonne) : null;
  const localUsd = latestLocal ? num(latestLocal.priceUSDTonne) : null;

  const indicator = {
    producerPriceUsdTonne: producerUsd,
    localMarketPriceUsdTonne: localUsd,
    localVsProducerPct: pct(localUsd, producerUsd),
    localNativePrice: latestLocal?.priceLCU ?? null,
    localNativeUnit: latestLocal?.unit ?? null,
    localCurrency: latestLocal?.currency ?? null,
    localConversionStatus: latestLocal?.conversionStatus ?? (localUsd === null ? 'not_converted' : 'converted'),
    producerTrend: trend(producer, 'priceUSDTonne'),
    localTrend: trend(local, 'priceUSDTonne'),
    dataCoverage: {
      producerRows: producer.length,
      localRows: local.length,
      producerSource: latestProducer?.source || 'FAOSTAT',
      localSource: latestLocal?.source || null
    }
  };

  return {
    status: producer.length || local.length ? 'ok' : 'no_data',
    country,
    iso3: iso3 || null,
    crop,
    indicator,
    latest: {
      producer: latestProducer,
      localMarket: latestLocal
    },
    sources: [
      'FAOSTAT Agricultural Producer Prices',
      'FAO GIEWS Food Price Monitoring and Analysis (FPMA)'
    ],
    sourceLinks: {
      producer: 'https://data.fao.org/catalog/dataset/47c17894-8ca1-4bd0-ba4d-6078e919e9b1',
      localMarket: 'https://fpma.fao.org/giews/fpmat4/global/'
    }
  };
});
