const {onCall, HttpsError} = require('firebase-functions/v2/https');

const API = 'https://data.unesco.org/api/explore/v2.1/catalog/datasets/whc001/records';
const clean = (v, max=3000) => String(v ?? '').replace(/\s+/g, ' ').trim().slice(0,max);
const arr = (v) => Array.isArray(v) ? v.map(x=>clean(x)).filter(Boolean) : typeof v==='string' ? v.split(/[;,|]/).map(x=>clean(x)).filter(Boolean) : [];

function mapSite(record) {
  const r = record?.record?.fields || record?.fields || record || {};
  const title = clean(r.name_en || r.name_ar || r.name_fr);
  if (!title) return null;
  return {
    id: 'world_' + clean(r.id_no || r.uuid, 120),
    title, titleAr: clean(r.name_ar, 500),
    description: clean(r.short_description_en || r.description_en || r.short_description_ar),
    year: clean(r.date_inscribed, 20),
    category: clean(r.category, 80),
    danger: Boolean(r.danger),
    countries: arr(r.states_names),
    region: clean(r.region, 120),
    coordinates: clean(r.coordinates, 120),
    criteria: clean(r.criteria_txt || r.cultural_criteria || r.natural_criteria, 400),
    transboundary: Boolean(r.transboundary),
    areaHectares: r.area_hectares ?? null,
    imageUrl: clean(r.main_image_url, 1000),
    source: 'UNESCO World Heritage Centre / DataHub',
    sourceUrl: 'https://whc.unesco.org/en/list/' + clean(r.id_no, 30),
    license: 'CC BY-SA 4.0',
    externalId: clean(r.id_no || r.uuid, 120),
  };
}
async function getJson(url){ const r=await fetch(url,{headers:{accept:'application/json','user-agent':'AUREN/1.0'}}); if(!r.ok) throw new Error('UNESCO API '+r.status); return r.json(); }
async function search({query='',country='',region='',year='',category='',limit=60}){
  const where=[];
  if(query) where.push('search(name_en, '+JSON.stringify(clean(query,200))+')');
  if(country) where.push('states_names like '+JSON.stringify('%'+clean(country,100)+'%'));
  if(region) where.push('region = '+JSON.stringify(clean(region,100)));
  if(year && /^\\d{4}$/.test(String(year))) where.push('date_inscribed = '+String(year));
  if(category) where.push('category = '+JSON.stringify(clean(category,100)));
  const p=new URLSearchParams({limit:String(Math.min(Math.max(Number(limit)||60,1),100)),offset:'0'});
  if(where.length) p.set('where',where.join(' AND '));
  const data=await getJson(API+'?'+p.toString());
  return (data.results||[]).map(mapSite).filter(Boolean);
}
exports.getAurenWorldHeritageExplorer = onCall({region:'us-central1',timeoutSeconds:30,memory:'256MiB'},async(request)=>{
  if(!request.auth) throw new HttpsError('unauthenticated','Sign in required.');
  const d=request.data||{};
  try{
    const results=await search({query:d.query||'',country:d.country||'',region:d.region||'',year:d.year||'',category:d.category||'',limit:d.limit||60});
    const all=await search({limit:100});
    const countries=[...new Set(all.flatMap(x=>x.countries))].sort();
    const regions=[...new Set(all.map(x=>x.region).filter(Boolean))].sort();
    const categories=[...new Set(all.map(x=>x.category).filter(Boolean))].sort();
    const years=[...new Set(all.map(x=>x.year).filter(Boolean))].sort((a,b)=>b.localeCompare(a));
    return {results,total:results.length,countries,regions,categories,years,stats:{indexed:all.length,danger:all.filter(x=>x.danger).length,transboundary:all.filter(x=>x.transboundary).length},source:'UNESCO World Heritage List / DataHub',dataset:'whc001',license:'CC BY-SA 4.0',attribution:'UNESCO',updatedAt:new Date().toISOString()};
  }catch(error){ console.error('getAurenWorldHeritageExplorer failed',error); throw new HttpsError('unavailable','UNESCO World Heritage Explorer is temporarily unavailable.'); }
});
