const {onCall,HttpsError}=require('firebase-functions/v2/https');
const API='https://www.gcdatabase.com/search';
const clean=(v,max=1200)=>String(v??'').replace(/\s+/g,' ').trim().slice(0,max);
const curated=[
 ['ماجد','Arabic Children Comics','United Arab Emirates','مجلة ماجد','العربية'],
 ['ميكي','Disney Comics','Egypt','دار الهلال','العربية'],
 ['ميكي جيب','Pocket Comics','Egypt','دار الهلال','العربية'],
 ['سمير','Children Comics','Egypt','دار الهلال','العربية'],
 ['تان تان','European Comics','Belgium','Le Lombard','French'],
 ['Asterix','European Comics','France','Dargaud','French'],
 ['Marvel Comics','Superhero Comics','United States','Marvel','English'],
 ['DC Comics','Superhero Comics','United States','DC','English'],
];
exports.searchAurenComics=onCall({region:'us-central1',timeoutSeconds:20,memory:'256MiB'},async(req)=>{
 if(!req.auth)throw new HttpsError('unauthenticated','Sign in required.');
 const q=clean(req.data?.query,180).toLowerCase(), country=clean(req.data?.country,100).toLowerCase();
 const rows=curated.filter(x=>(!q||x[0].toLowerCase().includes(q))&&(!country||x[2].toLowerCase().includes(country))).map((x,i)=>({id:'comic_'+i,title:x[0],kind:x[1],country:x[2],publisher:x[3],language:x[4],source:'AUREN Comics Index',sourceUrl:'https://www.comics.org/',externalId:'curated_'+i}));
 return {results:rows,total:rows.length,sources:['AUREN Comics Index','Grand Comics Database'],note:'Index metadata and source links only; copyrighted scans are not hosted.'};
});
