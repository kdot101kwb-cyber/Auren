const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const db = admin.firestore();

function auth(r){if(!r.auth?.uid) throw new Error('Authentication is required.');}
function clean(v){return String(v??'').trim();}
function key(r){return [String(r.iso3||'').toUpperCase(),clean(r.item).toLowerCase()];}
function linearForecast(rows, horizon){
  const data=rows.filter(r=>Number.isFinite(Number(r.year)) && Number.isFinite(Number(r.production))).sort((a,b)=>Number(a.year)-Number(b.year));
  if(!data.length)return [];
  const n=data.length, xs=data.map(r=>Number(r.year)), ys=data.map(r=>Number(r.production));
  const mx=xs.reduce((a,b)=>a+b,0)/n, my=ys.reduce((a,b)=>a+b,0)/n;
  const den=xs.reduce((s,x)=>s+(x-mx)**2,0);
  const slope=den?xs.reduce((s,x,i)=>s+(x-mx)*(ys[i]-my),0)/den:0;
  const intercept=my-slope*mx;
  const last=xs[n-1];
  return Array.from({length:horizon},(_,i)=>({year:last+i+1,predictedProduction:Math.max(0,intercept+slope*(last+i+1)),method:'linear_trend'}));
}

async function loadRows(iso3,item){
  const snap=await db.collection('auren_agri_production_history').limit(2000).get();
  return snap.docs.map(d=>d.data()).filter(r=>
    (!iso3||String(r.iso3||'').toUpperCase()===iso3)&&
    (!item||clean(r.item).toLowerCase()===item.toLowerCase())
  );
}

exports.aurenAgriProductionForecast = onCall(async request=>{
  auth(request);
  const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase();
  const item=clean(request.data?.item||request.data?.crop);
  const horizon=Math.min(Math.max(Number(request.data?.horizon)||5,1),10);
  const rows=await loadRows(iso3,item);
  const forecast=linearForecast(rows,horizon);
  return {status:forecast.length?'ok':'no_data',iso3,item,horizon,historyYears:rows.length,forecast,method:'linear_trend'};
});

exports.aurenAgriSeasonComparison = onCall(async request=>{
  auth(request);
  const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase();
  const item=clean(request.data?.item||request.data?.crop);
  const rows=(await loadRows(iso3,item)).sort((a,b)=>Number(a.year)-Number(b.year));
  const out=rows.map((r,i)=>{
    const prev=rows[i-1];
    const current=Number(r.production);
    const previous=prev?Number(prev.production):null;
    return {...r,growthPct:previous&&Number.isFinite(current)?((current-previous)/previous)*100:null};
  });
  return {status:out.length?'ok':'no_data',rows:out};
});

exports.aurenAgriCropScenario = onCall(async request=>{
  auth(request);
  const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase();
  const item=clean(request.data?.item||request.data?.crop);
  const baseProduction=Number(request.data?.baseProduction);
  const yieldChangePct=Number(request.data?.yieldChangePct||0);
  const areaChangePct=Number(request.data?.areaChangePct||0);
  const priceChangePct=Number(request.data?.priceChangePct||0);
  const costChangePct=Number(request.data?.costChangePct||0);
  if(!Number.isFinite(baseProduction)||baseProduction<0) throw new Error('baseProduction is required.');
  const production=baseProduction*(1+yieldChangePct/100)*(1+areaChangePct/100);
  const revenueIndex=(production/baseProduction)*(1+priceChangePct/100);
  const profitIndex=revenueIndex-(costChangePct/100);
  return {
    status:'ok',iso3,item,
    assumptions:{baseProduction,yieldChangePct,areaChangePct,priceChangePct,costChangePct},
    outputs:{projectedProduction:production,productionChangePct:(production/baseProduction-1)*100,revenueIndex,profitIndex},
    note:'Scenario is an analytical index model; connect sourced prices and costs for monetary profit.'
  };
});
