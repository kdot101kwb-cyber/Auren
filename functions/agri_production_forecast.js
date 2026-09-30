'use strict';
const {onCall}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');
const db=admin.firestore();
function auth(r){if(!r.auth?.uid)throw new Error('Authentication is required.');}
function clean(v){return String(v??'').trim();}
function num(v){const n=Number(v);return Number.isFinite(n)?n:null;}
function linear(rows,field,horizon){
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
 const last=xs[n-1];
 const forecast=Array.from({length:horizon},(_,i)=>{const year=last+i+1;return{year,predicted:Math.max(0,intercept+slope*year),method:'linear_trend_baseline'};});
 return {forecast,metrics:{observations:n,mae,rmse,mapePct:mape,slope,intercept,lastHistoricalYear:last},model:{name:'linear_trend_baseline',type:'ordinary_least_squares_trend',nonNegativeFloor:true}};
};