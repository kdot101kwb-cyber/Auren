'use strict';

const test=require('node:test');
const assert=require('node:assert/strict');

process.env.FIRESTORE_EMULATOR_HOST=process.env.FIRESTORE_EMULATOR_HOST||'127.0.0.1:8080';
process.env.GCLOUD_PROJECT=process.env.GCLOUD_PROJECT||'auren-emulator';

const admin=require('firebase-admin');
if(!admin.apps.length) admin.initializeApp({projectId:process.env.GCLOUD_PROJECT});
const db=admin.firestore();
const {runAurenSportsAlerts}=require('./functions/sports_alerts');

function fixture(){
  return {
    fixture:{id:123456,status:{short:'1H',elapsed:12}},
    teams:{home:{id:10,name:'AUREN FC'},away:{id:20,name:'Global FC'}},
    goals:{home:1,away:0},
    events:[{time:{elapsed:12},player:{id:7,name:'Player A'},type:'Goal',detail:'Normal Goal'}],
  };
}

test('Sports Alerts integration writes alert, sends FCM payload, and dedupes',async()=>{
  const uid='integration-user';
  await db.collection('users').doc(uid).collection('sportsFollowing').doc('10').set({sport:'football',id:'10'});
  await db.collection('users').doc(uid).collection('sportsSettings').doc('alerts').set({
    enabled:true,types:['goal','kickoff','red_card','full_time'],
  });

  await db.collection('users').doc(uid).collection('fcmTokens').doc('token-1').set({
    token:'fake-token',enabled:true,
  });

  const sent=[];
  const messaging={sendEachForMulticast:async(message)=>{
    sent.push(message);
    return {successCount:message.tokens.length,failureCount:0,responses:message.tokens.map(()=>({success:true}))};
  }};

  const options={
    db,
    fetchLiveFn:async()=>[fixture()],
    fetchTodayFn:async()=>[],
    getMessagingFn:()=>messaging,
    skipRunGuard:true,
  };

  const first=await runAurenSportsAlerts(options);
  assert.equal(first.fixtures,1);
  assert.equal(first.pushSent,1);
  assert.equal(sent[0].data.fixtureId,'123456');
  assert.equal(sent[0].data.type,'goal');

  const alerts=await db.collection('users').doc(uid).collection('sportsAlerts').get();
  assert.equal(alerts.size,1);

  const state=await db.collection('sports_live_state').doc('123456').get();
  assert.equal(state.data().homeScore,1);

  const second=await runAurenSportsAlerts(options);
  assert.equal(second.pushSent,0);
  const alertsAfter=await db.collection('users').doc(uid).collection('sportsAlerts').get();
  assert.equal(alertsAfter.size,1);
});
