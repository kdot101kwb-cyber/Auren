'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

function n(v) {
  if (v === null || v === undefined || v === '') return null;
  const x = Number(v);
  return Number.isFinite(x) ? x : null;
}

function text(v) {
  return String(v || '').trim();
}

function pct(a, b) {
  return a != null && b != null && b !== 0 ? ((a - b) / b) * 100 : null;
}

function latest(rows, key) {
  return rows
    .filter(r => n(r[key]) != null)
    .sort((a,b) => String(b.date || b.year || '').localeCompare(String(a.date || a.year || '')))[0] || null;
}

function seriesTrend(rows, key) {
  const ordered = rows
    .filter(r => n(r[key]) != null)
    .sort((a,b) => String(a.date || a.year || '').localeCompare(String(b.date || b.year || '')));
  if (ordered.length < 2) return {direction:'unknown', changePct:null, observations:ordered.length};
  const a = n(ordered[ordered.length - 2][key]);
  const b = n(ordered[ordered.length - 1][key]);
  const changePct = pct(b, a);
  return {
    direction: changePct == null ? 'unknown' : changePct > 2 ? 'up' : changePct < -2 ? 'down' : 'stable',
    changePct,
    observations:ordered.length
  };
}

async function producerRows(country, crop) {
  let q = db.collection('auren_agri_producer_prices');
  if (country) q = q.where('countryName','==',country);
  if (crop) q = q.where('item','==',crop);
  const snap = await q.limit(500).get();
  return snap.docs.map(d => d.data() || {});
}

async function localRows(country, crop) {
  let q = db.collection('auren_agri_local_market_prices');
  if (country) q = q.where('countryName','==',country);
  if (crop) q = q.where('item','==',crop);
  const snap = await q.limit(500).get().catch(() => ({docs:[]}));
  return snap.docs.map(d => d.data() || {});
}

async function countryTradeSignals(iso3, crop) {
  if (!iso3) return null;
  const snap = await db.collection('auren_global_data').doc(iso3).get();
  if (!snap.exists) return null;
  const d = snap.data() || {};
  const indicators = d.indicators || {};
  const pick = (codes) => {
    for (const code of codes) {
      const row = indicators[code];
      const value = n(row?.value);
      if (value != null) return {code, value, year:row?.year || row?.date || null, unit:row?.unit || null};
    }
    return null;
  };
  return {
    agriculturalLandShare:pick(['AG.LND.AGRI.ZS']),
    population:pick(['SP.POP.TOTL']),
    gdpPerCapita:pick(['NY.GDP.PCAP.CD']),
    crop:crop || null
  };
}

exports.aurenAgriMarketIntelligence = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p = request.data || {};
  const country = text(p.country);
  const iso3 = text(p.iso3).toUpperCase();
  const crop = text(p.crop);

  if (!country && !iso3) throw new Error('country or iso3 is required.');
  if (!crop) throw new Error('crop is required.');

  const [producer, local, trade] = await Promise.all([
    producerRows(country, crop),
    localRows(country, crop),
    countryTradeSignals(iso3, crop)
  ]);

  const latestProducer = latest(producer, 'priceUSDTonne');
  const latestLocal = latest(local, 'priceUSDTonne');
  const localCurrencyLatest = latest(local, 'priceLCU');

  const localVsProducerPct = pct(
    n(latestLocal?.priceUSDTonne),
    n(latestProducer?.priceUSDTonne)
  );

  const result = {
    status: producer.length || local.length ? 'ok' : 'no_data',
    country: country || null,
    iso3: iso3 || null,
    crop,
    market: {
      latestProducerPrice: latestProducer ? {
        value:n(latestProducer.priceUSDTonne),
        currency:'USD',
        unit:'tonne',
        date:latestProducer.date || null,
        source:latestProducer.source || 'FAOSTAT Agricultural Producer Prices'
      } : null,
      latestLocalMarketPrice: latestLocal ? {
        value:n(latestLocal.priceUSDTonne),
        currency:'USD',
        unit:'tonne',
        date:latestLocal.date || null,
        source:latestLocal.source || 'FAO GIEWS FPMA'
      } : null,
      latestLocalCurrencyPrice: localCurrencyLatest ? {
        value:n(localCurrencyLatest.priceLCU),
        currency:localCurrencyLatest.currency || null,
        unit:localCurrencyLatest.unit || null,
        date:localCurrencyLatest.date || null
      } : null,
      localVsProducerPct,
      producerTrend:seriesTrend(producer,'priceUSDTonne'),
      localTrend:seriesTrend(local,'priceUSDTonne')
    },
    coverage:{
      producerRows:producer.length,
      localRows:local.length,
      sources:[...new Set([
        ...producer.map(x => x.source).filter(Boolean),
        ...local.map(x => x.source).filter(Boolean)
      ])]
    },
    countrySignals:trade,
    alerts:[],
    missing:[]
  };

  if (!latestProducer) result.missing.push('current producer price in USD/tonne');
  if (!latestLocal) result.missing.push('current local-market price in USD/tonne');
  if (latestProducer && latestLocal && Math.abs(localVsProducerPct || 0) >= 20) {
    result.alerts.push({
      type:'price_gap',
      severity:Math.abs(localVsProducerPct) >= 50 ? 'high' : 'medium',
      localVsProducerPct,
      message:'Local-market and producer-price observations differ materially; validate market, unit, date and conversion assumptions.'
    });
  }
  if (result.market.localTrend.direction === 'up') {
    result.alerts.push({type:'local_price_trend',severity:'info',direction:'up'});
  } else if (result.market.localTrend.direction === 'down') {
    result.alerts.push({type:'local_price_trend',severity:'info',direction:'down'});
  }

  await db.collection('auren_agri_market_intelligence').add({
    uid:request.auth.uid,
    generatedAt:admin.firestore.FieldValue.serverTimestamp(),
    ...result
  });

  return result;
});

exports.aurenAgriMarketComparison = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const p=request.data||{};
  const crop=text(p.crop);
  const countries=Array.isArray(p.countries)
    ? p.countries.map(text).filter(Boolean).slice(0,50)
    : [];
  if (!crop || !countries.length) throw new Error('crop and countries are required.');

  const rows=[];
  for (const country of countries) {
    const [producer, local] = await Promise.all([
      producerRows(country,crop),
      localRows(country,crop)
    ]);
    const lp=latest(producer,'priceUSDTonne');
    const ll=latest(local,'priceUSDTonne');
    rows.push({
      country,
      producerPriceUsdTonne:n(lp?.priceUSDTonne),
      localMarketPriceUsdTonne:n(ll?.priceUSDTonne),
      localVsProducerPct:pct(n(ll?.priceUSDTonne),n(lp?.priceUSDTonne)),
      producerDate:lp?.date||null,
      localDate:ll?.date||null,
      producerSource:lp?.source||null,
      localSource:ll?.source||null,
      dataAvailable:Boolean(lp||ll)
    });
  }

  return {
    status:'ok',
    crop,
    countries:rows,
    note:'Comparison is descriptive. It does not adjust for quality, transport, taxes, exchange controls, tariffs, seasonality or buyer terms unless those inputs are supplied separately.'
  };
});
