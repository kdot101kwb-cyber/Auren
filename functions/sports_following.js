'use strict';

const {onCall,HttpsError}=require('firebase-functions/v2/https');
const {getFirestore,FieldValue}=require('firebase-admin/firestore');

const db=getFirestore();

function clean(value,max=180){
  return String(value??'').trim().slice(0,max);
}

function normalize(item){
  return {
    id:clean(item.id||item.teamId||item.fixtureId,160),
    sport:clean(item.sport||'football',40).toLowerCase(),
    name:clean(item.name||item.title||'Team',180),
    country:clean(item.country,100),
    logo:clean(item.logo,500),
    league:clean(item.league,160),
    source:clean(item.source||'API-Sports',80),
    updatedAt:FieldValue.serverTimestamp(),
  };
}

exports.getAurenSportsFollowing=onCall(
 {region:'us-central1',timeoutSeconds:15,memory:'256MiB'},
 async(request)=>{
  const uid=request.auth?.uid;
  if(!uid) throw new HttpsError('unauthenticated','Authentication is required.');
  const snap=await db.collection('users').doc(uid).collection('sportsFollowing').orderBy('name').limit(100).get();
  return {status:'ok',results:snap.docs.map(d=>({id:d.id,...d.data()}))};
 });

exports.followAurenSportsTeam=onCall(
 {region:'us-central1',timeoutSeconds:15,memory:'256MiB'},
 async(request)=>{
  const uid=request.auth?.uid;
  if(!uid) throw new HttpsError('unauthenticated','Authentication is required.');
  const team=normalize(request.data||{});
  if(!team.id||!team.name) throw new HttpsError('invalid-argument','Team id and name are required.');
  const ref=db.collection('users').doc(uid).collection('sportsFollowing').doc(team.id);
  await ref.set(team,{merge:true});
  return {status:'followed',team:{id:team.id,...team}};
 });

exports.unfollowAurenSportsTeam=onCall(
 {region:'us-central1',timeoutSeconds:15,memory:'256MiB'},
 async(request)=>{
  const uid=request.auth?.uid;
  if(!uid) throw new HttpsError('unauthenticated','Authentication is required.');
  const id=clean(request.data?.id,160);
  if(!id) throw new HttpsError('invalid-argument','Team id is required.');
  await db.collection('users').doc(uid).collection('sportsFollowing').doc(id).delete();
  return {status:'unfollowed',id};
 });
