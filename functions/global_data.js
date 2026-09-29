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
