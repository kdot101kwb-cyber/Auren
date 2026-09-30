'use strict';

const test=require('node:test');
const assert=require('node:assert/strict');
const {fixtureId,eventType,detectFreshEvents,buildPushMessage,chunk}=require('./sports_alerts_logic');

test('fixtureId extracts fixture ids',()=>{
  assert.equal(fixtureId({fixture:{id:12345}}),'12345');
  assert.equal(fixtureId({fixture:{id:null}}),'');
});

test('eventType recognizes goals and red cards',()=>{
  assert.equal(eventType({type:'Goal'}),'goal');
  assert.equal(eventType({type:'Card',detail:'Red Card'}),'red_card');
  assert.equal(eventType({type:'Card',detail:'Yellow Card'}),'');
});

test('new goals are emitted once when seen keys are supplied',()=>{
  const event={time:{elapsed:12},player:{id:7,name:'Player A'},type:'Goal',detail:'Normal Goal'};
  const first=detectFreshEvents({events:[event],seen:[],previousStatus:'1H',status:'1H',previousExists:true,score:{home:1,away:0},previousScore:{home:0,away:0}});
  assert.equal(first.length,1);
  assert.equal(first[0].type,'goal');
  const second=detectFreshEvents({events:[event],seen:[first[0].key],previousStatus:'1H',status:'1H',previousExists:true,score:{home:1,away:0},previousScore:{home:1,away:0}});
  assert.equal(second.length,0);
});

test('red cards are emitted',()=>{
  const fresh=detectFreshEvents({events:[{time:{elapsed:77},player:{id:9,name:'Player B'},type:'Card',detail:'Red Card'}],seen:[],previousStatus:'2H',status:'2H',previousExists:true,score:{home:1,away:0},previousScore:{home:1,away:0}});
  assert.equal(fresh[0].type,'red_card');
});

test('kickoff and full-time transitions are emitted',()=>{
  const kickoff=detectFreshEvents({events:[],seen:[],previousStatus:'NS',status:'1H',fixtureStatusElapsed:1,previousExists:true,score:{home:0,away:0},previousScore:{home:0,away:0}});
  assert.deepEqual(kickoff,[{key:'kickoff|1H',type:'kickoff',minute:1,player:''}]);
  const fullTime=detectFreshEvents({events:[],seen:[],previousStatus:'2H',status:'FT',fixtureStatusElapsed:90,previousExists:true,score:{home:2,away:1},previousScore:{home:2,away:1}});
  assert.deepEqual(fullTime,[{key:'full_time|FT',type:'full_time',minute:90,player:''}]);
});

test('score fallback emits a goal only when provider events have no goal',()=>{
  const fallback=detectFreshEvents({events:[],seen:[],previousStatus:'1H',status:'1H',previousExists:true,score:{home:2,away:0},previousScore:{home:1,away:0}});
  assert.equal(fallback.length,1);
  assert.equal(fallback[0].type,'goal');
  const providerGoal=detectFreshEvents({events:[{time:{elapsed:55},player:{id:3,name:'Scorer'},type:'Goal',detail:'Normal Goal'}],seen:[],previousStatus:'1H',status:'1H',previousExists:true,score:{home:2,away:0},previousScore:{home:1,away:0}});
  assert.equal(providerGoal.filter(e=>e.type==='goal').length,1);
});

test('chunk limits Firestore groups to 450 writes',()=>{
  assert.deepEqual(chunk(Array.from({length:1001},(_,i)=>i)).map(g=>g.length),[450,450,101]);
});

test('push payload keeps fixtureId for exact Match Center routing',()=>{
  const message=buildPushMessage({tokens:['token'],type:'goal',fixtureId:'987654',notificationId:'987654_goal',title:'Goal',body:'Home x Away'});
  assert.equal(message.data.fixtureId,'987654');
  assert.equal(message.data.type,'goal');
  assert.equal(message.android.notification.channelId,'auren_sports_alerts');
});
