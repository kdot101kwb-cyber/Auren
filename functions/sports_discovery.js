'use strict';
const {onCall,HttpsError}=require('firebase-functions/v2/https');

exports.searchAurenSports=onCall({region:'us-central1',timeoutSeconds:20,memory:'256MiB'},async(request)=>{
  if(!request.auth?.uid) throw new HttpsError('unauthenticated','Authentication is required.');
  const apiKey=String(process.env.API_FOOTBALL_KEY||'').trim();
  if(!apiKey) return {status:'not_configured',source:'API-Football',sourceUrl:'https://www.api-football.com/',results:[]};
  const q=String(request.data?.query||'').trim().slice(0,100);
  const date=String(request.data?.date||'').trim().slice(0,10);
  const sport=String(request.data?.sport||'').trim().toLowerCase();
  const url=new URL('https://v3.football.api-sports.io/fixtures');
  if(date) url.searchParams.set('date',date);
  else url.searchParams.set('next','20');
  if(q) url.searchParams.set('team',q);
  const response=await fetch(url,{headers:{'x-apisports-key':apiKey,'user-agent':'AUREN-Sports/1.0'}});
  if(!response.ok) throw new HttpsError('unavailable','Sports data provider is unavailable.');
  const data=await response.json();
  const results=(Array.isArray(data?.response)?data.response:[]).map(x=>({
    id:String(x.fixture?.id||''),sport:sport||'football',
    title:[x.teams?.home?.name,x.teams?.away?.name].filter(Boolean).join(' vs '),
    status:String(x.fixture?.status?.short||''),date:x.fixture?.date||null,
    league:x.league?.name||'',country:x.league?.country||'',
    venue:x.fixture?.venue?.name||'',homeLogo:x.teams?.home?.logo||'',awayLogo:x.teams?.away?.logo||'',
    sourceUrl:'https://www.api-football.com/'
  }));
  return {status:'ok',source:'API-Football',sourceUrl:'https://www.api-football.com/',results};
});
