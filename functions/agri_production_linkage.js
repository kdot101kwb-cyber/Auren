'use strict';
const {onCall}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');
const db=admin.firestore();

function auth(r){if(!r.auth?.uid)throw new Error('Authentication is required.');}
function text(v){return String(v??'').trim();}
function num(v){const n=Number(v);return Number.isFinite(n)?n:null;}
function cropMatch(v,target){const a=text(v).toLowerCase(),b=text(target).toLowerCase();return a===b||a.includes(b)||b.includes(a);}

exports.aurenAgriProductionIntelligence = onCall(async request=>{
  auth(request);
  const iso3=text(request.data?.iso3||request.data?.country).toUpperCase();
  const crop=text(request.data?.crop||request.data?.item);
  if(!/^[A-Z]{3}$/.test(iso3)||!crop)throw new Error('iso3 and crop are required.');

  const [productionSnap,gaezSnap,localPriceSnap,globalPriceSnap]=await Promise.all([
    db.collection('auren_agri_production_history').limit(2000).get(),
    db.collection('auren_gaez_v5_crop_summary_rows').where('countryKey','==',iso3).limit(500).get(),
    db.collection('auren_agri_local_market_prices').limit(1000).get(),
    db.collection('auren_agri_global_commodity_prices').limit(100).get()
  ]);

  const production=productionSnap.docs.map(d=>d.data()).filter(r=>cropMatch(r.item,crop)).sort((a,b)=>Number(a.year)-Number(b.year));
  const gaez=gaezSnap.docs.map(d=>d.data()).map(d=>d.row||{}).filter(r=>cropMatch(r.crop||r.Crop||r.item||r.Item||r.commodity,crop)).slice(0,50);
  const localPrices=localPriceSnap.docs.map(d=>({id:d.id,...d.data()})).filter(r=>
    String(r.iso3||r.countryCode||'').toUpperCase()===iso3 && cropMatch(r.item||r.commodity,crop)
  ).sort((a,b)=>String(b.date||b.observedAt||'').localeCompare(String(a.date||a.observedAt||''))).slice(0,25);
  const globalPrices=globalPriceSnap.docs.map(d=>({id:d.id,...d.data()})).filter(r=>cropMatch(r.commodity||r.id,crop));

  const latest=production[production.length-1]||null;
  const previous=production.length>1?production[production.length-2]:null;
  const productionGrowth=latest&&previous&&num(previous.production)>0&&num(latest.production)!=null
    ? ((num(latest.production)-num(previous.production))/num(previous.production))*100:null;

  return {
    status:(production.length||gaez.length||localPrices.length||globalPrices.length)?'ok':'no_data',
    iso3,crop,
    production:{history:production.slice(-20),latest,previous,growthPct:productionGrowth},
    gaez:{source:'FAO GAEZ v5 Crop Summary Data',version:'GAEZ v5',rows:gaez},
    prices:{local:localPrices,global:globalPrices},
    linkage:{
      productionToGaez:production.length>0&&gaez.length>0,
      productionToLocalPrice:production.length>0&&localPrices.length>0,
      productionToGlobalPrice:production.length>0&&globalPrices.length>0,
      readyForFinancialFeasibility:Boolean(production.length&& (localPrices.length||globalPrices.length))
    },
    generatedAt:new Date().toISOString()
  };
});