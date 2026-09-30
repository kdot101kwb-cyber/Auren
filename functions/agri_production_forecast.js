'use strict';
const {onCall}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');
const db=admin.firestore();
function auth(r){if(!r.auth?.uid)throw new Error('Authentication is required.');}
function clean(v){return String(v??'').trim();}
function num(v){const n=Number(v);return Number.isFinite(n)?n:null;}
function linear(rows,field,horizon){
 const data=rows.filter(r=>num(r.year)!=null&&num(r[field])!=null).sort((a,b)=>num(a.year)-num(b.year));
 if(!data.length)return [];
 const n=data.length,xs=data.map(r=>num(r.year)),ys=data.map(r=>num(r[field]));
 const mx=xs.reduce((a,b)=>a+b,0)/n,my=ys.reduce((a,b)=>a+b,0)/n,den=xs.reduce((s,x)=>s+(x-mx)**2,0);
 const slope=den?xs.reduce((s,x,i)=>s+(x-mx)*(ys[i]-my),0)/den:0,intercept=my-slope*mx,last=xs[n-1];
 return Array.from({length:horizon},(_,i)=>{const year=last+i+1;return{year,predicted:Math.max(0,intercept+slope*year),method:'linear_trend_baseline'};});
}
async function loadRows(iso3,item){
 const snap=await db.collection('auren_agri_production_history').limit(2000).get();
 return snap.docs.map(d=>d.data()).filter(r=>(!iso3||String(r.iso3||'').toUpperCase()===iso3)&&(!item||clean(r.item).toLowerCase()===item.toLowerCase()));
}
function priceValue(r){return num(r.price??r.Price??r.value??r.Value??r.pricePerTon);}
async function latestPrice(iso3,item){
 const [local,global]=await Promise.all([db.collection('auren_agri_local_market_prices').limit(1000).get(),db.collection('auren_agri_global_commodity_prices').limit(100).get()]);
 const localRows=local.docs.map(d=>d.data()).filter(r=>String(r.iso3||r.countryCode||'').toUpperCase()===iso3&&clean(r.item||r.commodity).toLowerCase().includes(item.toLowerCase()));
 const globalRows=global.docs.map(d=>d.data()).filter(r=>clean(r.commodity||r.id).toLowerCase().includes(item.toLowerCase()));
 const rows=[...localRows,...globalRows].filter(r=>priceValue(r)!=null).sort((a,b)=>String(b.observedAt||b.date||'').localeCompare(String(a.observedAt||a.date||'')));
 if(!rows.length)return null;
 const r=rows[0];return{value:priceValue(r),currency:r.currency||null,unit:r.unit||null,source:r.source||r.exchange||'market'};
}
async function latestCost(iso3,item){
 const slug=item.toLowerCase().replace(/[^a-z0-9]+/g,'_'),snap=await db.collection('auren_agri_cost_evidence').doc(iso3+'_'+slug).get();
 if(!snap.exists)return null;
 const items=Array.isArray(snap.data()?.items)?snap.data().items:[],opex=items.find(x=>String(x.category||'').toLowerCase()==='opex'&&num(x.value)!=null);
 return opex?{value:num(opex.value),currency:opex.currency||null,unit:opex.unit||null,source:opex.source||null}:null;
}
exports.aurenAgriProductionForecast=onCall(async request=>{
 auth(request);const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase(),item=clean(request.data?.item||request.data?.crop),horizon=Math.min(Math.max(num(request.data?.horizon)||5,1),10);
 const rows=await loadRows(iso3,item),production=linear(rows,'production',horizon),yieldForecast=linear(rows,'yieldValue',horizon),areaForecast=linear(rows,'area',horizon),price=await latestPrice(iso3,item),cost=await latestCost(iso3,item);
 const revenueForecast=production.map((p,i)=>{const revenue=price?num(p.predicted)*price.value:null,profit=revenue!=null&&cost?revenue-cost.value:null;return{year:p.year,predictedProduction:num(p.predicted),predictedYield:yieldForecast[i]?.predicted??null,predictedArea:areaForecast[i]?.predicted??null,revenue,profit,revenueCurrency:price?.currency??null,revenueUnit:price?.unit??null,profitCurrency:price?.currency&&cost?.currency===price.currency?price.currency:null};});
 return{status:production.length?'ok':'no_data',iso3,item,horizon,historyYears:rows.length,forecast:production,yieldForecast,areaForecast,revenueForecast,market:{price,cost},profitabilityStatus:cost&&price?'calculated':'needs_sourced_price_and_opex',method:'linear_trend_baseline'};
});
exports.aurenAgriSeasonComparison=onCall(async request=>{
 auth(request);const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase(),item=clean(request.data?.item||request.data?.crop),rows=(await loadRows(iso3,item)).sort((a,b)=>num(a.year)-num(b.year));
 const out=rows.map((r,i)=>{const prev=rows[i-1],current=num(r.production),previous=prev?num(prev.production):null;return{...r,growthPct:previous&&current!=null?((current-previous)/previous)*100:null};});
 return{status:out.length?'ok':'no_data',rows:out};
});
exports.aurenAgriCropScenario=onCall(async request=>{
 auth(request);const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase(),item=clean(request.data?.item||request.data?.crop),baseProduction=num(request.data?.baseProduction),yieldChangePct=num(request.data?.yieldChangePct)||0,areaChangePct=num(request.data?.areaChangePct)||0,priceChangePct=num(request.data?.priceChangePct)||0,costChangePct=num(request.data?.costChangePct)||0;
 if(baseProduction==null||baseProduction<0)throw new Error('baseProduction is required.');
 const production=baseProduction*(1+yieldChangePct/100)*(1+areaChangePct/100),price=await latestPrice(iso3,item),cost=await latestCost(iso3,item),revenue=price?production*price.value*(1+priceChangePct/100):null,profit=revenue!=null&&cost?revenue-cost.value*(1+costChangePct/100):null;
 return{status:'ok',iso3,item,assumptions:{baseProduction,yieldChangePct,areaChangePct,priceChangePct,costChangePct},outputs:{projectedProduction:production,productionChangePct:(production/baseProduction-1)*100,revenue,profit,revenueCurrency:price?.currency??null,profitCurrency:price&&cost&&price.currency===cost.currency?price.currency:null},market:{price,cost},profitabilityStatus:price&&cost?'calculated':'needs_sourced_price_and_opex',note:'Revenue/profit are calculated only when sourced market price and explicit OPEX evidence are available.'};
});