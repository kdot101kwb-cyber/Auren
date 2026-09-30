const {onCall,HttpsError}=require('firebase-functions/v2/https');
const clean=(v,max=500)=>String(v??'').replace(/\s+/g,' ').trim().slice(0,max);
exports.getAurenLibraryGraph=onCall({region:'us-central1'},async(req)=>{
 if(!req.auth)throw new HttpsError('unauthenticated','Sign in required.');
 const d=req.data||{}, id=clean(d.id,200), title=clean(d.title,240), kind=clean(d.kind,100);
 const nodes=[]; const edges=[]; const add=(type,label,key)=>{if(!label)return;const nodeId=type+':'+clean(key||label,180);if(!nodes.some(n=>n.id===nodeId))nodes.push({id:nodeId,type,label:clean(label,300)});return nodeId;};
 const root=add(kind||'work',title,id||title);
 for(const [type,key] of [['author',d.author],['publisher',d.publisher],['country',d.country],['language',d.language],['series',d.series],['issue',d.issue],['journal',d.journal],['doi',d.doi]]){const n=add(type,key,key);if(root&&n)edges.push({from:root,to:n,relation:'HAS_'+type.toUpperCase()});}
 return {root, nodes, edges, model:['Work','Edition','Author','Publisher','Series','Issue','Character','Country','Language','Journal','DOI','Heritage','Source'],relations:['AUTHORED_BY','PUBLISHED_BY','PART_OF','HAS_ISSUE','HAS_CHARACTER','TRANSLATED_TO','FROM_COUNTRY','ABOUT','CITES','SOURCE_OF']};
});
