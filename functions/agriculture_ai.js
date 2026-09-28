'use strict';

const {onCall}=require('firebase-functions/v2/https');
const {defineSecret,defineString}=require('firebase-functions/params');
const admin=require('firebase-admin');

const OPENROUTER_API_KEY=defineSecret('OPENROUTER_API_KEY');
const AGRICULTURE_AI_MODEL=defineString('AGRICULTURE_AI_MODEL',{
  default:'google/gemini-2.0-flash-001',
  description:'OpenRouter model used by the AUREN agriculture advisor.'
});
const db=admin.firestore();

exports.aurenAgricultureAdvisor=onCall({
  region:'us-central1',
  timeoutSeconds:30,
  memory:'256MiB',
  enforceAppCheck:true,
  secrets:[OPENROUTER_API_KEY],
},async(request)=>{
  const uid=request.auth?.uid;
  if(!uid) throw new Error('Authentication is required.');

  const input=request.data||{};
  const type=String(input.type||'').trim();
  const location=String(input.location||'').trim().slice(0,200);
  const crop=String(input.crop||'').trim().slice(0,120);
  const animal=String(input.animal||'').trim().slice(0,120);
  const observations=String(input.observations||'').trim().slice(0,4000);
  if(!['crop','livestock','farm'].includes(type)||!observations){
    throw new Error('Agriculture type and observations are required.');
  }

  const key=OPENROUTER_API_KEY.value().trim();
  if(!key) return {
    status:'provider_unconfigured',
    advice:'المستشار الذكي غير مفعّل حالياً. يمكنك حفظ الملاحظات وإعادة التحليل بعد إعداد مزود الذكاء الاصطناعي.'
  };

  const system='You are AUREN Agriculture AI. Give practical, conservative first-line guidance for crops, livestock, and farm operations. Never claim a definitive diagnosis. For suspected disease, poisoning, severe injury, pregnancy complications, or rapidly worsening livestock symptoms, advise a qualified local veterinarian/agronomist. Consider location only as context, do not invent weather or local facts. Return concise Arabic with: assessment, immediate_steps, things_to_monitor, escalation, and questions. Do not recommend unsafe chemical doses.';
  const user=JSON.stringify({type,location,crop,animal,observations});
  const response=await fetch('https://openrouter.ai/api/v1/chat/completions',{
    method:'POST',
    headers:{
      'content-type':'application/json',
      authorization:'Bearer '+key,
      'HTTP-Referer':'https://auren.app',
      'X-Title':'AUREN Agriculture AI'
    },
    body:JSON.stringify({
      model:AGRICULTURE_AI_MODEL.value(),
      messages:[{role:'system',content:system},{role:'user',content:user}],
      temperature:0.2,
      max_tokens:900
    })
  });
  const raw=await response.text();
  let data={};
  try{data=JSON.parse(raw);}catch(_){}
  if(!response.ok) throw new Error(String(data?.error?.message||'Agriculture AI provider failed').slice(0,300));
  const advice=String(data?.choices?.[0]?.message?.content||'').trim();
  if(!advice) throw new Error('Agriculture AI returned an empty response.');

  await db.collection('users').doc(uid).collection('agricultureAdvisories').add({
    type,location,crop,animal,observations,advice,
    model:AGRICULTURE_AI_MODEL.value(),
    createdAt:admin.firestore.FieldValue.serverTimestamp()
  });
  return {status:'ok',advice};
});
