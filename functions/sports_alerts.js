'use strict';

const {onSchedule}=require('firebase-functions/v2/scheduler');
const {getFirestore,FieldValue}=require('firebase-admin/firestore');

const db=getFirestore();
const API_BASE='https://v3.football.api-sports.io';

async function fetchLive(){
  const key=String(process.env.API_FOOTBALL_KEY||'').trim();
  if(!key) return [];
  const response=await fetch(API_BASE+'/fixtures?live=all',{headers:{'x-apisports-key':key}});
  if(!response.ok) throw new Error('API-Football live request failed: '+response.status);
  const data=await response.json();
  const live=Array.isArray(data.response)?data.response:[];
  return await enrichFixtures(live,key);
}

async function fetchToday(){
  const key=String(process.env.API_FOOTBALL_KEY||'').trim();
  if(!key) return [];
  const date=new Date().toISOString().slice(0,10);
  const response=await fetch(API_BASE+'/fixtures?date='+date,{headers:{'x-apisports-key':key}});
  if(!response.ok) return [];
  const data=await response.json();
  return Array.isArray(data.response)?data.response:[];
}

async function enrichFixtures(rows,key){
  const detailed=[];
  for(let i=0;i<rows.length;i+=20){
    const ids=rows.slice(i,i+20).map(f=>f?.fixture?.id).filter(Boolean).join('-');
    if(!ids) continue;
    const detail=await fetch(API_BASE+'/fixtures?ids='+ids,{headers:{'x-apisports-key':key}});
    if(detail.ok){
      const detailData=await detail.json();
      detailed.push(...(Array.isArray(detailData.response)?detailData.response:[]));
    }
  }
  return detailed.length?detailed:rows;
}

function fixtureId(f){return String(f?.fixture?.id||'').trim();}
function eventType(e){
  const t=String(e?.type||'').toLowerCase();
  if(t==='goal') return 'goal';
  if(t==='card' && String(e?.detail||'').toLowerCase().includes('red')) return 'red_card';
  return '';
}

exports.refreshAurenSportsAlerts=onSchedule(
 {schedule:'every 1 minutes',region:'us-central1',timeoutSeconds:50,memory:'256MiB'},
 async()=>{
  const live=await fetchLive();
  const today=await fetchToday();
  const fixturesById=new Map();
  for(const f of today){const id=fixtureId(f);if(id)fixturesById.set(id,f);}
  for(const f of fixtures){const id=fixtureId(f);if(id)fixturesById.set(id,f);}
  const fixtures=[...fixturesById.values()];
  const runRef=db.collection('sports_alert_runs').doc('live');
  const runSnap=await runRef.get();
  const lastRunMs=runSnap.exists?Number(runSnap.data()?.startedAtMs||0):0;
  if(Date.now()-lastRunMs<45000)return {skipped:true,reason:'recent_run'};
  await runRef.set({startedAtMs:Date.now(),updatedAt:FieldValue.serverTimestamp()},{merge:true});
  const batch=db.batch();
  const followingByTeam=new Map();
  const followingSnap=await db.collectionGroup('sportsFollowing').where('sport','==','football').limit(500).get();
  for(const d of followingSnap.docs){const data=d.data()||{};const uid=d.ref.parent.parent?.id;const teamId=String(data.id||'');if(uid&&teamId){if(!followingByTeam.has(teamId))followingByTeam.set(teamId,new Set());followingByTeam.get(teamId).add(uid);}}
  for(const f of live){
    const id=fixtureId(f); if(!id) continue;
    const home=String(f?.teams?.home?.name||'Home');
    const away=String(f?.teams?.away?.name||'Away');
    const score={home:Number(f?.goals?.home??0),away:Number(f?.goals?.away??0)};
    const ref=db.collection('sports_live_state').doc(id);
    const snap=await ref.get();
    const previous=snap.exists?snap.data():{};
    const events=Array.isArray(f?.events)?f.events:[];
    const status=String(f?.fixture?.status?.short||'');
    const previousStatus=String(previous.status||'');
    const seen=Array.isArray(previous.eventKeys)?previous.eventKeys:[];
    const fresh=events.map(e=>({key:String(e?.time?.elapsed||'')+'|'+String(e?.player?.id||e?.player?.name||'')+'|'+String(e?.type||'')+'|'+String(e?.detail||''),type:eventType(e),minute:Number(e?.time?.elapsed||0),player:String(e?.player?.name||'') })).filter(e=>e.type && e.key && !seen.includes(e.key));
    if(snap.exists && previousStatus && previousStatus!=='1H' && previousStatus!=='HT' && previousStatus!=='2H' && previousStatus!=='ET' && previousStatus!=='P' && ['1H','HT','2H','ET','P'].includes(status)){
      fresh.push({key:'kickoff|'+status,type:'kickoff',minute:Number(f?.fixture?.status?.elapsed||0),player:''});
    }
    if(snap.exists && previousStatus!=='FT' && status==='FT'){
      fresh.push({key:'full_time|FT',type:'full_time',minute:Number(f?.fixture?.status?.elapsed||0),player:''});
    }
    if(snap.exists && (score.home!==Number(previous.homeScore??score.home)||score.away!==Number(previous.awayScore??score.away))){
      fresh.push({key:'score|'+score.home+'|'+score.away,type:'goal',minute:0,player:''});
    }
    const users=new Set([...(followingByTeam.get(String(f?.teams?.home?.id||''))||[]),...(followingByTeam.get(String(f?.teams?.away?.id||''))||[])]);
    for(const uid of users){
      const pref=await db.collection('users').doc(uid).collection('sportsSettings').doc('alerts').get();
      const settings=pref.exists?pref.data():{enabled:true,types:['kickoff','goal','red_card','full_time']};
      if(settings.enabled===false) continue;
      const allowed=Array.isArray(settings.types)?settings.types:[];
      for(const e of fresh.filter(x=>allowed.includes(x.type))){
        const notificationId=id+'_'+e.key.replace(/[^a-zA-Z0-9_-]/g,'_');
        batch.set(db.collection('users').doc(uid).collection('sportsAlerts').doc(notificationId),{
          fixtureId:id,type:e.type,title:e.type==='goal'?'هدف في المباراة':e.type==='red_card'?'بطاقة حمراء':'تحديث المباراة',
          body:home+' × '+away+(e.player?' — '+e.player:'')+(e.minute?' ('+e.minute+"')":''),
          home,away,score,createdAt:FieldValue.serverTimestamp(),read:false,
        },{merge:true});
      }
    }
    batch.set(ref,{homeScore:score.home,awayScore:score.away,status,eventKeys:[...new Set([...seen,...fresh.map(e=>e.key)])].slice(-100),updatedAt:FieldValue.serverTimestamp()},{merge:true});
  }
  await batch.commit();
  return {fixtures:fixtures.length,live:live.length,today:today.length};
});
