'use strict';

const {onCall}=require('firebase-functions/v2/https');
const admin=require('firebase-admin');

const db=admin.firestore();

const LPI_INDICATORS = {
  overall:'LP.LPI.OVRL.XQ',
  customs:'LP.LPI.CUST.XQ',
  infrastructure:'LP.LPI.INFR.XQ',
  internationalShipments:'LP.LPI.ITRN.XQ',
  logisticsCompetence:'LP.LPI.LOGS.XQ',
  tracking:'LP.LPI.TRAC.XQ',
  timeliness:'LP.LPI.TIME.XQ',
  exportLeadTime:'LP.LPI.EXP.DURS',
  importLeadTime:'LP.LPI.IMP.DURS',
};

exports.aurenWorldBankLogistics = onCall(async(request)=>{
  if(!request.auth?.uid) throw new Error('Authentication is required.');
  const country=String(request.data?.country||'all').trim().toLowerCase();
  const requested=Array.isArray(request.data?.indicators)
    ? request.data.indicators.map(v=>String(v)).filter(v=>Object.prototype.hasOwnProperty.call(LPI_INDICATORS,v))
    : Object.keys(LPI_INDICATORS);
  if(!requested.length) throw new Error('At least one valid logistics indicator is required.');

  const rows=[];
  for(const key of requested){
    const indicator=LPI_INDICATORS[key];
    const url='https://api.worldbank.org/v2/country/'+encodeURIComponent(country)+'/indicator/'+encodeURIComponent(indicator)+'?format=json&per_page=100';
    const response=await fetch(url);
    const raw=await response.text();
    if(!response.ok) continue;
    let data=[];
    try{data=JSON.parse(raw);}catch(_){continue;}
    const values=Array.isArray(data)&&Array.isArray(data[1])?data[1]:[];
    for(const row of values){
      if(row?.value==null) continue;
      rows.push({
        indicator:key,
        indicatorCode:indicator,
        country:row.countryiso3code||country.toUpperCase(),
        year:row.date||null,
        value:Number(row.value),
        unit:key==='overall'||key==='customs'||key==='infrastructure'||key==='internationalShipments'||key==='logisticsCompetence'||key==='tracking'||key==='timeliness'
          ? 'score_1_to_5' : 'days',
        source:'World Bank Logistics Performance Index',
      });
    }
  }

  return {
    status:'ok',
    country,
    indicators:requested,
    rows,
    note:'LPI is a country-level logistics performance signal, not a freight price. It must not be converted into a currency cost without an explicit cost source.',
  };
});

exports.aurenWorldBankLogisticsStore = onCall(async(request)=>{
  if(!request.auth?.uid) throw new Error('Authentication is required.');
  const country=String(request.data?.country||request.data?.iso3||'').trim().toUpperCase();
  if(!/^[A-Z]{3}$/.test(country)) throw new Error('ISO3 country code is required.');
  const rows=request.data?.rows;
  if(!Array.isArray(rows)) throw new Error('rows are required.');

  const accepted=rows.filter(row=>
    row && row.indicator && row.indicatorCode && finiteNumber(row.value)
    && row.source==='World Bank Logistics Performance Index'
  ).map(row=>({
    indicator:String(row.indicator),
    indicatorCode:String(row.indicatorCode),
    year:String(row.year||''),
    value:Number(row.value),
    unit:String(row.unit||''),
    source:String(row.source),
  }));

  await db.collection('auren_agri_logistics_evidence').doc(country).set({
    iso3:country,
    source:'World Bank Logistics Performance Index',
    sourceType:'country_indicator',
    rows:accepted,
    updatedAt:admin.firestore.FieldValue.serverTimestamp(),
  },{merge:true});

  return {status:'stored',iso3:country,count:accepted.length};
});

function finiteNumber(v){
  const n=Number(v);
  return Number.isFinite(n)?n:null;
}
