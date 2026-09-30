const {onCall,HttpsError}=require('firebase-functions/v2/https');
const clean=(v,max=500)=>String(v??'').replace(/\s+/g,' ').trim().slice(0,max);
const modules=[
 require('./global_library_index'),
 require('./unesco_heritage_search'),
 require('./auren_magazine_index'),
 require('./auren_comics_index'),
 require('./auren_research_index'),
];
exports.searchAurenUnifiedLibrary=onCall({region:'us-central1',timeoutSeconds:60,memory:'256MiB'},async(req)=>{
 if(!req.auth)throw new HttpsError('unauthenticated','Sign in required.');
 const q=clean(req.data?.query,180); if(q.length<2)return{results:[],total:0,sources:[]};
 const calls=[
  ['searchAurenGlobalLibrary',modules[0]],
  ['searchAurenUNESCOHeritage',modules[1]],
  ['searchAurenMagazines',modules[2]],
  ['searchAurenComics',modules[3]],
  ['searchAurenResearch',modules[4]]
 ];
 const settled=await Promise.allSettled(calls.map(([name,m])=>m[name]({auth:req.auth,data:{query:q,limit:20}})));
 const results=[];
 for(const s of settled)if(s.status==='fulfilled'){const d=s.value?.data||{};if(Array.isArray(d.results))results.push(...d.results);}
 const seen=new Set(),deduped=results.filter(x=>{const k=(clean(x.title,300)+'|'+clean(x.source,100)).toLowerCase();if(seen.has(k))return false;seen.add(k);return true;}).slice(0,100);
 return{results:deduped,total:deduped.length,sources:[...new Set(deduped.map(x=>x.source).filter(Boolean))],query:q};
});