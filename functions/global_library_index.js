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
  ['World Heritage Stories','قصص الشعوب','حكايات شعبية، أساطير، ملاحم، أمثال وتقاليد السرد من دول العالم'],
  ['Country Stories','قصص من الدول','اكتشف القصص والتراث حسب الدولة والقارة واللغة والمجتمع'],
];

const GLOBAL_HERITAGE_STORIES = [
  {id:'sudan_jertiq',title:'الجرتق السوداني',kind:'Heritage Tradition',country:'Sudan',language:'ar',description:'ممارسات وطقوس وتعبيرات سودانية مرتبطة بالحفظ والحماية والوفرة والخصوبة.',sourceUrl:'https://ich.unesco.org/en/RL/al-jertiq-practices-rituals-and-expressions-for-preservation-protection-abundance-and-fertility-in-sudan-02214',year:'2025'},
  {id:'china_yimakan',title:'Hezhen Yimakan Storytelling',kind:'Storytelling Tradition',country:'China',language:'Hezhen',description:'تقليد سرد شفهي لدى شعب Hezhen يجمع الحكايات والأغاني والذاكرة الجماعية.',sourceUrl:'https://ich.unesco.org/en/RL/hezhen-yimakan-storytelling-02152',year:'2025'},
  {id:'mauritania_samba',title:'The Epic of Samba Gueladio',kind:'Epic',country:'Mauritania',language:'Fulani',description:'ملحمة شفوية متوارثة مرتبطة بالذاكرة والسرد والموسيقى في موريتانيا.',sourceUrl:'https://ich.unesco.org/en/RL/the-epic-of-samba-gueladio-01941',year:'2024'},
  {id:'azerbaijan_nasreddin',title:'Nasreddin Anecdotes',kind:'Folktales',country:'Azerbaijan; Kazakhstan; Kyrgyzstan; Tajikistan; Türkiye; Turkmenistan; Uzbekistan',language:'Multiple',description:'تقليد سرد النوادر المنسوبة إلى نصر الدين، مع اختلافات محلية في الشخصيات والصور والحكايات.',sourceUrl:'https://ich.unesco.org/en/RL/telling-tradition-of-nasreddin-aneecdotes-01705',year:'2022'},
  {id:'benin_geleda',title:'Oral Heritage of Gelede',kind:'Oral Heritage',country:'Benin; Nigeria; Togo',language:'Yoruba',description:'تراث شفهي وفني مرتبط بمجتمعات اليوروبا وانتقال الذاكرة الثقافية عبر الأجيال.',sourceUrl:'https://ich.unesco.org/en/RL/oral-heritage-of-gelede-00002',year:'2008'},
  {id:'uzbekistan_bakhshi',title:'Bakhshi Art',kind:'Epic Storytelling',country:'Uzbekistan',language:'Uzbek',description:'فن سرد ملحمي يجمع الحكاية والموسيقى والأداء ويُتناقل بين الرواة.',sourceUrl:'https://ich.unesco.org/en/RL/bakhshi-art-01515',year:'2021'},
  {id:'japan_folk_tales',title:'Japanese Folk Tales',kind:'Folktales',country:'Japan',language:'Japanese',description:'مجموعة موضوعية لحكايات وموروثات السرد الياباني، تُبحث عبر مصادر المكتبات والتراث المفتوحة.',sourceUrl:'https://www.loc.gov/collections/world-digital-library/about-this-collection/',year:'Global Index'},
  {id:'morocco_jemaa',title:'Jemaa el-Fna Storytelling Culture',kind:'Storytelling Culture',country:'Morocco',language:'ar; Amazigh',description:'فضاء ثقافي حي ارتبط بالرواة والعروض الشفوية والموسيقى والحكايات في مراكش.',sourceUrl:'https://ich.unesco.org/en/RL/cultural-space-of-jemaa-el-fna-square-00014',year:'2008'},
  {id:'vanuatu_sand',title:'Vanuatu Sand Drawings',kind:'Storytelling Art',country:'Vanuatu',language:'Multiple',description:'رسومات رملية تقليدية تحمل معرفة وقصصاً ورموزاً تنتقل داخل المجتمعات.',sourceUrl:'https://ich.unesco.org/en/RL/vanuatu-sand-drawings-00073',year:'2008'},
  {id:'bangladesh_baul',title:'Baul Songs and Stories',kind:'Folk Storytelling',country:'Bangladesh',language:'Bengali',description:'تراث غنائي شفهي يحمل أفكاراً وحكايات وتجارب اجتماعية وروحية.',sourceUrl:'https://ich.unesco.org/en/RL/baul-songs-00107',year:'2008'},
  {id:'korea_arirang',title:'Arirang Folk Song Tradition',kind:'Folk Tradition',country:'Republic of Korea',language:'Korean',description:'تقليد غنائي شعبي واسع الانتشار، يصلح كبوابة لاكتشاف القصص والذاكرة الشعبية الكورية.',sourceUrl:'https://ich.unesco.org/en/RL/arirang-lyrical-folk-song-in-the-republic-of-korea-00445',year:'2012'},
  {id:'togo_gelede',title:'Guin Oral Traditions',kind:'Oral Tradition',country:'Togo',language:'Multiple',description:'سرد وطقوس مرتبطة بالذاكرة المجتمعية والاحتفالات في تقاليد شعب Guin.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'sudan_folklore',title:'Sudanese Oral Traditions & Folk Tales',kind:'Folktales & Oral Tradition',country:'Sudan',language:'Arabic; Nubian; Beja; multiple',description:'بوابة لفهرسة الحكايات والأمثال والأغاني والسرد الشفهي السوداني، مع ربط كل سجل بمصدره.',sourceUrl:'https://ich.unesco.org/en/lists',year:'Global Index'},
  {id:'egypt_hilali',title:'Al-Sirah Al-Hilaliyyah Epic',kind:'Epic',country:'Egypt',language:'Arabic',description:'ملحمة شعبية عربية تروي سيرة بني هلال ورحلتهم إلى شمال أفريقيا.',sourceUrl:'https://ich.unesco.org/en/RL/al-sirah-al-hilaliyyah-epic-00075',year:'2008'},
  {id:'algeria_ahellil',title:'Ahellil of Gourara',kind:'Oral & Musical Tradition',country:'Algeria',language:'Tamazight; Arabic',description:'تقليد من الأناشيد الجماعية في منطقة غورارة مرتبط بالتجمعات والمناسبات.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'albania_iso',title:'Albanian Folk Iso-Polyphony',kind:'Folk Tradition',country:'Albania',language:'Albanian',description:'تقليد غنائي شعبي متعدد الأصوات من الذاكرة الثقافية الألبانية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'kyrgyz_akyns',title:'Art of Akyns, Kyrgyz Epic Tellers',kind:'Epic Storytelling',country:'Kyrgyzstan',language:'Kyrgyz',description:'فن الرواة الملحميين الذين يحفظون وينقلون القصص والأشعار الملحمية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'turkiye_meddah',title:'Arts of the Meddah, Public Storytellers',kind:'Storytelling',country:'Türkiye',language:'Turkish',description:'تقليد الحكواتي العام الذي يعتمد على السرد والأداء وتقمص الشخصيات.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'uganda_koogere',title:'Koogere Oral Tradition',kind:'Oral Tradition',country:'Uganda',language:'Runyakitara',description:'روايات وأقوال مرتبطة بذاكرة مجتمعات Basongora وBanyabindi وBatooro، وتتناول الحكمة والوفرة والبطولة.',sourceUrl:'https://ich.unesco.org/en/USL/koogere-oral-tradition-of-the-basongora-banyabindi-and-batooro-peoples-00911',year:'2015'},
  {id:'philippines_hudhud',title:'Hudhud Chants of the Ifugao',kind:'Epic Oral Tradition',country:'Philippines',language:'Ifugao',description:'أناشيد شفوية تروي أبطالاً وأسلافاً وقوانين وعادات ومعتقدات تقليدية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'philippines_darangen',title:'Darangen Epic of the Maranao',kind:'Epic',country:'Philippines',language:'Maranao',description:'ملحمة شعبية مرتبطة بذاكرة شعب Maranao في منطقة بحيرة Lanao.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'palestine_hikaye',title:'Palestinian Hikaye',kind:'Storytelling Tradition',country:'State of Palestine',language:'Arabic',description:'تقليد حكواتي نسائي يروي القصص وينقل الذاكرة والقيم الاجتماعية عبر الأجيال.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'guatemala_rabinal',title:'Rabinal Achí',kind:'Dance Drama & Story',country:'Guatemala',language:'Achi',description:'مسرحية راقصة تقليدية تحمل سرداً تاريخياً وشخصيات وذاكرة مجتمعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'nicaragua_gueguense',title:'El Güegüense',kind:'Folk Drama',country:'Nicaragua',language:'Spanish; Nahuat',description:'تقليد مسرحي شعبي يجمع السرد والموسيقى والرقص والشخصيات الساخرة.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'brazil_wajapi',title:'Oral and Graphic Expressions of the Wajapi',kind:'Oral & Graphic Heritage',country:'Brazil',language:'Wajapi',description:'تقاليد شفهية ورسوم رمزية تنقل معرفة وهوية وذاكرة مجتمع Wajapi.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'mexico_dead',title:'Indigenous Festivity Dedicated to the Dead',kind:'Living Heritage',country:'Mexico',language:'Spanish; Indigenous languages',description:'تقاليد وطقوس وذاكرة مجتمعية مرتبطة بتكريم الموتى واستمرار الروابط بين الأجيال.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'cambodia_sbek',title:'Sbek Thom, Khmer Shadow Theatre',kind:'Traditional Theatre',country:'Cambodia',language:'Khmer',description:'مسرح ظلال خميري يستخدم الأداء والدمى والسرد التقليدي.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'india_ramlila',title:'Ramlila, Traditional Performance of the Ramayana',kind:'Epic Performance',country:'India',language:'Hindi; multiple',description:'تقليد أدائي يروي حلقات من الرامايانا عبر التمثيل والموسيقى والسرد.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'indonesia_wayang',title:'Wayang Puppet Theatre',kind:'Puppet Storytelling',country:'Indonesia',language:'Indonesian; Javanese; Sundanese',description:'مسرح دمى تقليدي يعتمد على السرد والشخصيات والموسيقى ونقل القصص.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'japan_kabuki',title:'Kabuki Theatre',kind:'Traditional Theatre',country:'Japan',language:'Japanese',description:'مسرح ياباني تقليدي يجمع السرد والأداء والموسيقى والحركة والشخصيات.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'georgia_polyphonic',title:'Georgian Polyphonic Singing',kind:'Folk Tradition',country:'Georgia',language:'Georgian',description:'تقليد غنائي متعدد الأصوات يحمل الذاكرة الموسيقية والاجتماعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'tonga_lakalaka',title:'Lakalaka, Dances and Sung Speeches',kind:'Sung Storytelling',country:'Tonga',language:'Tongan',description:'تقليد يجمع الرقص والخطاب المغنى والسرد الجماعي.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'garifuna',title:'Language, Dance and Music of the Garifuna',kind:'Oral Heritage',country:'Belize; Guatemala; Honduras; Nicaragua',language:'Garifuna',description:'تراث يجمع اللغة والقصص والأغاني والرقص ويحفظ تاريخ ومعرفة مجتمع Garifuna.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'jamaica_moore',title:'Maroon Heritage of Moore Town',kind:'Community Heritage',country:'Jamaica',language:'English; Creole',description:'تراث مجتمعي حي يحمل الذاكرة والقصص والممارسات الثقافية لمجتمع Moore Town.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
];


const GLOBAL_HERITAGE_REGIONS = [
  {id:'africa',title:'Africa',ar:'أفريقيا',countries:['Sudan','Egypt','Morocco','Algeria','Tunisia','Mauritania','Senegal','Mali','Guinea','Nigeria','Ghana','Benin','Togo','Ethiopia','Kenya','Tanzania','Uganda','Rwanda','Cameroon','Gabon','Congo','South Africa','Madagascar']},
  {id:'asia',title:'Asia',ar:'آسيا',countries:['China','Japan','South Korea','India','Pakistan','Bangladesh','Nepal','Bhutan','Sri Lanka','Indonesia','Malaysia','Brunei','Thailand','Vietnam','Cambodia','Philippines','Mongolia','Uzbekistan','Kazakhstan','Kyrgyzstan','Türkiye','Iran','Iraq','Jordan','Saudi Arabia','United Arab Emirates','Oman','Yemen','Palestine']},
  {id:'europe',title:'Europe',ar:'أوروبا',countries:['Ireland','United Kingdom','France','Spain','Portugal','Italy','Germany','Austria','Switzerland','Belgium','Netherlands','Denmark','Sweden','Norway','Finland','Iceland','Poland','Czechia','Hungary','Romania','Bulgaria','Greece','Albania','Serbia','Croatia','Bosnia and Herzegovina','Ukraine','Georgia','Armenia','Azerbaijan']},
  {id:'americas',title:'Americas',ar:'الأمريكتان',countries:['Canada','United States','Mexico','Guatemala','Belize','Cuba','Jamaica','Haiti','Dominican Republic','Colombia','Venezuela','Ecuador','Peru','Bolivia','Brazil','Argentina','Chile','Uruguay','Paraguay']},
  {id:'oceania',title:'Oceania',ar:'أوقيانوسيا',countries:['Australia','New Zealand','Papua New Guinea','Vanuatu','Fiji','Samoa','Tonga','Solomon Islands']},
];

const GLOBAL_HERITAGE_TYPES = [
  {id:'folktales',title:'Folktales',ar:'حكايات شعبية'},
  {id:'legends',title:'Legends',ar:'أساطير'},
  {id:'myths',title:'Myths',ar:'موروثات وأساطير كونية'},
  {id:'epics',title:'Epics',ar:'ملاحم'},
  {id:'oral',title:'Oral Storytelling',ar:'الحكاية الشفوية'},
  {id:'proverbs',title:'Proverbs & Riddles',ar:'أمثال وألغاز'},
  {id:'children',title:'Children Stories',ar:'قصص الأطفال'},
  {id:'heroes',title:'Heroes & Characters',ar:'الأبطال والشخصيات'},
  {id:'creation',title:'Creation Stories',ar:'قصص الخلق'},
  {id:'tricksters',title:'Trickster Tales',ar:'حكايات الشخصيات الماكرة'},
  {id:'history',title:'Historical Stories',ar:'قصص تاريخية'},
  {id:'nature',title:'Nature & Animal Tales',ar:'حكايات الطبيعة والحيوانات'},
];

exports.getAurenGlobalHeritageExplorer = onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    return {
      status:'ok',
      regions:GLOBAL_HERITAGE_REGIONS,
      types:GLOBAL_HERITAGE_TYPES,
      coverage:{
        model:'country → region → language → tradition → story → character → source',
        source:'UNESCO Intangible Cultural Heritage and open/public-domain library sources',
        note:'Coverage is designed to expand country by country; records are metadata/source indexes unless content rights permit full text.',
      },
    };
  },
);

exports.getAurenGlobalHeritageStories = onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const country = clean(request.data?.country, 100).toLowerCase();
    const language = clean(request.data?.language, 80).toLowerCase();
    const query = clean(request.data?.query, 160).toLowerCase();
    const stories = GLOBAL_HERITAGE_STORIES
      .filter((x) => !country || x.country.toLowerCase().includes(country))
      .filter((x) => !language || x.language.toLowerCase().includes(language))
      .filter((x) => !query || [x.title,x.kind,x.country,x.description].join(' ').toLowerCase().includes(query))
      .map((x) => result({
        id:'heritage_' + x.id,
        title:x.title,
        kind:x.kind,
        description:x.description,
        year:x.year,
        language:x.language,
        country:x.country,
        source:'UNESCO Intangible Cultural Heritage / AUREN Heritage Index',
        sourceUrl:x.sourceUrl,
        externalId:x.id,
      }));
    return {
      status:'ok',
      results:stories,
      countries:[...new Set(GLOBAL_HERITAGE_STORIES.flatMap((x) => x.country.split(';').map((c) => c.trim())))].sort(),
      note:'AUREN indexes cultural heritage metadata and source records; it does not reproduce copyrighted stories or scans.',
    };
  },
);


const GLOBAL_HERITAGE_STORY_DETAILS = {
  sudan_folklore:{stories:[{title:'حكايات شعبية سودانية',summary:'مدخل لفهرسة الحكايات الشعبية والرواية الشفوية السودانية حسب المجتمع واللغة والمنطقة.',languages:['Arabic','Nubian','Beja'],regions:['Sudan']}],characters:[],variants:[],sources:['UNESCO Intangible Cultural Heritage']},
  egypt_hilali:{stories:[{title:'السيرة الهلالية',summary:'ملحمة شعبية تتناقلها الأجيال عبر السرد والغناء والأداء، وتدور حول سيرة بني هلال ورحلتهم.',languages:['Arabic'],regions:['Egypt','North Africa']}],characters:['أبو زيد الهلالي','الجازية الهلالية'],variants:['روايات وأداءات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  china_yimakan:{stories:[{title:'Yimakan',summary:'سرد شفهي لدى شعب Hezhen يجمع الحكاية والغناء ويحفظ الذاكرة الجماعية.',languages:['Hezhen'],regions:['China']}],characters:[],variants:['روايات شفهية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  morocco_jemaa:{stories:[{title:'حكايات جامع الفنا',summary:'مدخل لاكتشاف تقاليد الحكواتي والرواة والأداءات الشفوية في ساحة جامع الفنا بمراكش.',languages:['Arabic','Amazigh'],regions:['Morocco']}],characters:[],variants:['روايات وأداءات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  palestine_hikaye:{stories:[{title:'الحكواتي الفلسطيني',summary:'تقليد سردي نسائي ينقل القصص والقيم والذاكرة الاجتماعية عبر الأجيال.',languages:['Arabic'],regions:['State of Palestine']}],characters:[],variants:['روايات عائلية ومحلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  philippines_hudhud:{stories:[{title:'Hudhud',summary:'أناشيد شفوية تروي أبطالاً وأسلافاً وقوانين وعادات ومعتقدات تقليدية لدى Ifugao.',languages:['Ifugao'],regions:['Philippines']}],characters:[],variants:['أداءات وروايات شفوية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  indonesia_wayang:{stories:[{title:'Wayang',summary:'مسرح دمى تقليدي يروي قصصاً وشخصيات عبر الأداء والموسيقى والسرد.',languages:['Javanese','Sundanese','Indonesian'],regions:['Indonesia']}],characters:['شخصيات Wayang المحلية'],variants:['تقاليد Java وSunda وغيرها'],sources:['UNESCO Intangible Cultural Heritage']},
  japan_kabuki:{stories:[{title:'Kabuki',summary:'مسرح تقليدي ياباني يعتمد على السرد والأداء والموسيقى والحركة والشخصيات.',languages:['Japanese'],regions:['Japan']}],characters:[],variants:['مدارس وأساليب أداء متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
};

exports.getAurenGlobalHeritageStoryDetail = onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB', enforceAppCheck:true},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
    const id = clean(request.data?.id, 120).replace(/^heritage_/, '');
    if (!id) throw new HttpsError('invalid-argument', 'Heritage story id is required.');
    const detail = GLOBAL_HERITAGE_STORY_DETAILS[id];
    const base = GLOBAL_HERITAGE_STORIES.find((x) => x.id === id);
    if (!detail && !base) throw new HttpsError('not-found', 'Heritage story was not found.');
    return {
      status:'ok',
      story: base ? result({id:'heritage_' + base.id,title:base.title,kind:base.kind,description:base.description,year:base.year,language:base.language,country:base.country,source:'UNESCO Intangible Cultural Heritage / AUREN Heritage Index',sourceUrl:base.sourceUrl,externalId:base.id}) : null,
      stories:detail?.stories || [],
      characters:detail?.characters || [],
      variants:detail?.variants || [],
      languages:detail?.languages || [],
      regions:detail?.regions || [],
      sources:detail?.sources || [],
      note:'Indexed cultural record; copyrighted text and recordings are not reproduced without permission.',
    };
  },
);

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
