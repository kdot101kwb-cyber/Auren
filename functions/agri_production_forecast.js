'use strict';
const {onCall}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');
const db=admin.firestore();

function auth(r){if(!r.auth?.uid)throw new Error('Authentication is required.');}
function clean(v){return String(v??'').trim();}
function num(v){const n=Number(v);return Number.isFinite(n)?n:null;}

function linearModel(rows,field){
 const data=rows.filter(r=>num(r.year)!=null&&num(r[field])!=null).sort((a,b)=>num(a.year)-num(b.year));
 if(!data.length)return {forecast:[],metrics:{observations:0}};
 const xs=data.map(r=>num(r.year)),ys=data.map(r=>num(r[field])),n=ys.length;
 const mx=xs.reduce((a,b)=>a+b,0)/n,my=ys.reduce((a,b)=>a+b,0)/n;
 const den=xs.reduce((s,x)=>s+(x-mx)**2,0);
 const slope=den?xs.reduce((s,x,i)=>s+(x-mx)*(ys[i]-my),0)/den:0;
 const intercept=my-slope*mx;
 const fitted=xs.map(x=>Math.max(0,intercept+slope*x));
 const errors=ys.map((y,i)=>y-fitted[i]);
 const mae=errors.reduce((s,e)=>s+Math.abs(e),0)/n;
 const rmse=Math.sqrt(errors.reduce((s,e)=>s+e*e,0)/n);
 const mapeRows=ys.map((y,i)=>Math.abs(y)>0?Math.abs((y-fitted[i])/y)*100:null).filter(v=>v!=null);
 const mape=mapeRows.length?mapeRows.reduce((s,e)=>s+e,0)/mapeRows.length:null;
 return {data,xs,ys,slope,intercept,metrics:{observations:n,mae,rmse,mapePct:mape,slope,intercept,lastHistoricalYear:xs[n-1]},model:{name:'linear_trend_baseline',type:'ordinary_least_squares_trend',nonNegativeFloor:true}};
}
function predict(model,year){return Math.max(0,model.intercept+model.slope*year);}
function forecast(model,horizon){const last=model.xs[model.xs.length-1];return Array.from({length:horizon},(_,i)=>{const year=last+i+1;return{year,predicted:predict(model,year),method:'linear_trend_baseline'};});}

function backtest(rows,field,minTrain=3){
 const data=rows.filter(r=>num(r.year)!=null&&num(r[field])!=null).sort((a,b)=>num(a.year)-num(b.year));
 if(data.length<=minTrain)return {status:'insufficient_data',observations:data.length,folds:0};
 const errors=[];
 for(let i=minTrain;i<data.length;i++){
  const train=data.slice(0,i);
  const m=linearModel(train,field);
  const actual=num(data[i][field]),pred=predict(m,num(data[i].year));
  errors.push({year:num(data[i].year),actual,predicted:pred,absoluteError:Math.abs(actual-pred),squaredError:(actual-pred)**2,ape:actual!==0?Math.abs((actual-pred)/actual)*100:null});
 }
 const valid=errors.filter(e=>e.ape!=null);
 return {status:'ok',observations:data.length,folds:errors.length,mae:errors.reduce((s,e)=>s+e.absoluteError,0)/errors.length,rmse:Math.sqrt(errors.reduce((s,e)=>s+e.squaredError,0)/errors.length),mapePct:valid.length?valid.reduce((s,e)=>s+e.ape,0)/valid.length:null,foldsDetail:errors};
}
function cagr(rows,field){
 const d=rows.filter(r=>num(r.year)!=null&&num(r[field])!=null).sort((a,b)=>num(a.year)-num(b.year));
 if(d.length<2)return null;
 const first=num(d[0][field]),last=num(d[d.length-1][field]),years=num(d[d.length-1].year)-num(d[0].year);
 if(first<=0||last<0||years<=0)return null;
 return (Math.pow(last/first,1/years)-1)*100;
}
function movingAverageForecast(rows,field,horizon,window=3){
 const d=rows.filter(r=>num(r.year)!=null&&num(r[field])!=null).sort((a,b)=>num(a.year)-num(b.year));
 if(!d.length)return [];
 const values=d.map(r=>num(r[field]));
 const out=[];
 for(let i=0;i<horizon;i++){const start=Math.max(0,values.length-window),slice=values.slice(start);const v=slice.reduce((a,b)=>a+b,0)/slice.length;out.push({year:num(d[d.length-1].year)+i+1,predicted:Math.max(0,v),method:'moving_average_baseline',window});values.push(v);}
 return out;
}
async function loadRows(iso3,item){
 const snap=await db.collection('auren_agri_production_history').limit(2000).get();
 return snap.docs.map(d=>d.data()).filter(r=>(!iso3||String(r.iso3||'').toUpperCase()===iso3)&&(!item||clean(r.item).toLowerCase()===item.toLowerCase()));
}
function priceValue(r){return num(r.price??r.Price??r.value??r.Value??r.pricePerTon);}
async function latestPrice(iso3,item){
 const [local,global]=await Promise.all([db.collection('auren_agri_local_market_prices').limit(1000).get(),db.collection('auren_agri_global_commodity_prices').limit(100).get()]);
 const rows=[...local.docs.map(d=>d.data()).filter(r=>String(r.iso3||r.countryCode||'').toUpperCase()===iso3&&clean(r.item||r.commodity).toLowerCase().includes(item.toLowerCase())),...global.docs.map(d=>d.data()).filter(r=>clean(r.commodity||r.id).toLowerCase().includes(item.toLowerCase()))].filter(r=>priceValue(r)!=null).sort((a,b)=>String(b.observedAt||b.date||'').localeCompare(String(a.observedAt||a.date||'')));
 if(!rows.length)return null;const r=rows[0];return{value:priceValue(r),currency:r.currency||null,unit:r.unit||null,source:r.source||r.exchange||'market'};
}
async function latestCost(iso3,item){
 const slug=item.toLowerCase().replace(/[^a-z0-9]+/g,'_'),snap=await db.collection('auren_agri_cost_evidence').doc(iso3+'_'+slug).get();
 if(!snap.exists)return null;const items=Array.isArray(snap.data()?.items)?snap.data().items:[],opex=items.find(x=>String(x.category||'').toLowerCase()==='opex'&&num(x.value)!=null);
 return opex?{value:num(opex.value),currency:opex.currency||null,unit:opex.unit||null,source:opex.source||null}:null;
}

exports.aurenAgriProductionForecast=onCall(async request=>{
 auth(request);const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase(),item=clean(request.data?.item||request.data?.crop),horizon=Math.min(Math.max(num(request.data?.horizon)||5,1),10);
 const rows=await loadRows(iso3,item),pm=linearModel(rows,'production'),ym=linearModel(rows,'yieldValue'),am=linearModel(rows,'area'),production=forecast(pm,horizon),yieldForecast=forecast(ym,horizon),areaForecast=forecast(am,horizon),price=await latestPrice(iso3,item),cost=await latestCost(iso3,item);
 const revenueForecast=production.map((p,i)=>{const revenue=price?p.predicted*price.value:null,profit=revenue!=null&&cost?revenue-cost.value:null;return{year:p.year,predictedProduction:p.predicted,predictedYield:yieldForecast[i]?.predicted??null,predictedArea:areaForecast[i]?.predicted??null,revenue,profit,revenueCurrency:price?.currency??null,revenueUnit:price?.unit??null,profitCurrency:price?.currency&&cost?.currency===price.currency?price.currency:null};});
 return{status:production.length?'ok':'no_data',iso3,item,horizon,historyYears:rows.length,forecast:production,yieldForecast,areaForecast,revenueForecast,baseline:{production:pm.metrics,yield:ym.metrics,area:am.metrics,model:pm.model,cagrPct:{production:cagr(rows,'production'),yield:cagr(rows,'yieldValue'),area:cagr(rows,'area')}},market:{price,cost},profitabilityStatus:cost&&price?'calculated':'needs_sourced_price_and_opex',limitations:['Baseline trend model; not an agronomic causal forecast.','Revenue assumes latest compatible price remains constant across forecast years.']};
});

exports.aurenAgriForecastBacktest=onCall(async request=>{
 auth(request);const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase(),item=clean(request.data?.item||request.data?.crop),rows=await loadRows(iso3,item);
 const fields={production:'production',yield:'yieldValue',area:'area'};
 const backtests={},movingAverages={};
 for(const [key,field] of Object.entries(fields)){backtests[key]=backtest(rows,field,3);movingAverages[key]=movingAverageForecast(rows,field,5,3);}
 return{status:rows.length?'ok':'no_data',iso3,item,backtests,movingAverages,comparison:{purpose:'Compare simple baselines before introducing more complex models.',candidates:['linear_trend_baseline','moving_average_baseline'],selectionRule:'Use diagnostics and backtesting evidence; no automatic claim of superiority.'}};
});

exports.aurenAgriSeasonComparison=onCall(async request=>{
 auth(request);const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase(),item=clean(request.data?.item||request.data?.crop),rows=(await loadRows(iso3,item)).sort((a,b)=>num(a.year)-num(b.year));
 return{status:rows.length?'ok':'no_data',rows:rows.map((r,i)=>{const prev=rows[i-1],current=num(r.production),previous=prev?num(prev.production):null;return{...r,growthPct:previous&&current!=null?((current-previous)/previous)*100:null};})};
});

exports.aurenAgriCropScenario=onCall(async request=>{
 auth(request);const iso3=clean(request.data?.iso3||request.data?.country).toUpperCase(),item=clean(request.data?.item||request.data?.crop),baseProduction=num(request.data?.baseProduction),yieldChangePct=num(request.data?.yieldChangePct)||0,areaChangePct=num(request.data?.areaChangePct)||0,priceChangePct=num(request.data?.priceChangePct)||0,costChangePct=num(request.data?.costChangePct)||0;
 if(baseProduction==null||baseProduction<0)throw new Error('baseProduction is required.');
 const production=baseProduction*(1+yieldChangePct/100)*(1+areaChangePct/100),price=await latestPrice(iso3,item),cost=await latestCost(iso3,item),revenue=price?production*price.value*(1+priceChangePct/100):null,profit=revenue!=null&&cost?revenue-cost.value*(1+costChangePct/100):null;
 return{status:'ok',iso3,item,assumptions:{baseProduction,yieldChangePct,areaChangePct,priceChangePct,costChangePct},outputs:{projectedProduction:production,productionChangePct:(production/baseProduction-1)*100,revenue,profit,revenueCurrency:price?.currency??null,profitCurrency:price&&cost&&price.currency===cost.currency?price.currency:null},market:{price,cost},profitabilityStatus:price&&cost?'calculated':'needs_sourced_price_and_opex'};
});