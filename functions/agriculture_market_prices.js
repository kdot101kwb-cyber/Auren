const {onCall} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {FieldValue} = require('firebase-admin/firestore');
const db = require('firebase-admin').firestore();

const GLOBAL_COMMODITIES = [
  {key:'wheat', name:'Wheat', endpointName:'wheat', category:'grains'},
  {key:'corn', name:'Corn', endpointName:'corn', category:'grains'},
  {key:'soybean', name:'Soybean', endpointName:'soybean', category:'oilseeds'},
  {key:'coffee', name:'Coffee', endpointName:'coffee', category:'softs'},
  {key:'cocoa', name:'Cocoa', endpointName:'cocoa', category:'softs'},
  {key:'sugar', name:'Sugar', endpointName:'sugar', category:'softs'},
  {key:'cotton', name:'Cotton', endpointName:'cotton', category:'fiber'},
  {key:'rough_rice', name:'Rough Rice', endpointName:'rough_rice', category:'grains'},
  {key:'live_cattle', name:'Live Cattle', endpointName:'live_cattle', category:'livestock'},
];

async function fetchGlobalCommodity(item) {
  const url = 'https://www.omkar.cloud/api/commodity-price?name=' + encodeURIComponent(item.endpointName);
  const response = await fetch(url, {signal:AbortSignal.timeout(12000)});
  const raw = await response.text();
  let data = {};
  try { data = JSON.parse(raw); } catch (_) {}
  if (!response.ok) throw new Error(item.key + ': provider HTTP ' + response.status);
  const price = Number(data.price_usd);
  return {
    id:item.key, market:'global', commodity:item.name, category:item.category,
    price:Number.isFinite(price) ? price : null, currency:'USD',
    unit:'provider_unit', exchange:String(data.exchange || 'global futures').slice(0,80),
    updatedAt:String(data.updated_at || new Date().toISOString()),
    source:'Omkar Commodity Price API',
    sourceUrl:'https://www.omkar.cloud/tools/commodity-price-api', live:true,
  };
}

async function readLocalPrices({country, state, city, commodity, limit}) {
  // Country is optional: ALL returns the latest sourced rows across countries.
  // State/city/commodity remain in-memory filters so one global index serves the browse screen.
  let query = db.collection('agri_local_market_prices').orderBy('updatedAt', 'desc')
    .limit(country === 'ALL' ? 1000 : Math.min(Math.max(limit * 8, 50), 400));
  if (country !== 'ALL') query = query.where('countryCode', '==', country.toUpperCase());
  const snap = await query.get();
  const wantedState = state.toLowerCase();
  const wantedCity = city.toLowerCase();
  const wantedCommodity = commodity.toLowerCase();
  return snap.docs.filter((doc) => {
    const d = doc.data() || {};
    return (!wantedState || d.stateKey === wantedState)
      && (!wantedCity || d.cityKey === wantedCity)
      && (!wantedCommodity || d.commodityKey === wantedCommodity);
  }).slice(0, limit).map((doc) => {
    const d = doc.data() || {};
    return {
      id:doc.id, market:'local', country:d.country || country || '', countryCode:d.countryCode || '',
      state:d.state || '', city:d.city || '', commodity:d.commodity || commodity || '',
      category:d.category || 'agriculture', price:Number(d.price), currency:d.currency || 'SDG',
      unit:d.unit || '', marketName:d.marketName || '',
      updatedAt:d.updatedAt?.toDate?.()?.toISOString?.() || d.updatedAt || null,
      source:d.source || 'AUREN local market import', sourceUrl:d.sourceUrl || null,
      live:false, verified:Boolean(d.verified),
    };
  });
}

async function upsertGlobalPrices() {
  const settled = await Promise.allSettled(GLOBAL_COMMODITIES.map(fetchGlobalCommodity));
  const batch = db.batch();
  let count = 0;
  for (let i = 0; i < settled.length; i++) {
    const result = settled[i];
    if (result.status !== 'fulfilled' || result.value.price == null) continue;
    const item = result.value;
    const ref = db.collection('agri_global_market_prices').doc(item.id);
    const historyRef = db.collection('agri_market_price_history').doc();
    batch.set(ref, {...item, updatedAt:FieldValue.serverTimestamp()}, {merge:true});
    batch.set(historyRef, {...item, observedAt:FieldValue.serverTimestamp()}, {merge:false});
    count++;
  }
  if (count) await batch.commit();
  return count;
}

exports.aurenAgricultureMarketPrices = onCall(
  {region:'us-central1', timeoutSeconds:30, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    if (!request.auth?.uid) throw new Error('Authentication is required.');
    const country = String(request.data?.country || 'ALL').trim().toUpperCase();
    if (country !== 'ALL' && !/^[A-Z]{3}$/.test(country)) throw new Error('country must be a valid ISO3 code or ALL.');
    const state = String(request.data?.state || '').trim().slice(0, 100);
    const city = String(request.data?.city || '').trim().slice(0, 100);
    const commodity = String(request.data?.commodity || '').trim().slice(0, 100);
    const limit = Math.min(Math.max(Number(request.data?.limit) || 25, 1), 100);
    const [globalSettled, local] = await Promise.all([
      Promise.allSettled(GLOBAL_COMMODITIES.map(fetchGlobalCommodity)),
      readLocalPrices({country, state, city, commodity, limit}),
    ]);
    const global = globalSettled.filter((x) => x.status === 'fulfilled').map((x) => x.value);
    return {
      status:'ok', asOf:new Date().toISOString(), country, global, local,
      priceHistory:{collection:'agri_market_price_history', retention:'append-only observations from scheduled refreshes'},
      localDataNote:local.length ? null : 'لا توجد أسعار محلية مستوردة لهذا الموقع حالياً.',
      sources:{global:'Omkar Commodity Price API', local:'AUREN local market price imports; source metadata is stored per record.'},
    };
  }
);

exports.refreshAurenGlobalMarketPrices = onSchedule(
  {schedule:'every 6 hours', timeZone:'UTC', region:'us-central1', timeoutSeconds:60, memory:'256MiB'},
  async () => console.log('AUREN global agriculture prices refreshed:', await upsertGlobalPrices())
);

exports.upsertAurenLocalMarketPrice = onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new Error('Authentication is required.');
    const adminDoc = await db.collection('admin_uids').doc(uid).get();
    if (!adminDoc.exists || adminDoc.data()?.enabled !== true) throw new Error('Admin permission is required.');
    const d = request.data || {};
    const price = Number(d.price);
    const commodity = String(d.commodity || '').trim().slice(0, 120);
    if (!commodity || !Number.isFinite(price) || price < 0 || !/^[A-Z]{3}$/.test(String(d.countryCode || '').trim().toUpperCase())) {
      throw new Error('Valid commodity, non-negative price, and ISO3 countryCode are required.');
    }
    const ref = db.collection('agri_local_market_prices').doc();
    await ref.set({
      country:String(d.country || '').trim().slice(0, 80), countryCode:String(d.countryCode || '').trim().slice(0, 3).toUpperCase(),
      state:String(d.state || '').trim().slice(0, 100), stateKey:String(d.state || '').trim().toLowerCase().slice(0, 100),
      city:String(d.city || '').trim().slice(0, 100), cityKey:String(d.city || '').trim().toLowerCase().slice(0, 100),
      commodity, commodityKey:commodity.toLowerCase(), category:String(d.category || 'agriculture').trim().slice(0, 60),
      price, currency:String(d.currency || 'SDG').trim().slice(0, 10), unit:String(d.unit || '').trim().slice(0, 40),
      marketName:String(d.marketName || '').trim().slice(0, 120), source:String(d.source || 'AUREN local market import').trim().slice(0, 200),
      sourceUrl:String(d.sourceUrl || '').trim().slice(0, 500), verified:Boolean(d.verified), importedBy:uid,
      updatedAt:FieldValue.serverTimestamp(),
    });
    return {status:'ok', id:ref.id};
  }
);
