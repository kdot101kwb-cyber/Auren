'use strict';

const {onCall}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');

const db=admin.firestore();

const SOURCES=[
  {id:'world_bank_wdi',name:'World Bank WDI',kind:'api',url:'https://api.worldbank.org/v2/',coverage:'global',auth:'none'},
  {id:'fao_faostat',name:'FAOSTAT',kind:'dataset',url:'https://www.fao.org/faostat/',coverage:'245+ countries and territories',auth:'public'},
  {id:'fao_wca',name:'FAO World Census of Agriculture',kind:'dataset',url:'https://www.fao.org/world-census-agriculture/en',coverage:'countries with agricultural census data',auth:'public'},
  {id:'ilo_ilostat',name:'ILOSTAT',kind:'dataset',url:'https://ilostat.ilo.org/data/',coverage:'global',auth:'public'},
  {id:'un_comtrade',name:'UN Comtrade',kind:'trade_dataset',url:'https://comtradeplus.un.org/',coverage:'global',auth:'public'},
];

exports.aurenGlobalDataSources=onCall(async(request)=>{
  if(!request.auth?.uid) throw new Error('Authentication is required.');
  return {
    status:'ok',
    sources:SOURCES,
    scope:[
      'country profiles',
      'agriculture and livestock',
      'land and irrigation',
      'labour and wages',
      'trade and imports/exports',
      'energy and development indicators',
      'market and feasibility inputs'
    ],
    note:'Data availability and update frequency differ by country and source. AUREN should store source, year, unit and freshness for every imported value.'
  };
});

exports.aurenWorldBankIndicators=onCall(async(request)=>{
  if(!request.auth?.uid) throw new Error('Authentication is required.');
  const country=String(request.data?.country||'all').trim().toLowerCase();
  const indicator=String(request.data?.indicator||'').trim();
  if(!indicator) throw new Error('indicator is required.');
  const date=String(request.data?.date||'').trim();
  const url='https://api.worldbank.org/v2/country/'+encodeURIComponent(country)+'/indicator/'+encodeURIComponent(indicator)+'?format=json&per_page=100'+(date?'&date='+encodeURIComponent(date):'');
  const response=await fetch(url);
  const raw=await response.text();
  if(!response.ok) throw new Error('World Bank data request failed.');
  let data=[];
  try{data=JSON.parse(raw);}catch(_){throw new Error('World Bank returned invalid JSON.');}
  const rows=Array.isArray(data)&&Array.isArray(data[1])?data[1]:[];
  return {status:'ok',source:'world_bank_wdi',indicator,country,rows:rows.slice(0,100)};
});


function normalizeSearchText(value) {
  return String(value || '').trim().toLowerCase().slice(0, 120);
}

function publicCountryProfile(doc) {
  const d = doc.data() || {};
  return {
    iso2: d.iso2 || null,
    iso3: d.iso3 || doc.id,
    name: d.name || null,
    region: d.region || null,
    incomeLevel: d.incomeLevel || null,
    lendingType: d.lendingType || null,
    capitalCity: d.capitalCity || null,
    latitude: Number.isFinite(Number(d.latitude)) ? Number(d.latitude) : null,
    longitude: Number.isFinite(Number(d.longitude)) ? Number(d.longitude) : null,
    source: d.source || 'world_bank_wdi',
  };
}

function indicatorSnapshot(doc) {
  const d = doc.data() || {};
  const indicators = d.indicators && typeof d.indicators === 'object' ? d.indicators : {};
  const result = {};
  for (const [key, value] of Object.entries(indicators)) {
    if (!value || value.value == null) continue;
    result[key] = {
      value: Number(value.value),
      year: String(value.year || ''),
      indicatorName: String(value.indicatorName || key).slice(0, 240),
    };
  }
  return result;
}

exports.aurenCountryIntelligence = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const query = normalizeSearchText(request.data?.query);
  const iso3 = String(request.data?.iso3 || '').trim().toUpperCase().slice(0, 3);
  const limit = Math.min(Math.max(Number(request.data?.limit) || 10, 1), 25);

  let docs = [];
  if (iso3) {
    const snap = await db.collection('auren_global_countries').doc(iso3).get();
    if (snap.exists) docs = [snap];
  } else {
    const snap = await db.collection('auren_global_countries').orderBy('name').limit(250).get();
    docs = snap.docs.filter((doc) => {
      if (!query) return true;
      const d = doc.data() || {};
      return [d.name, d.iso2, d.iso3, d.capitalCity, d.region]
        .some((value) => normalizeSearchText(value).includes(query));
    }).slice(0, limit);
  }

  const results = [];
  for (const doc of docs.slice(0, limit)) {
    const country = publicCountryProfile(doc);
    const dataSnap = await db.collection('auren_global_data').doc(country.iso3).get();
    results.push({
      ...country,
      indicators: dataSnap.exists ? indicatorSnapshot(dataSnap) : {},
    });
  }

  return {
    status: 'ok',
    query: query || null,
    iso3: iso3 || null,
    results,
    count: results.length,
    source: 'auren_global_data',
  };
});

exports.aurenOpportunityCountryScan = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const query = normalizeSearchText(request.data?.query);
  const region = normalizeSearchText(request.data?.region);
  const limit = Math.min(Math.max(Number(request.data?.limit) || 10, 1), 25);

  const snap = await db.collection('auren_global_countries').orderBy('name').limit(250).get();
  const candidates = [];

  for (const doc of snap.docs) {
    const country = publicCountryProfile(doc);
    if (query && ![country.name, country.iso2, country.iso3, country.capitalCity, country.region]
      .some((value) => normalizeSearchText(value).includes(query))) continue;
    if (region && !normalizeSearchText(country.region).includes(region)) continue;

    const dataSnap = await db.collection('auren_global_data').doc(country.iso3).get();
    const indicators = dataSnap.exists ? indicatorSnapshot(dataSnap) : {};
    const signals = {
      population: Number(indicators['SP.POP.TOTL']?.value || 0),
      gdpPerCapita: Number(indicators['NY.GDP.PCAP.CD']?.value || 0),
      unemployment: Number(indicators['SL.UEM.TOTL.ZS']?.value || 0),
      agriculturalLand: Number(indicators['AG.LND.AGRI.ZS']?.value || 0),
    };
    const completeness = Object.values(signals).filter((value) => Number.isFinite(value) && value > 0).length;
    candidates.push({
      ...country,
      indicators,
      dataCompleteness: completeness,
      signals,
    });
  }

  candidates.sort((a, b) => b.dataCompleteness - a.dataCompleteness || a.name.localeCompare(b.name));
  return {
    status: 'ok',
    query: query || null,
    region: region || null,
    results: candidates.slice(0, limit),
    count: Math.min(candidates.length, limit),
    rankingBasis: 'data_completeness_then_name',
    source: 'world_bank_wdi',
  };
});
