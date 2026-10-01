const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const db = admin.firestore();

async function getJson(url) {
  const response = await fetch(url, {headers: {'user-agent': 'AUREN/1.0 entertainment-library'}});
  if (!response.ok) throw new Error('HTTP ' + response.status + ' from ' + url);
  return response.json();
}

function clean(value, max = 3000) {
  return String(value || '').replace(/\s+/g, ' ').trim().slice(0, max);
}

function bookDoc(book) {
  const id = 'book_gutenberg_' + String(book.id);
  const formats = book.formats || {};
  const html = formats['text/html; charset=utf-8'] || formats['text/html'] || '';
  const cover = formats['image/jpeg'] || '';
  const author = Array.isArray(book.authors) && book.authors[0] ? book.authors[0].name : '';
  const subjects = Array.isArray(book.subjects) ? book.subjects.slice(0, 6).map(clean) : [];
  return {id,title:clean(book.title,160),type:'Book',description:clean(author ? 'By ' + author + '. ' + subjects.join(' • ') : subjects.join(' • '),3000),imageUrl:clean(cover,2000),mediaUrl:clean(html || ('https://www.gutenberg.org/ebooks/' + book.id),2000),mediaKind:'book',creatorId:'auren-library',channelId:'auren-library',country:'',language:Array.isArray(book.languages)&&book.languages[0]?book.languages[0]:'en',year:'',genres:subjects,seasons:0,episodes:0,trailerUrl:'',artistName:'',albumName:'',visibility:'public',source:'Project Gutenberg / Gutendex',sourceUrl:'https://www.gutenberg.org/ebooks/'+book.id,licenseNote:'Catalog metadata for a public-domain/openly distributed ebook; verify local copyright status before redistribution.',createdAt:admin.firestore.FieldValue.serverTimestamp(),updatedAt:admin.firestore.FieldValue.serverTimestamp()};
}

function mangaDoc(manga) {
  const id='manga_mal_'+String(manga.mal_id);
  const genres=Array.isArray(manga.genres)?manga.genres.slice(0,8).map((g)=>clean(g?.name,80)):[];
  const image=manga.images?.jpg?.large_image_url||manga.images?.jpg?.image_url||'';
  return {id,title:clean(manga.title,160),type:'Manga',description:clean(manga.synopsis||'Manga catalog entry.',3000),imageUrl:clean(image,2000),mediaUrl:'https://myanimelist.net/manga/'+manga.mal_id,mediaKind:'catalog',creatorId:'auren-library',channelId:'auren-library',country:'Japan',language:'ja',year:manga.published?.from?String(new Date(manga.published.from).getFullYear()):'',genres,seasons:0,episodes:0,trailerUrl:'',artistName:'',albumName:'',visibility:'public',source:'Jikan / MyAnimeList',sourceUrl:'https://myanimelist.net/manga/'+manga.mal_id,licenseNote:'Metadata/catalog entry only; AUREN does not host copyrighted manga scans.',createdAt:admin.firestore.FieldValue.serverTimestamp(),updatedAt:admin.firestore.FieldValue.serverTimestamp()};
}

function animeDoc(anime) {
  const id='anime_mal_'+String(anime.mal_id);
  const genres=Array.isArray(anime.genres)?anime.genres.slice(0,8).map((g)=>clean(g?.name,80)):[];
  const image=anime.images?.jpg?.large_image_url||anime.images?.jpg?.image_url||'';
  const title=anime.title||anime.title_english||anime.title_japanese||'Anime';
  return {id,title:clean(title,160),type:'Anime',description:clean(anime.synopsis||'Anime catalog entry.',3000),imageUrl:clean(image,2000),mediaUrl:'https://myanimelist.net/anime/'+anime.mal_id,mediaKind:'catalog',creatorId:'auren-library',channelId:'auren-library',country:'Japan',language:'ja',year:anime.year?String(anime.year):'',genres,seasons:0,episodes:Number(anime.episodes||0),trailerUrl:anime.trailer?.url||'',artistName:'',albumName:'',visibility:'public',source:'Jikan / MyAnimeList',sourceUrl:'https://myanimelist.net/anime/'+anime.mal_id,licenseNote:'Metadata/catalog entry only; AUREN does not host copyrighted episodes.',createdAt:admin.firestore.FieldValue.serverTimestamp(),updatedAt:admin.firestore.FieldValue.serverTimestamp()};
}

function journalDoc(journal, source) {
  const issn=journal.ISSN||journal.issn||'';
  const id=source+'_journal_'+String(issn||journal.id||journal.display_name||journal.title||'unknown').replace(/[^a-zA-Z0-9]+/g,'_').slice(0,100);
  const title=journal.title||journal.display_name||journal.name||'Journal';
  const host=journal.publisher||journal.host_organization_name||'';
  return {id,title:clean(title,160),type:'Journal',description:clean(host?'Journal / periodical. Publisher: '+host:'Journal / periodical catalog entry.',3000),imageUrl:'',mediaUrl:clean(journal.url||journal.homepage_url||('https://api.crossref.org/journals/'+issn),2000),mediaKind:'catalog',creatorId:'auren-library',channelId:'auren-library',country:clean(journal.country||journal.country_code||'',80),language:'',year:'',genres:['Journal','Periodical'],seasons:0,episodes:0,trailerUrl:'',artistName:'',albumName:'',visibility:'public',source,sourceUrl:clean(journal.url||journal.homepage_url||'',2000),issn:clean(issn,80),licenseNote:'Metadata/catalog entry only; AUREN does not host copyrighted journal or magazine issues.',createdAt:admin.firestore.FieldValue.serverTimestamp(),updatedAt:admin.firestore.FieldValue.serverTimestamp()};
}


function seriesDoc(show) {
  const id = 'series_tvmaze_' + String(show.id);
  const image = show.image?.original || show.image?.medium || '';
  const genres = Array.isArray(show.genres) ? show.genres.slice(0, 8).map((g) => clean(g, 80)) : [];
  const premiered = show.premiered ? String(show.premiered).slice(0, 4) : '';
  const country = show.network?.country?.name || show.webChannel?.country?.name || '';
  const language = show.language || '';
  return {
    id,
    title: clean(show.name, 160),
    type: 'Global Series',
    description: clean(show.summary || 'Series catalog entry.', 3000),
    imageUrl: clean(image, 2000),
    mediaUrl: clean(show.url || ('https://www.tvmaze.com/shows/' + show.id), 2000),
    mediaKind: 'catalog',
    creatorId: 'auren-global-series',
    channelId: 'auren-global-series',
    country: clean(country, 100),
    language: clean(language, 40),
    year: premiered,
    genres,
    seasons: Number(show._embedded?.episodes ? 1 : 0),
    episodes: Number(show._embedded?.episodes?.length || 0),
    trailerUrl: '',
    artistName: '',
    albumName: '',
    visibility: 'public',
    source: 'TVmaze',
    sourceUrl: clean(show.url || '', 2000),
    licenseNote: 'Catalog metadata only; AUREN does not host copyrighted series episodes.',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

exports.seedAurenGlobalSeriesLibrary = onCall(
  {region: 'us-central1', timeoutSeconds: 120, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Authentication is required.');

    const marker = db.collection('entertainment_library_meta').doc('global_series_v1');
    const existing = await marker.get();
    if (existing.exists && existing.data()?.status === 'ready') {
      return {status: 'ready', seeded: false, message: 'AUREN Global Series Library is already populated.'};
    }

    const response = await getJson('https://api.tvmaze.com/shows?page=0');
    const shows = Array.isArray(response) ? response.slice(0, 100) : [];
    const docs = shows.map(seriesDoc);

    for (let i = 0; i < docs.length; i += 400) {
      const batch = db.batch();
      docs.slice(i, i + 400).forEach((item) => {
        const {id, ...data} = item;
        batch.set(db.collection('entertainment_items').doc(id), data, {merge: true});
      });
      await batch.commit();
    }

    await marker.set({
      status: 'ready',
      count: docs.length,
      seededBy: request.auth.uid,
      seededAt: admin.firestore.FieldValue.serverTimestamp(),
      source: 'TVmaze',
    }, {merge: true});

    return {status: 'ready', seeded: true, count: docs.length, source: 'TVmaze'};
  },
);

exports.seedAurenEntertainmentLibrary = onCall({region:'us-central1',timeoutSeconds:120,memory:'256MiB',enforceAppCheck:true},async(request)=>{
  if(!request.auth?.uid)throw new HttpsError('unauthenticated','Authentication is required.');
  const marker=db.collection('entertainment_library_meta').doc('global_v2');
  const existing=await marker.get();
  if(existing.exists&&existing.data()?.status==='ready')return {status:'ready',seeded:false,message:'AUREN Entertainment Library is already populated.'};
  const [books,anime,manga,crossref,openalex]=await Promise.all([
    getJson('https://gutendex.com/books?languages=en&copyright=false&sort=popular&page=1'),
    getJson('https://api.jikan.moe/v4/top/anime?limit=25'),
    getJson('https://api.jikan.moe/v4/top/manga?limit=25'),
    getJson('https://api.crossref.org/journals?rows=100'),
    getJson('https://api.openalex.org/sources?filter=type:journal&sort=-works_count&per-page=100'),
  ]);
  const docs=[...(books.results||[]).slice(0,40).map(bookDoc),...(anime.data||[]).slice(0,25).map(animeDoc),...(manga.data||[]).slice(0,25).map(mangaDoc),...((crossref.message&&crossref.message.items)||[]).slice(0,100).map((x)=>journalDoc(x,'Crossref')),...((openalex.results)||[]).slice(0,100).map((x)=>journalDoc(x,'OpenAlex'))];
  for(let i=0;i<docs.length;i+=400){const batch=db.batch();docs.slice(i,i+400).forEach((item)=>{const {id,...data}=item;batch.set(db.collection('entertainment_items').doc(id),data,{merge:true});});await batch.commit();}
  await marker.set({status:'ready',books:Math.min((books.results||[]).length,40),anime:Math.min((anime.data||[]).length,25),total:docs.length,seededBy:request.auth.uid,seededAt:admin.firestore.FieldValue.serverTimestamp(),sources:['Gutendex / Project Gutenberg','Jikan / MyAnimeList','Crossref','OpenAlex']},{merge:true});
  return {status:'ready',seeded:true,books:Math.min((books.results||[]).length,40),anime:Math.min((anime.data||[]).length,25),manga:Math.min((manga.data||[]).length,25),journals:Math.min(((crossref.message&&crossref.message.items)||[]).length,100)+Math.min((openalex.results||[]).length,100),total:docs.length};
});

const GLOBAL_LIBRARY_SOURCES={openLibrary:'Open Library',crossref:'Crossref',openAlex:'OpenAlex'};
function globalClean(v,max=1200){return String(v||'').replace(/\s+/g,' ').trim().slice(0,max);}
async function globalGetJson(url){const r=await fetch(url,{headers:{'user-agent':'AUREN/1.0 global-library-index'}});if(!r.ok)throw new Error('HTTP '+r.status);return r.json();}
function globalResult(x){return {id:globalClean(x.id,180),title:globalClean(x.title,240),kind:globalClean(x.kind,80),description:globalClean(x.description,1200),author:globalClean(x.author,240),publisher:globalClean(x.publisher,240),year:globalClean(x.year,40),issue:globalClean(x.issue,80),language:globalClean(x.language,40),country:globalClean(x.country,100),source:x.source,sourceUrl:globalClean(x.sourceUrl,2000),imageUrl:globalClean(x.imageUrl,2000),externalId:globalClean(x.externalId,200),rights:'Metadata/index record. AUREN does not copy or host copyrighted scans or issues without permission.'};}
function arabicHeritage(q){
  const catalog=[
    ['majid','ماجد','مجلة أطفال وكوميكس عربية','مجلة ماجد','1979'],['samir','سمير','مجلة أطفال وكوميكس مصرية','دار الهلال','1956'],['mickey','ميكي','مجلة ديزني المصورة بالعربية','دار الهلال / ناشرون لاحقاً','1959'],['pocket_mickey','ميكي جيب','سلسلة إصدارات جيب مرتبطة بميكي','دار الهلال','1975'],['basim','باسم','مجلة أطفال وكوميكس عربية','ناشرون عرب',''],['sindbad','السندباد','مجلة أدب ومغامرات للأطفال','دار الهلال',''],['aladdin','علاء الدين','مجلة أطفال عربية','ناشرون عرب',''],['rajul_al_mustahil','رجل المستحيل','سلسلة روايات تجسس ومغامرات عربية','نبيل فاروق / المؤسسة العربية الحديثة',''],['malaf_al_mustaqbal','ملف المستقبل','سلسلة خيال علمي عربية','نبيل فاروق / المؤسسة العربية الحديثة',''],['ma_waraa_al_tabia','ما وراء الطبيعة','سلسلة رعب وفانتازيا عربية','أحمد خالد توفيق',''],['fantazia','فانتازيا','سلسلة روايات فانتازيا عربية','أحمد خالد توفيق',''],['safari','سفاري','سلسلة روايات طبية ومغامرات','أحمد خالد توفيق','']
  ];
  const needle=q.toLowerCase();
  return catalog.filter(x=>x.some(v=>String(v).toLowerCase().includes(needle))).map(x=>globalResult({id:'curated_'+x[0],title:x[1],kind:x[1].includes('روايات')||x[1].includes('المستحيل')||x[1].includes('المستقبل')||x[1].includes('الطبيعة')||x[1].includes('فانتازيا')||x[1].includes('سفاري')?'Arabic Series':'Arabic Magazine',description:x[2],publisher:x[3],year:x[4],language:'ar',country:'العالم العربي',source:'AUREN Arabic Heritage Index',sourceUrl:'https://www.comics.org/search/?q='+encodeURIComponent(x[1]),externalId:x[0]}));
}
function olResults(d){return (d.docs||[]).slice(0,20).map(x=>globalResult({id:'ol_'+(x.key||x.title),title:x.title,kind:x.type==='work'?'Book':'Edition',description:Array.isArray(x.first_sentence)?x.first_sentence[0]:'',author:Array.isArray(x.author_name)?x.author_name.slice(0,3).join(', '):'',publisher:Array.isArray(x.publisher)?x.publisher.slice(0,3).join(', '):'',year:x.first_publish_year||'',language:Array.isArray(x.language)?x.language.slice(0,3).join(', '):'',source:GLOBAL_LIBRARY_SOURCES.openLibrary,sourceUrl:'https://openlibrary.org'+(x.key||''),imageUrl:x.cover_i?'https://covers.openlibrary.org/b/id/'+x.cover_i+'-M.jpg':'',externalId:x.key||''}));}
function crResults(d){return (d.message?.items||[]).slice(0,20).map(x=>globalResult({id:'cr_'+(x.DOI||x.title?.[0]||''),title:x.title?.[0]||'',kind:x.type==='journal-article'?'Journal Article':'Publication',description:x.subtitle?.join(' ')||'',author:(x.author||[]).slice(0,3).map(a=>[a.given,a.family].filter(Boolean).join(' ')).join(', '),publisher:x.publisher||'',year:x.published?.['date-parts']?.[0]?.[0]||'',source:GLOBAL_LIBRARY_SOURCES.crossref,sourceUrl:x.URL||('https://doi.org/'+(x.DOI||'')),externalId:x.DOI||''}));}
function oaResults(d){return (d.results||[]).slice(0,20).map(x=>globalResult({id:'oa_'+(x.id||x.doi||x.title),title:x.title,kind:x.type||'Work',author:(x.authorships||[]).slice(0,3).map(a=>a.author?.display_name).filter(Boolean).join(', '),publisher:x.primary_location?.source?.host_organization_name||'',year:x.publication_year||'',source:GLOBAL_LIBRARY_SOURCES.openAlex,sourceUrl:x.primary_location?.landing_page_url||x.doi||x.id||'',externalId:x.id||x.doi||''}));}

exports.searchAurenGlobalLibrary=onCall({region:'us-central1',timeoutSeconds:30,memory:'256MiB',enforceAppCheck:true},async(request)=>{
  if(!request.auth?.uid)throw new HttpsError('unauthenticated','Authentication is required.');
  const query=globalClean(request.data?.query,160);
  const page=Math.max(1,Math.min(Number(request.data?.page)||1,10));
  if(query.length<2)throw new HttpsError('invalid-argument','Search query must contain at least 2 characters.');
  const e=encodeURIComponent(query);
  const tasks=await Promise.allSettled([globalGetJson('https://openlibrary.org/search.json?q='+e+'&page='+page+'&limit=20'),globalGetJson('https://api.crossref.org/works?query='+e+'&rows=20'),globalGetJson('https://api.openalex.org/works?search='+e+'&per-page=20&page='+page)]);
  const out=[...arabicHeritage(query),...(tasks[0].status==='fulfilled'?olResults(tasks[0].value):[]),...(tasks[1].status==='fulfilled'?crResults(tasks[1].value):[]),...(tasks[2].status==='fulfilled'?oaResults(tasks[2].value):[])];
  const seen=new Set();
  const results=out.filter(x=>{const k=(x.title+'|'+x.source).toLowerCase();if(seen.has(k))return false;seen.add(k);return true;}).slice(0,60);
  return {status:'ok',query,page,results,sources:[GLOBAL_LIBRARY_SOURCES.openLibrary,GLOBAL_LIBRARY_SOURCES.crossref,GLOBAL_LIBRARY_SOURCES.openAlex,'AUREN Arabic Heritage Index'],note:'Global federated metadata search. Full scans/issues are not copied or hosted by this index.'};
});
