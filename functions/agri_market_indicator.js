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

exports.aurenAgriMarketIndicator = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const p = request.data || {};
  const country = String(p.country || 'Sudan').trim();
  const crop = String(p.crop || 'Sorghum').trim();

  const producerSnap = await db.collection('auren_agri_producer_prices')
    .where('countryName', '==', country)
    .where('item', '==', crop)
    .limit(60)
    .get();

  const producer = producerSnap.docs.map(d => d.data()).sort((a,b) => String(a.date||'').localeCompare(String(b.date||''))).slice(-24);

  // Optional local-market feed. A future GIEWS/market adapter can write the same schema.
  const localSnap = await db.collection('auren_agri_local_market_prices')
    .where('countryName', '==', country)
    .where('item', '==', crop)
    .limit(60)
    .get().catch(() => ({docs:[]}));

  const local = localSnap.docs.map(d => d.data()).sort((a,b) => String(a.date||'').localeCompare(String(b.date||''))).slice(-24);

  const latestProducer = producer.length ? producer[producer.length-1] : null;
  const latestLocal = local.length ? local[local.length-1] : null;

  const producerUsd = latestProducer ? num(latestProducer.priceUSDTonne) : null;
  const localUsd = latestLocal ? num(latestLocal.priceUSDTonne) : null;

  const indicator = {
    producerPriceUsdTonne: producerUsd,
    localMarketPriceUsdTonne: localUsd,
    localVsProducerPct: pct(localUsd, producerUsd),
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
