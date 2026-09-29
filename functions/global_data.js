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

exports.aurenCountryIntelligence=onCall(async(request)=>{
  if(!request.auth?.uid) throw new Error('Authentication is required.');
  const query=String(request.data?.query||'').trim().toLowerCase().slice(0,120);
  const iso3=String(request.data?.iso3||'').trim().toUpperCase().slice(0,3);
  const limit=Math.min(Math.max(Number(request.data?.limit)||10,1),25);
  let docs=[];
  if(iso3){
    const snap=await db.collection('auren_global_countries').doc(iso3).get();
    if(snap.exists) docs=[snap];
  }else{
    const snap=await db.collection('auren_global_countries').orderBy('name').limit(250).get();
    docs=snap.docs.filter(doc=>{
      if(!query)return true;
      const d=doc.data()||{};
      return [d.name,d.iso2,d.iso3,d.capitalCity,d.region].some(v=>String(v||'').toLowerCase().includes(query));
    }).slice(0,limit);
  }
  const results=[];
  for(const doc of docs.slice(0,limit)){
    const d=doc.data()||{};
    const iso=d.iso3||doc.id;
    const dataSnap=await db.collection('auren_global_data').doc(iso).get();
    const indicators=dataSnap.exists?dataSnap.data()?.indicators||:{};
    results.push({
      iso2:d.iso2||null,iso3:iso,name:d.name||null,region:d.region||null,
      incomeLevel:d.incomeLevel||null,capitalCity:d.capitalCity||null,
      source:d.source||'world_bank_wdi',indicators
    });
  }
  return {status:'ok',query:query||null,iso3:iso3||null,results,count:results.length,source:'auren_global_data'};
});

exports.aurenOpportunityCountryScan=onCall(async(request)=>{
  if(!request.auth?.uid) throw new Error('Authentication is required.');
  const query=String(request.data?.query||'').trim().toLowerCase().slice(0,120);
  const region=String(request.data?.region||'').trim().toLowerCase().slice(0,120);
  const limit=Math.min(Math.max(Number(request.data?.limit)||10,1),25);
  const snap=await db.collection('auren_global_countries').orderBy('name').limit(250).get();
  const candidates=[];
  for(const doc of snap.docs){
    const d=doc.data()||{};
    if(query&&!([d.name,d.iso2,d.iso3,d.capitalCity,d.region].some(v=>String(v||'').toLowerCase().includes(query))))continue;
    if(region&&!String(d.region||'').toLowerCase().includes(region))continue;
    const dataSnap=await db.collection('auren_global_data').doc(d.iso3||doc.id).get();
    const indicators=dataSnap.exists?dataSnap.data()?.indicators||:{};
    const signals={
      population:Number(indicators['SP.POP.TOTL']?.value||0),
      gdpPerCapita:Number(indicators['NY.GDP.PCAP.CD']?.value||0),
      unemployment:Number(indicators['SL.UEM.TOTL.ZS']?.value||0),
      agriculturalLand:Number(indicators['AG.LND.AGRI.ZS']?.value||0)
    };
    const completeness=Object.values(signals).filter(v=>Number.isFinite(v)&&v>0).length;
    candidates.push({...d,indicators,dataCompleteness:completeness,signals});
  }
  candidates.sort((a,b)=>b.dataCompleteness-a.dataCompleteness||String(a.name||'').localeCompare(String(b.name||'')));
  return {status:'ok',query:query||null,region:region||null,results:candidates.slice(0,limit),count:Math.min(candidates.length,limit),rankingBasis:'data_completeness_then_name',source:'world_bank_wdi'};
});

Object.assign(module.exports,require('./agri_logistics_evidence'));
