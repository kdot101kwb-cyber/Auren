'use strict';
const {onCall,HttpsError}=require('firebase-functions/v2/https');

exports.searchAurenEvents=onCall({region:'us-central1',timeoutSeconds:20,memory:'256MiB'},async(request)=>{
  if(!request.auth?.uid) throw new HttpsError('unauthenticated','Authentication is required.');
  const key=String(process.env.TICKETMASTER_API_KEY||'').trim();
  if(!key) return {status:'not_configured',source:'Ticketmaster Discovery API',sourceUrl:'https://developer.ticketmaster.com/products-and-docs/apis/discovery-api/v2/',results:[]};
  const query=String(request.data?.query||'').trim().slice(0,120);
  const country=String(request.data?.countryCode||'').trim().toUpperCase().slice(0,2);
  const url=new URL('https://app.ticketmaster.com/discovery/v2/events.json');
  url.searchParams.set('apikey',key); url.searchParams.set('size','25');
  if(query) url.searchParams.set('keyword',query);
  if(country) url.searchParams.set('countryCode',country);
  const response=await fetch(url,{headers:{'user-agent':'AUREN-Events/1.0'}});
  if(!response.ok) throw new HttpsError('unavailable','Events provider is unavailable.');
  const data=await response.json();
  const events=Array.isArray(data?._embedded?.events)?data._embedded.events:[];
  return {status:'ok',source:'Ticketmaster Discovery API',sourceUrl:'https://developer.ticketmaster.com/products-and-docs/apis/discovery-api/v2/',results:events.map(e=>({
    id:String(e.id||''),title:String(e.name||''),date:e.dates?.start?.dateTime||e.dates?.start?.localDate||null,
    venue:e._embedded?.venues?.[0]?.name||'',city:e._embedded?.venues?.[0]?.city?.name||'',
    country:e._embedded?.venues?.[0]?.country?.name||'',image:e.images?.[0]?.url||'',
    url:e.url||'',status:e.dates?.status?.code||'',source:'Ticketmaster'
  })).filter(x=>x.title)};
});
