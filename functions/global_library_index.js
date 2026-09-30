const {onCall, HttpsError} = require('firebase-functions/v2/https');

const SOURCES = {
  openLibrary: 'Open Library',
  crossref: 'Crossref',
  openAlex: 'OpenAlex',
  jaraid: 'Jaraid',
  gcd: 'Grand Comics Database',
};

function clean(value, max = 1200) {
  return String(value || '').replace(/\s+/g, ' ').trim().slice(0, max);
}

async function getJson(url) {
  const response = await fetch(url, {
    headers: {'user-agent': 'AUREN/1.0 global-library-index'},
  });
  if (!response.ok) throw new Error('HTTP ' + response.status + ' from ' + url);
  return response.json();
}

function result({id, title, kind, description, author = '', publisher = '', year = '', issue = '', language = '', country = '', source, sourceUrl, imageUrl = '', externalId = ''}) {
  return {
    id: clean(id, 180),
    title: clean(title, 240),
    kind: clean(kind, 80),
    description: clean(description, 1200),
    author: clean(author, 240),
    publisher: clean(publisher, 240),
    year: clean(year, 40),
    issue: clean(issue, 80),
    language: clean(language, 40),
    country: clean(country, 100),
    source,
    sourceUrl: clean(sourceUrl, 2000),
    imageUrl: clean(imageUrl, 2000),
    externalId: clean(externalId, 200),
    rights: 'Metadata/index record. AUREN does not copy or host copyrighted scans or issues without permission.',
  };
}

function openLibraryResults(data) {
  return (data.docs || []).slice(0, 20).map((x) => result({
    id: 'ol_' + (x.key || x.edition_key?.[0] || Math.random()),
    title: x.title,
    kind: (x.type === 'work' ? 'Book' : 'Edition'),
    description: Array.isArray(x.first_sentence) ? x.first_sentence[0] : '',
    author: Array.isArray(x.author_name) ? x.author_name.slice(0, 3).join(', ') : '',
    publisher: Array.isArray(x.publisher) ? x.publisher.slice(0, 3).join(', ') : '',
    year: x.first_publish_year || '',
    language: Array.isArray(x.language) ? x.language.slice(0, 3).join(', ') : '',
    source: SOURCES.openLibrary,
    sourceUrl: 'https://openlibrary.org' + (x.key || ''),
    imageUrl: x.cover_i ? 'https://covers.openlibrary.org/b/id/' + x.cover_i + '-M.jpg' : '',
    externalId: x.key || '',
  }));
}

function crossrefResults(data) {
  return (data.message?.items || []).slice(0, 20).map((x) => result({
    id: 'cr_' + (x.DOI || x.title?.[0] || ''),
    title: x.title?.[0] || '',
    kind: x.type === 'journal-article' ? 'Journal Article' : 'Publication',
    description: x.subtitle?.join(' ') || '',
    author: (x.author || []).slice(0, 3).map((a) => [a.given, a.family].filter(Boolean).join(' ')).join(', '),
    publisher: x.publisher || '',
    year: x.published?.['date-parts']?.[0]?.[0] || '',
    source: SOURCES.crossref,
    sourceUrl: x.URL || ('https://doi.org/' + (x.DOI || '')),
    externalId: x.DOI || '',
  }));
}


function doajResults(data) {
  return (data.results || []).slice(0, 15).map((x) => {
    const b = x.bibjson || {};
    const title = b.title || '';
    const authors = (b.author || []).slice(0, 4).map((a) => a.name).filter(Boolean).join(', ');
    const link = (b.link || []).map((l) => l.url).find(Boolean) || '';
    return result({
      id: 'doaj_' + (x.id || title),
      title,
      kind: 'Open Access Article',
      description: b.abstract || 'Open-access article indexed by DOAJ.',
      author: authors,
      publisher: b.publisher || '',
      year: b.year || '',
      language: Array.isArray(b.language) ? b.language.join(', ') : (b.language || ''),
      source: 'DOAJ',
      sourceUrl: link || 'https://doaj.org/',
      externalId: x.id || '',
    });
  }).filter((x) => x.title);
}

const GLOBAL_SUBJECTS = [
  ['Literature','الأدب','روايات، شعر، مسرح، قصة قصيرة، نقد أدبي'],
  ['History','التاريخ','الحضارات، التاريخ العالمي، الآثار والتراث'],
  ['Arts','الفنون','الرسم، النحت، التصوير، السينما، المسرح، الموسيقى والتصميم'],
  ['Fiction','الروايات والقصص','كلاسيكيات، بوليسي، خيال علمي، فانتازيا ورعب'],
  ['Children','كتب الأطفال','أدب الأطفال، القصص المصورة والمجلات'],
  ['Philosophy','الفلسفة','الفلسفة، الأخلاق، المنطق والأفكار'],
  ['Science','العلوم','العلوم الطبيعية، الرياضيات والعلوم المبسطة'],
  ['Education','التعليم','التعلم، المراجع والمناهج'],
  ['Biography','السير والشخصيات','السير الذاتية والمذكرات والشخصيات'],
  ['Culture','الثقافة','اللغة، المجتمع، الثقافة والتراث'],
  ['Magazines','المجلات','المجلات، الدوريات وأعدادها'],
  ['Arabic Heritage','التراث العربي','الأدب والمجلات والسلاسل والمؤلفون والرسامون والناشرون العرب'],
];

exports.getAurenGlobalLibrarySubjects = onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    return {
      status:'ok',
      subjects: GLOBAL_SUBJECTS.map((x) => ({
        id:'subject_' + x[0].toLowerCase().replace(/[^a-z0-9]+/g, '_'),
        title:x[1],
        kind:'Subject',
        description:x[2],
        source:'AUREN Global Library Index',
        sourceUrl:'https://openlibrary.org/subjects',
        rights:'Subject metadata only.',
      })),
    };
  },
);

function openAlexResults(data) {
  return (data.results || []).slice(0, 20).map((x) => result({
    id: 'oa_' + (x.id || x.doi || x.title || ''),
    title: x.title,
    kind: x.type || 'Work',
    description: x.abstract_inverted_index ? 'OpenAlex scholarly work record.' : '',
    author: (x.authorships || []).slice(0, 3).map((a) => a.author?.display_name).filter(Boolean).join(', '),
    publisher: x.primary_location?.source?.host_organization_name || '',
    year: x.publication_year || '',
    source: SOURCES.openAlex,
    sourceUrl: x.primary_location?.landing_page_url || x.doi || x.id || '',
    externalId: x.id || x.doi || '',
  }));
}

function curatedArabicResults(query) {
  const q = query.toLowerCase();
  const catalog = [
    ['majid','ماجد','مجلة أطفال وكوميكس عربية','مجلة ماجد','1979','Arabic Kids Magazine'],
    ['samir','سمير','مجلة أطفال وكوميكس مصرية','دار الهلال','1956','Arabic Kids Magazine'],
    ['mickey','ميكي','مجلة ديزني المصورة بالعربية','دار الهلال / ناشرون لاحقاً','1959','Arabic Disney Magazine'],
    ['pocket_mickey','ميكي جيب','سلسلة إصدارات جيب مرتبطة بميكي','دار الهلال','1975','Arabic Disney Series'],
    ['basim','باسم','مجلة أطفال وكوميكس عربية','ناشرون عرب','', 'Arabic Kids Magazine'],
    ['al_sindbad','السندباد','مجلة أدب ومغامرات للأطفال','دار الهلال','', 'Arabic Kids Magazine'],
    ['aladdin','علاء الدين','مجلة أطفال عربية','ناشرون عرب','', 'Arabic Kids Magazine'],
    ['rajul_al_mustahil','رجل المستحيل','سلسلة روايات تجسس ومغامرات عربية','نبيل فاروق / المؤسسة العربية الحديثة','', 'Arabic Series'],
    ['malaf_al_mustaqbal','ملف المستقبل','سلسلة خيال علمي عربية','نبيل فاروق / المؤسسة العربية الحديثة','', 'Arabic Series'],
    ['ma_waraa_al_tabia','ما وراء الطبيعة','سلسلة رعب وفانتازيا عربية','أحمد خالد توفيق','', 'Arabic Series'],
    ['fantazia','فانتازيا','سلسلة روايات فانتازيا عربية','أحمد خالد توفيق','', 'Arabic Series'],
    ['safari','سفاري','سلسلة روايات طبية ومغامرات','أحمد خالد توفيق','', 'Arabic Series'],
  ];
  return catalog.filter((x) => x.some((v) => String(v).toLowerCase().includes(q))).map((x) => result({
    id:'curated_' + x[0],
    title:x[1],
    kind:x[5],
    description:x[2],
    publisher:x[3],
    year:x[4],
    language:'ar',
    country:'العالم العربي',
    source:'AUREN Arabic Heritage Index',
    sourceUrl:'https://www.comics.org/search/?q=' + encodeURIComponent(x[1]),
    externalId:x[0],
  }));
}

exports.searchAurenGlobalLibrary = onCall(
  {region:'us-central1', timeoutSeconds:30, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const query = clean(request.data?.query, 160);
    const page = Math.max(1, Math.min(Number(request.data?.page) || 1, 10));
    if (query.length < 2) throw new HttpsError('invalid-argument', 'Search query must contain at least 2 characters.');

    const encoded = encodeURIComponent(query);
    const tasks = await Promise.allSettled([
      getJson('https://openlibrary.org/search.json?q=' + encoded + '&page=' + page + '&limit=20'),
      getJson('https://api.crossref.org/works?query=' + encoded + '&rows=20'),
      getJson('https://api.openalex.org/works?search=' + encoded + '&per-page=20&page=' + page),
      getJson('https://doaj.org/api/search/articles/' + encoded + '?pageSize=15'),
    ]);

    const out = [
      ...curatedArabicResults(query),
      ...(tasks[0].status === 'fulfilled' ? openLibraryResults(tasks[0].value) : []),
      ...(tasks[1].status === 'fulfilled' ? crossrefResults(tasks[1].value) : []),
      ...(tasks[2].status === 'fulfilled' ? openAlexResults(tasks[2].value) : []),
      ...(tasks[3].status === 'fulfilled' ? doajResults(tasks[3].value) : []),
    ];

    const seen = new Set();
    const results = out.filter((x) => {
      const key = (x.title + '|' + x.source).toLowerCase();
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    }).slice(0, 60);

    return {
      status:'ok',
      query,
      page,
      results,
      sources:[SOURCES.openLibrary, SOURCES.crossref, SOURCES.openAlex, 'DOAJ', 'AUREN Arabic Heritage Index'],
      note:'Global federated metadata search. Full scans/issues are not copied or hosted by this index.',
    };
  },
);
