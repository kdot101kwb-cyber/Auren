const {onCall,HttpsError}=require('firebase-functions/v2/https');

const clean=(v,max=1200)=>String(v??'').replace(/\\s+/g,' ').trim().slice(0,max);
const curated=[
  ['مجلة ماجد','مجلة أطفال','الإمارات العربية المتحدة','أبوظبي للإعلام / مؤسسة الاتحاد للصحافة والنشر','العربية','https://www.majid.ae/'],
  ['مجلة ميكي','مجلة أطفال وكوميكس','مصر','دار الهلال','العربية','https://www.daralhilal.com.eg/'],
  ['سمير','مجلة أطفال وكوميكس','مصر','دار الهلال','العربية','https://www.daralhilal.com.eg/'],
  ['رجل المستحيل','سلسلة روايات','مصر','المؤسسة العربية الحديثة','العربية','https://www.goodreads.com/'],
  ['ملف المستقبل','سلسلة خيال علمي','مصر','المؤسسة العربية الحديثة','العربية','https://www.goodreads.com/'],
  ['ما وراء الطبيعة','سلسلة رعب وخيال','مصر','المؤسسة العربية الحديثة','العربية','https://www.goodreads.com/'],
  ['العربي الصغير','مجلة أطفال وثقافة','الكويت','مجلة العربي','العربية','https://alarabi.nccal.gov.kw/'],
];
async function getJson(url){const r=await fetch(url,{headers:{accept:'application/json','user-agent':'AUREN/1.0 magazine-index'}});if(!r.ok)throw new Error('HTTP '+r.status);return r.json();}
async function crossref(q,limit){const u='https://api.crossref.org/works?query.container-title='+encodeURIComponent(q)+'&rows='+limit;const d=await getJson(u);return (d.message?.items||[]).map(x=>({id:'crossref_'+clean(x.DOI||x.URL,200),title:clean((x['container-title']||[])[0]||x.title?.[0]),kind:'Magazine / Journal',author:clean((x.author||[]).map(a=>a.family||a.name).join(', ')),publisher:clean(x.publisher),year:clean(x.published?.['date-parts']?.[0]?.[0]),language:clean(x.language),source:'Crossref',sourceUrl:clean(x.URL||('https://doi.org/'+x.DOI),2000),externalId:clean(x.DOI,300)}));}
exports.searchAurenMagazines=onCall({region:'us-central1',timeoutSeconds:30,memory:'256MiB'},async(request)=>{
 if(!request.auth)throw new HttpsError('unauthenticated','Sign in required.');
 const q=clean(request.data?.query,180), country=clean(request.data?.country,100), limit=Math.min(Math.max(Number(request.data?.limit||40),1),60);
 try{
  const rows=q?await crossref(q,limit):[];
  const curatedRows=curated.filter(x=>!country||x[2].toLowerCase().includes(country.toLowerCase())).filter(x=>!q||x[0].toLowerCase().includes(q.toLowerCase())).map((x,i)=>({id:'curated_mag_'+i,title:x[0],kind:x[1],country:x[2],publisher:x[3],language:x[4],source:'AUREN Magazine Index',sourceUrl:x[5],externalId:'curated_'+i}));
  const seen=new Set(),results=[...curatedRows,...rows].filter(x=>{const k=(x.title+'|'+x.source).toLowerCase();if(seen.has(k))return false;seen.add(k);return true;}).slice(0,limit);
  return {results,total:results.length,curatedCount:curatedRows.length,sources:['AUREN Magazine Index','Crossref'],note:'Index metadata and source links only; copyrighted scans are not hosted.'};
 }catch(e){console.error(e);throw new HttpsError('unavailable','Magazine index is temporarily unavailable.');}
});
