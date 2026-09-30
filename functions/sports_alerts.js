'use strict';

const {onSchedule}=require('firebase-functions/v2/scheduler');
const {getFirestore,FieldValue}=require('firebase-admin/firestore');
const {getMessaging}=require('firebase-admin/messaging');
const {fixtureId,detectFreshEvents,buildPushMessage,chunk}=require('./sports_alerts_logic');

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

async function runAurenSportsAlerts(options={}){
  const store=options.db||db;
  const fetchLiveFn=options.fetchLiveFn||fetchLive;
  const fetchTodayFn=options.fetchTodayFn||fetchToday;
  const messagingFn=options.getMessagingFn||getMessaging;
  const skipRunGuard=options.skipRunGuard===true;
  if(!skipRunGuard){
    const runRef=store.collection('sports_alert_runs').doc('live');
    const runSnap=await runRef.get();
    const lastRunMs=runSnap.exists?Number(runSnap.data()?.startedAtMs||0):0;
    if(Date.now()-lastRunMs<45000)return {skipped:true,reason:'recent_run'};
    await runRef.set({startedAtMs:Date.now(),updatedAt:FieldValue.serverTimestamp()},{merge:true});
  }

  const live=await fetchLiveFn();
  const today=await fetchTodayFn();
  const fixturesById=new Map();
  for(const f of today){const id=fixtureId(f);if(id)fixturesById.set(id,f);}
  for(const f of live){const id=fixtureId(f);if(id)fixturesById.set(id,f);}
  const fixtures=[...fixturesById.values()];
  const writes=[];
  const pushJobs=[];
  const followingByTeam=new Map();
  const followingSnap=await store.collectionGroup('sportsFollowing').where('sport','==','football').limit(500).get();
  for(const d of followingSnap.docs){const data=d.data()||{};const uid=d.ref.parent.parent?.id;const teamId=String(data.id||'');if(uid&&teamId){if(!followingByTeam.has(teamId))followingByTeam.set(teamId,new Set());followingByTeam.get(teamId).add(uid);}}
  for(const f of fixtures){
    const id=fixtureId(f); if(!id) continue;
    const home=String(f?.teams?.home?.name||'Home');
    const away=String(f?.teams?.away?.name||'Away');
    const score={home:Number(f?.goals?.home??0),away:Number(f?.goals?.away??0)};
    const ref=store.collection('sports_live_state').doc(id);
    const snap=await ref.get();
    const previous=snap.exists?snap.data():{};
    const events=Array.isArray(f?.events)?f.events:[];
    const status=String(f?.fixture?.status?.short||'');
    const previousStatus=String(previous.status||'');
    const seen=Array.isArray(previous.eventKeys)?previous.eventKeys:[];
    const fresh=detectFreshEvents({
      events,
      seen,
      previousStatus,
      status,
      fixtureStatusElapsed:f?.fixture?.status?.elapsed,
      previousExists:snap.exists,
      score,
      previousScore:{home:previous.homeScore,away:previous.awayScore},
    });
    const users=new Set([...(followingByTeam.get(String(f?.teams?.home?.id||''))||[]),...(followingByTeam.get(String(f?.teams?.away?.id||''))||[])]);
    for(const uid of users){
      const pref=await store.collection('users').doc(uid).collection('sportsSettings').doc('alerts').get();
      const settings=pref.exists?pref.data():{enabled:true,types:['kickoff','goal','red_card','full_time']};
      if(settings.enabled===false) continue;
      const allowed=Array.isArray(settings.types)?settings.types:[];
      for(const e of fresh.filter(x=>allowed.includes(x.type))){
        const notificationId=id+'_'+e.key.replace(/[^a-zA-Z0-9_-]/g,'_');
        writes.push({ref:store.collection('users').doc(uid).collection('sportsAlerts').doc(notificationId),data:{
          fixtureId:id,type:e.type,title:e.type==='goal'?'هدف في المباراة':e.type==='red_card'?'بطاقة حمراء':e.type==='kickoff'?'بدأت المباراة':e.type==='full_time'?'انتهت المباراة':'تحديث المباراة',
          body:home+' × '+away+(e.player?' — '+e.player:'')+(e.minute?' ('+e.minute+"')":''),
          home,away,score,createdAt:FieldValue.serverTimestamp(),read:false,
        },merge:true});
        pushJobs.push({
          uid,
          notificationId,
          title:e.type==='goal'?'هدف في المباراة':e.type==='red_card'?'بطاقة حمراء':e.type==='kickoff'?'بدأت المباراة':e.type==='full_time'?'انتهت المباراة':'تحديث المباراة',
          body:home+' × '+away+(e.player?' — '+e.player:'')+(e.minute?' ('+e.minute+"')":''),
          type:e.type,
          fixtureId:id,
        });
      }
    }
    writes.push({ref,data:{homeScore:score.home,awayScore:score.away,status,eventKeys:[...new Set([...seen,...fresh.map(e=>e.key)])].slice(-100),updatedAt:FieldValue.serverTimestamp()},merge:true});
  }
  // Firestore batches are capped at 500 writes. Keep headroom for future fields.
  for(const group of chunk(writes,450)){
    const batch=store.batch();
    for(const write of group) batch.set(write.ref,write.data,{merge:write.merge!==false});
    await batch.commit();
  }

  let pushSent=0;
  let pushFailed=0;
  for(const job of pushJobs){
    const tokenSnap=await store.collection('users').doc(job.uid).collection('fcmTokens').where('enabled','==',true).limit(100).get();
    const tokens=tokenSnap.docs.map(d=>String(d.data()?.token||'').trim()).filter(Boolean);
    if(!tokens.length) continue;
    const response=await messagingFn().sendEachForMulticast(buildPushMessage({...job,tokens}));
    pushSent+=response.successCount;
    pushFailed+=response.failureCount;
    const invalid=[];
    response.responses.forEach((result,index)=>{
      const code=result.error?.code||'';
      if(code==='messaging/registration-token-not-registered'||code==='messaging/invalid-registration-token'){
        invalid.push(tokens[index]);
      }
    });
    for(const token of invalid){
      for(const doc of tokenSnap.docs){
        if(String(doc.data()?.token||'')===token) await doc.ref.delete();
      }
    }
  }

  return {fixtures:fixtures.length,live:live.length,today:today.length,pushSent,pushFailed};
}

exports.runAurenSportsAlerts=runAurenSportsAlerts;
exports.refreshAurenSportsAlerts=onSchedule(
 {schedule:'every 1 minutes',region:'us-central1',timeoutSeconds:50,memory:'256MiB'},
 async()=>runAurenSportsAlerts()
);
