const {onCall,HttpsError}=require('firebase-functions/v2/https');
const clean=(v,max=500)=>String(v??'').replace(/\s+/g,' ').trim().slice(0,max);
async function call(name,data){return require('firebase-functions/v2/https').onCall;}
exports.searchAurenUnifiedLibrary=onCall({region:'us-central1',timeoutSeconds:45,memory:'256MiB'},async(req)=>{
 if(!req.auth)throw new HttpsError('unauthenticated','Sign in required.');
 const q=clean(req.data?.query,180); if(q.length<2) return {results:[],total:0,sources:[]};
 const tasks=[];
 const names=['searchAurenGlobalLibrary','searchAurenUNESCOHeritage','searchAurenMagazines','searchAurenComics','searchAurenResearch'];
 for(const n of names){try{const fn=module.parent?.exports?.[n]||exports[n]; if(typeof fn==='function') tasks.push(fn({auth:req.auth,data:{query:q,limit:20}}));}catch(_){}}
 const settled=await Promise.allSettled(tasks);
 const results=[];
 for(const s of settled) if(s.status==='fulfilled'){const d=s.value?.data||s.value; if(d?.results)results.push(...d.results);}
 const seen=new Set(),deduped=results.filter(x=>{const k=(clean(x.title,300)+'|'+clean(x.source,100)).toLowerCase();if(seen.has(k))return false;seen.add(k);return true;}).slice(0,100);
 return {results:deduped,total:deduped.length,sources:[...new Set(deduped.map(x=>x.source).filter(Boolean))],query:q};
});
