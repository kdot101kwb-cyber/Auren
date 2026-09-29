'use strict';

const {onCall}=require('firebase-functions/v2/https');
const {defineSecret,defineString}=require('firebase-functions/params');
const admin=require('firebase-admin');

const OPENROUTER_API_KEY=defineSecret('OPENROUTER_API_KEY');
const AGRICULTURE_AI_MODEL=defineString('AGRICULTURE_AI_MODEL',{
  default:'google/gemini-2.0-flash-001',
  description:'OpenRouter model used by the AUREN AgriTech, Industry and Innovation advisor.'
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
  const material=String(input.material||'').trim().slice(0,200);
  const invention=String(input.invention||'').trim().slice(0,500);
  const observations=String(input.observations||'').trim().slice(0,4000);
  if(!['crop','livestock','farm','manufacturing','invention','research','energy','recycling','design','business','production','costing','supply_chain','quality'].includes(type)||!observations){
    throw new Error('AUREN domain and observations are required.');
  }

  const key=OPENROUTER_API_KEY.value().trim();
  if(!key) return {
    status:'provider_unconfigured',
    advice:'المستشار الذكي غير مفعّل حالياً. يمكنك حفظ الملاحظات وإعادة التحليل بعد إعداد مزود الذكاء الاصطناعي.'
  };

  const system='You are AUREN AgriTech, Industry, Innovation & Design AI. Support agriculture, livestock, farms, manufacturing, inventions, research, energy, recycling, design and business creation with practical, conservative guidance. For health or animal disease never claim a definitive diagnosis and refer to a qualified professional when needed. For manufacturing, inventions and design, distinguish concepts from validated engineering results; include requirements, materials, dimensions, prototype, testing, safety and regulatory considerations where relevant. Design domains include apparel, footwear, architecture/buildings, interiors, furniture, product/industrial design, packaging, brand/graphic identity, UI/UX, landscape/urban spaces and design-to-make workflows. For business, production, costing, supply chain and quality requests, structure feasibility studies with market, product, capacity, site, equipment, workforce, raw materials, production flow, quality control, HSE, startup investment, operating costs, unit economics, break-even, cash flow, risks, suppliers, distribution and launch plan. Clearly label assumptions and estimates; do not invent current prices or regulations. For architecture and buildings, do not present concept guidance as certified structural, fire, electrical or permit-ready plans; recommend qualified professionals and local code review. Never invent local weather, market, laws, certifications or technical measurements. Do not provide unsafe chemical, electrical, mechanical or biological instructions. Return concise Arabic with: assessment, immediate_steps, things_to_monitor, risks_and_safety, next_steps, and questions.';
  const user=JSON.stringify({type,location,crop,animal,material,invention,observations});
  const response=await fetch('https://openrouter.ai/api/v1/chat/completions',{
    method:'POST',
    headers:{
      'content-type':'application/json',
      authorization:'Bearer '+key,
      'HTTP-Referer':'https://auren.app',
      'X-Title':'AUREN AgriTech, Industry, Innovation & Design AI'
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
    type,location,crop,animal,material,invention,observations,advice,
    model:AGRICULTURE_AI_MODEL.value(),
    createdAt:admin.firestore.FieldValue.serverTimestamp()
  });
  return {status:'ok',advice};
});
