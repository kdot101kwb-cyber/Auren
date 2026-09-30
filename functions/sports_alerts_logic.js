'use strict';

function fixtureId(f){
  return String(f?.fixture?.id||'').trim();
}

function eventType(e){
  const t=String(e?.type||'').toLowerCase();
  if(t==='goal') return 'goal';
  if(t==='card' && String(e?.detail||'').toLowerCase().includes('red')) return 'red_card';
  return '';
}

function detectFreshEvents({events,seen,previousStatus,status,fixtureStatusElapsed,previousExists,score,previousScore}){
  const known=Array.isArray(seen)?seen:[];
  const fresh=events.map(e=>({
    key:String(e?.time?.elapsed||'')+'|'+String(e?.player?.id||e?.player?.name||'')+'|'+String(e?.type||'')+'|'+String(e?.detail||''),
    type:eventType(e),
    minute:Number(e?.time?.elapsed||0),
    player:String(e?.player?.name||'')
  })).filter(e=>e.type && e.key && !known.includes(e.key));

  const liveStatuses=['1H','HT','2H','ET','P'];
  if(previousExists && previousStatus && !liveStatuses.includes(previousStatus) && liveStatuses.includes(status)){
    fresh.push({key:'kickoff|'+status,type:'kickoff',minute:Number(fixtureStatusElapsed||0),player:''});
  }
  if(previousExists && previousStatus!=='FT' && status==='FT'){
    fresh.push({key:'full_time|FT',type:'full_time',minute:Number(fixtureStatusElapsed||0),player:''});
  }
  if(previousExists && !fresh.some(e=>e.type==='goal') &&
     (score.home!==Number(previousScore?.home??score.home)||score.away!==Number(previousScore?.away??score.away))){
    fresh.push({key:'score|'+score.home+'|'+score.away,type:'goal',minute:0,player:''});
  }
  return fresh;
}

function buildPushMessage(job){
  return {
    tokens:job.tokens,
    notification:{title:job.title,body:job.body},
    data:{
      type:job.type,
      fixtureId:job.fixtureId,
      notificationId:job.notificationId,
    },
    android:{
      priority:'high',
      notification:{channelId:'auren_sports_alerts'},
    },
  };
}

function chunk(items,size=450){
  const groups=[];
  for(let i=0;i<items.length;i+=size) groups.push(items.slice(i,i+size));
  return groups;
}

module.exports={fixtureId,eventType,detectFreshEvents,buildPushMessage,chunk};
