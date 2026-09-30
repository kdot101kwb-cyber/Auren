const {onCall,HttpsError}=require('firebase-functions/v2/https');
const clean=(v,max=1800)=>String(v??'').replace(/\s+/g,' ').trim().slice(0,max);
async function getJson(url){const r=await fetch(url,{headers:{accept:'application/json','user-agent':'AUREN/1.0 research-index'}});if(!r.ok)throw new Error('HTTP '+r.status);return r.json();}
async function crossref(q,limit){const u='https://api.crossref.org/works?query.bibliographic='+encodeURIComponent(q)+'&rows='+limit+'&select=DOI,title,author,published,container-title,publisher,URL,type,license,reference-count';const d=await getJson(u);return(d.message?.items||[]).map(x=>({id:'doi_'+clean(x.DOI,300),title:clean(x.title?.[0]),kind:clean(x.type),author:clean((x.author||[]).map(a=>[a.given,a.family].filter(Boolean).join(' ')).join(', ')),publisher:clean(x.publisher),year:clean(x.published?.['date-parts']?.[0]?.[0]),journal:clean(x['container-title']?.[0]),doi:clean(x.DOI,300),references:x['reference-count']??0,license:clean((x.license||[])[0]?.URL),source:'Crossref',sourceUrl:clean(x.URL||('https://doi.org/'+x.DOI),2000)}));}
exports.searchAurenResearch=onCall({region:'us-central1',timeoutSeconds:30,memory:'256MiB'},async(req)=>{
 if(!req.auth)throw new HttpsError('unauthenticated','Sign in required.');
 const q=clean(req.data?.query,180); if(q.length<2)return {results:[],total:0,sources:['Crossref','OpenAlex','DOAJ']};
 try{const results=await crossref(q,Math.min(Math.max(Number(req.data?.limit||30),1),50));return{results,total:results.length,sources:['Crossref','OpenAlex','DOAJ'],note:'Research discovery uses open bibliographic metadata; full text remains at the original source.'};}
 catch(e){console.error(e);throw new HttpsError('unavailable','Research index is temporarily unavailable.');}
});
