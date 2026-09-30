'use strict';
const {onCall,HttpsError}=require('firebase-functions/v2/https');

async function fetchJson(url, options={}) {
  const response=await fetch(url,{...options,headers:{'user-agent':'AUREN-Sports/1.1',...(options.headers||{})}});
  if(!response.ok) throw new Error('provider_http_'+response.status);
  return response.json();
}

function mapFootball(rows, source) {
  return (Array.isArray(rows)?rows:[]).map(x=>({
    id:String(x.fixture?.id||x.idEvent||''),
    sport:'football',
    title:[x.teams?.home?.name,x.teams?.away?.name].filter(Boolean).join(' vs ') || String(x.strEvent||''),
    status:String(x.fixture?.status?.short||x.strStatus||''),
    date:x.fixture?.date||x.dateEvent||null,
    league:x.league?.name||x.strLeague||'',
    country:x.league?.country||x.strCountry||'',
    venue:x.fixture?.venue?.name||x.strVenue||'',
    homeLogo:x.teams?.home?.logo||x.strHomeTeamBadge||'',
    awayLogo:x.teams?.away?.logo||x.strAwayTeamBadge||'',
    source,
  })).filter(x=>x.title);
}

exports.searchAurenSports=onCall({region:'us-central1',timeoutSeconds:25,memory:'256MiB'},async(request)=>{
  if(!request.auth?.uid) throw new HttpsError('unauthenticated','Authentication is required.');
  const q=String(request.data?.query||'').trim().slice(0,100);
  const sport=String(request.data?.sport||'football').trim().toLowerCase() || 'football';
  const date=String(request.data?.date||'').trim().slice(0,10);
  const apiKey=String(process.env.API_FOOTBALL_KEY||'').trim();
  const tsdbKey=String(process.env.THESPORTSDB_API_KEY||'').trim();

  const providers=[];
  if(apiKey) {
    try {
      const url=new URL('https://v3.football.api-sports.io/fixtures');
      if(date) url.searchParams.set('date',date); else url.searchParams.set('next','20');
      if(q) url.searchParams.set('team',q);
      const data=await fetchJson(url,{headers:{'x-apisports-key':apiKey}});
      providers.push(...mapFootball(data?.response,'API-Football'));
    } catch (_) {}
  }
  if(tsdbKey && q) {
    try {
      const url=new URL('https://www.thesportsdb.com/api/v1/json/'+encodeURIComponent(tsdbKey)+'/searchevents.php');
      url.searchParams.set('e',q);
      const data=await fetchJson(url);
      providers.push(...mapFootball(data?.event,'TheSportsDB'));
    } catch (_) {}
  }

  const seen=new Set();
  const results=providers.filter(x=>{const k=(x.source||'')+':'+x.id;if(!x.id||seen.has(k))return false;seen.add(k);return true;}).slice(0,50);
  return {
    status: results.length ? 'ok' : 'not_configured',
    providers: ['API-Football','TheSportsDB'],
    results,
    sourceUrls:{
      'API-Football':'https://www.api-football.com/',
      'TheSportsDB':'https://www.thesportsdb.com/api.php'
    },
    message: results.length ? '' : 'Configure API_FOOTBALL_KEY and/or THESPORTSDB_API_KEY in Firebase Functions.'
  };
});
