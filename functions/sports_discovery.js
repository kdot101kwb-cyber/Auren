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

  const apiSportMap={
    football:'football', basketball:'basketball', tennis:'tennis', cricket:'cricket',
    baseball:'baseball', hockey:'hockey', handball:'handball', volleyball:'volleyball',
    rugby:'rugby', mma:'mma', formula1:'formula1', afl:'afl', nfl:'nfl',
    americanfootball:'nfl', formula1:'formula1'
  };
  const selectedApiSport=apiSportMap[sport]||'football';
  const providers=[];
  const sourceUrls={
    'API-Sports':'https://api-sports.io/',
    'TheSportsDB':'https://www.thesportsdb.com/api.php'
  };

  if(apiKey) {
    try {
      if(selectedApiSport==='football') {
        const url=new URL('https://v3.football.api-sports.io/fixtures');
        if(date) url.searchParams.set('date',date); else url.searchParams.set('next','20');
        if(q) url.searchParams.set('team',q);
        const data=await fetchJson(url,{headers:{'x-apisports-key':apiKey}});
        providers.push(...mapFootball(data?.response,'API-Sports'));
      } else {
        const base='https://v1.'+selectedApiSport+'.api-sports.io/games';
        const url=new URL(base);
        if(date) url.searchParams.set('date',date); else url.searchParams.set('next','20');
        if(q) url.searchParams.set('team',q);
        const data=await fetchJson(url,{headers:{'x-apisports-key':apiKey}});
        const rows=Array.isArray(data?.response)?data.response:[];
        providers.push(...rows.map(x=>({
          id:String(x.id||''), sport:selectedApiSport,
          title:[x.teams?.home?.name,x.teams?.away?.name].filter(Boolean).join(' vs '),
          status:String(x.status?.short||x.status?.long||''),
          date:x.date||null, league:x.league?.name||'', country:x.country?.name||x.country?.code||'',
          venue:x.venue?.name||'', homeLogo:x.teams?.home?.logo||'', awayLogo:x.teams?.away?.logo||'',
          source:'API-Sports'
        })).filter(x=>x.title));
      }
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
  const results=providers.filter(x=>{const k=(x.sport||'')+':'+(x.id||'')+':'+(x.source||'');if(!x.id||seen.has(k))return false;seen.add(k);return true;}).slice(0,50);
  return {
    status: results.length ? 'ok' : 'not_configured',
    providers: ['API-Sports','TheSportsDB'],
    results,
    sourceUrls:{
      'API-Sports':'https://api-sports.io/',
      'TheSportsDB':'https://www.thesportsdb.com/api.php'
    },
    message: results.length ? '' : 'Configure API_FOOTBALL_KEY and/or THESPORTSDB_API_KEY in Firebase Functions.'
  };
});
