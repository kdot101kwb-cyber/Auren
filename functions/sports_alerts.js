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
  return Array.isArray(data.response)?data.response:[];
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
  const batch=db.batch();
  for(const f of live){
    const id=fixtureId(f); if(!id) continue;
    const home=String(f?.teams?.home?.name||'Home');
    const away=String(f?.teams?.away?.name||'Away');
    const score={home:Number(f?.goals?.home??0),away:Number(f?.goals?.away??0)};
    const ref=db.collection('sports_live_state').doc(id);
    const snap=await ref.get();
    const previous=snap.exists?snap.data():{};
    const events=Array.isArray(f?.events)?f.events:[];
    const seen=Array.isArray(previous.eventKeys)?previous.eventKeys:[];
    const fresh=events.map(e=>({key:String(e?.time?.elapsed||'')+'|'+String(e?.player?.id||e?.player?.name||'')+'|'+String(e?.type||'')+'|'+String(e?.detail||''),type:eventType(e),minute:Number(e?.time?.elapsed||0),player:String(e?.player?.name||'') })).filter(e=>e.type && e.key && !seen.includes(e.key));
    if(snap.exists && (score.home!==Number(previous.homeScore??score.home)||score.away!==Number(previous.awayScore??score.away))){
      fresh.push({key:'score|'+score.home+'|'+score.away,type:'goal',minute:0,player:''});
    }
    const following=await db.collectionGroup('sportsFollowing').where('sport','==','football').where('id','==',String(f?.teams?.home?.id||'')).limit(100).get();
    const awayFollowing=await db.collectionGroup('sportsFollowing').where('sport','==','football').where('id','==',String(f?.teams?.away?.id||'')).limit(100).get();
    const users=new Set([...following.docs.map(d=>d.ref.parent.parent?.id),...awayFollowing.docs.map(d=>d.ref.parent.parent?.id)].filter(Boolean));
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
    batch.set(ref,{homeScore:score.home,awayScore:score.away,eventKeys:[...new Set([...seen,...fresh.map(e=>e.key)])].slice(-100),updatedAt:FieldValue.serverTimestamp()},{merge:true});
  }
  await batch.commit();
  return {fixtures:live.length};
});
