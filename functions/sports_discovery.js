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
    fixtureId:String(x.fixture?.id||x.idEvent||''),
    homeTeamId:String(x.teams?.home?.id||''),
    awayTeamId:String(x.teams?.away?.id||''),
    score:(x.goals?.home!=null||x.goals?.away!=null)?String(x.goals?.home??'-')+'-'+String(x.goals?.away??'-'):'',
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

async function fetchApiSportResource(apiKey, sport, resource, params={}) {
  const base = sport === 'football'
    ? 'https://v3.football.api-sports.io'
    : 'https://v1.' + sport + '.api-sports.io';
  const url = new URL(base + '/' + resource);
  Object.entries(params).forEach(([k,v]) => {
    if (v !== undefined && v !== null && String(v).trim() !== '') url.searchParams.set(k,String(v));
  });
  const data = await fetchJson(url,{headers:{'x-apisports-key':apiKey}});
  return Array.isArray(data?.response) ? data.response : [];
}

function mapCompetitionRows(rows, sport) {
  return rows.map(x => ({
    id:String(x.league?.id || x.id || ''),
    sport,
    name:x.league?.name || x.name || '',
    country:x.country?.name || x.country?.code || x.league?.country || '',
    logo:x.league?.logo || x.logo || '',
    type:x.league?.type || x.type || '',
    season:x.seasons?.[0]?.year || x.season?.year || null,
    source:'API-Sports'
  })).filter(x=>x.id && x.name);
}

function mapTeamRows(rows, sport) {
  return rows.map(x => ({
    id:String(x.team?.id || x.id || ''),
    sport,
    name:x.team?.name || x.name || '',
    country:x.team?.country || x.country?.name || '',
    logo:x.team?.logo || x.logo || '',
    source:'API-Sports'
  })).filter(x=>x.id && x.name);
}

exports.searchAurenSports=onCall({region:'us-central1',timeoutSeconds:25,memory:'256MiB'},async(request)=>{
  if(!request.auth?.uid) throw new HttpsError('unauthenticated','Authentication is required.');
  const q=String(request.data?.query||'').trim().slice(0,100);
  const sport=String(request.data?.sport||'football').trim().toLowerCase() || 'football';
  const date=String(request.data?.date||'').trim().slice(0,10);
  const resource=String(request.data?.resource||'games').trim().toLowerCase();
  const country=String(request.data?.country||'').trim().slice(0,80);
  const leagueId=String(request.data?.leagueId||'').trim();
  const apiKey=String(process.env.API_FOOTBALL_KEY||'').trim();
  const tsdbKey=String(process.env.THESPORTSDB_API_KEY||'').trim();

  const apiSportMap={
    football:'football', basketball:'basketball', tennis:'tennis', cricket:'cricket',
    baseball:'baseball', hockey:'hockey', handball:'handball', volleyball:'volleyball',
    rugby:'rugby', mma:'mma', formula1:'formula1', afl:'afl', nfl:'nfl',
    americanfootball:'nfl'
  };
  const selectedApiSport=apiSportMap[sport]||'football';
  const apiKeysBySport={
    football:process.env.API_FOOTBALL_KEY,
    basketball:process.env.API_BASKETBALL_KEY,
    baseball:process.env.API_BASEBALL_KEY,
    hockey:process.env.API_HOCKEY_KEY,
    handball:process.env.API_HANDBALL_KEY,
    volleyball:process.env.API_VOLLEYBALL_KEY,
    rugby:process.env.API_RUGBY_KEY,
    mma:process.env.API_MMA_KEY,
    formula1:process.env.API_FORMULA1_KEY,
    afl:process.env.API_AFL_KEY,
    nfl:process.env.API_NFL_KEY,
    tennis:process.env.API_TENNIS_KEY,
    cricket:process.env.API_CRICKET_KEY
  };
  const selectedApiKey=String(apiKeysBySport[selectedApiSport]||apiKey||'').trim();
  const providers=[];
  const sourceUrls={
    'API-Sports':'https://api-sports.io/',
    'TheSportsDB':'https://www.thesportsdb.com/api.php'
  };

  if(selectedApiKey && selectedApiSport==='football' && (resource==='live' || resource==='today')) {
    try {
      const endpoint='fixtures';
      const params=resource==='live'?{live:'all'}:{date:date||new Date().toISOString().slice(0,10)};
      const rows=await fetchApiSportResource(selectedApiKey,'football',endpoint,params);
      return {status:'ok',resource,providers:['API-Sports'],results:mapFootball(rows,'API-Sports'),sourceUrls};
    } catch (_) {}
  }

  if(selectedApiKey) {
    try {
      if(resource==='leagues' || resource==='competitions') {
        const rows=await fetchApiSportResource(selectedApiKey,selectedApiSport,'leagues',country?{country}:{});
        return {status:'ok',resource:'leagues',providers:['API-Sports'],results:mapCompetitionRows(rows,selectedApiSport),sourceUrls};
      }
      if(resource==='standings') {
        const rows=await fetchApiSportResource(selectedApiKey,selectedApiSport,'standings',leagueId?{league:leagueId,season:request.data?.season}:country?{country,season:request.data?.season}:{season:request.data?.season});
        return {status:'ok',resource:'standings',providers:['API-Sports'],results:rows,sourceUrls};
      }
      if(resource==='players') {
        const params=q?{search:q}:leagueId?{league:leagueId,season:request.data?.season}:{};
        const rows=await fetchApiSportResource(selectedApiKey,selectedApiSport,'players',params);
        return {status:'ok',resource:'players',providers:['API-Sports'],results:rows,sourceUrls};
      }
      if(resource==='team_stats') {
        const teamId=String(request.data?.teamId||'').trim();
        const rows=await fetchApiSportResource(selectedApiKey,selectedApiSport,'teams/statistics',teamId?{team:teamId,league:leagueId,season:request.data?.season}:{});
        return {status:'ok',resource:'team_stats',providers:['API-Sports'],results:rows,sourceUrls};
      }
      if(selectedApiSport==='football' && ['match_events','match_lineups','match_stats','match_players','h2h'].includes(resource)) {
        const fixtureId=String(request.data?.gameId||request.data?.fixtureId||'').trim();
        let endpoint='fixtures';
        let params={};
        if(resource==='match_events'){ endpoint='fixtures/events'; params={fixture:fixtureId}; }
        if(resource==='match_lineups'){ endpoint='fixtures/lineups'; params={fixture:fixtureId}; }
        if(resource==='match_stats'){ endpoint='fixtures/statistics'; params={fixture:fixtureId}; }
        if(resource==='match_players'){ endpoint='fixtures/players'; params={fixture:fixtureId}; }
        if(resource==='h2h'){
          const home=String(request.data?.homeTeamId||'').trim();
          const away=String(request.data?.awayTeamId||'').trim();
          endpoint='fixtures/headtohead'; params={h2h:home+'-'+away,last:10};
        }
        if(resource!=='h2h' && !fixtureId) return {status:'invalid',resource,providers:['API-Sports'],results:[],sourceUrls};
        if(resource==='h2h' && (!request.data?.homeTeamId || !request.data?.awayTeamId)) return {status:'invalid',resource,providers:['API-Sports'],results:[],sourceUrls};
        const rows=await fetchApiSportResource(selectedApiKey,'football',endpoint,params);
        return {status:'ok',resource,providers:['API-Sports'],results:rows,sourceUrls};
      }
      if(resource==='game_details') {
        const gameId=String(request.data?.gameId||'').trim();
        const rows=await fetchApiSportResource(selectedApiKey,selectedApiSport,selectedApiSport==='football'?'fixtures':'games',gameId?{id:gameId}:{});
        return {status:'ok',resource:'game_details',providers:['API-Sports'],results:rows,sourceUrls};
      }
      if(resource==='teams') {
        const rows=await fetchApiSportResource(selectedApiKey,selectedApiSport,'teams',q?{search:q}:country?{country}:{});
        return {status:'ok',resource:'teams',providers:['API-Sports'],results:mapTeamRows(rows,selectedApiSport),sourceUrls};
      }
    } catch (_) {}

    try {
      if(selectedApiSport==='football') {
        const url=new URL('https://v3.football.api-sports.io/fixtures');
        if(date) url.searchParams.set('date',date); else url.searchParams.set('next','20');
        if(q) url.searchParams.set('team',q);
        const data=await fetchJson(url,{headers:{'x-apisports-key':selectedApiKey}});
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
