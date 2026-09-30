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
  {id:'chad_guruna',title:'Guruna',kind:'Pastoral & Oral Tradition',country:'Chad; Cameroon',language:'Multiple',description:'ممارسة رعوية واجتماعية وفنية مرتبطة بالماشية لدى مجتمعات Massa.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'romania_cobza',title:'Cobza, Traditional Knowledge, Skills and Music',kind:'Music & Craft Tradition',country:'Romania; Republic of Moldova',language:'Romanian',description:'معرفة ومهارات وموسيقى مرتبطة بصناعة وعزف آلة Cobza.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'turkic_yurt',title:'Traditional Knowledge and Skills in Making Kyrgyz, Kazakh and Karakalpak Yurts',kind:'Traditional Craft & Knowledge',country:'Kazakhstan; Kyrgyzstan; Uzbekistan',language:'Multiple Turkic languages',description:'معارف ومهارات صناعة وتجهيز الخيام التقليدية لدى مجتمعات آسيا الوسطى.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'sudan_jertiq_2025',title:'Al-Jertiq: Practices, Rituals and Expressions in Sudan',kind:'Living Heritage',country:'Sudan',language:'Arabic; multiple',description:'ممارسات وطقوس وتعبيرات سودانية مرتبطة بالحفظ والحماية والوفرة والخصوبة.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'egypt_koshary',title:'Koshary: Daily Life Dish and Practices',kind:'Food Heritage',country:'Egypt',language:'Arabic',description:'معرفة وممارسات مرتبطة بطبق الكشري في الحياة اليومية والمجتمع المصري.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'georgia_wheat',title:'Georgian Wheat Culture',kind:'Agricultural & Food Heritage',country:'Georgia',language:'Georgian',description:'تقاليد وطقوس ومعارف مرتبطة بزراعة القمح والثقافة الغذائية في جورجيا.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'ethiopia_gifaataa',title:'Gifaataa, Wolaita New Year Festival',kind:'Festival Heritage',country:'Ethiopia',language:'Wolaita',description:'احتفال سنوي يحمل الطقوس والأغاني والقصص والذاكرة المجتمعية لدى شعب Wolaita.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'sri_lanka_kithul',title:'Kithul Madeema/Kithul Kapeema',kind:'Traditional Knowledge',country:'Sri Lanka',language:'Sinhala; Tamil',description:'تقنيات ومعارف تقليدية مرتبطة باستخراج عصارة نخيل Kithul.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'togo_guin_newyear',title:'Guin New Year Sacred Stone Rites',kind:'Ritual & Oral Heritage',country:'Togo',language:'Guin',description:'طقوس وممارسات مرتبطة بحمل الحجر المقدس واحتفالات رأس السنة في مجتمع Guin.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'kyrgyz_maksym',title:'Traditional Knowledge and Cultural Contexts of Making Maksym',kind:'Food & Traditional Knowledge',country:'Kyrgyzstan',language:'Kyrgyz',description:'معرفة وممارسات مرتبطة بإعداد مشروب Maksym التقليدي وسياقه الثقافي.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},

  {id:'2025_arabic_kohl',title:'Arabic Kohl',kind:'Heritage Practice',country:'Syria; Iraq; Jordan; Libya; Oman; Palestine; Saudi Arabia; Tunisia; United Arab Emirates',language:'Arabic',description:'معارف ومهارات وممارسات مرتبطة بالكحل العربي عبر مجتمعات متعددة.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'2025_highlife',title:'Highlife music and dance',kind:'Music & Dance',country:'Ghana',language:'English; Akan; multiple',description:'موسيقى ورقص يعكسان تطوراً تاريخياً وثقافياً في غانا.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'2025_diwania',title:'The Diwaniya, a unifying cultural practice in Kuwait',kind:'Social Practice',country:'Kuwait',language:'Arabic',description:'ممارسة اجتماعية تجمع الناس وتدعم التواصل ونقل المعرفة والعادات في الكويت.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},  {id:'jordan_mihrass',title:'Al-Mihrass Tree Knowledge and Rituals',kind:'Traditional Knowledge & Rituals',country:'Jordan',language:'Arabic',description:'معرفة ومهارات وطقوس مرتبطة بشجرة الميحرص في الأردن، ضمن سجل التراث الحي.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'iraq_muhaibis',title:'Al-Muhaibis Social Practices and Traditions',kind:'Social Tradition',country:'Iraq',language:'Arabic',description:'ممارسات اجتماعية وتراثية مرتبطة بلعبة المحيبس والذاكرة الجماعية في العراق.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'arabic_kohl',title:'Arabic Kohl',kind:'Traditional Knowledge',country:'Syria; Iraq; Jordan; Libya; Oman; Palestine; Saudi Arabia; Tunisia; United Arab Emirates',language:'Arabic',description:'معرفة ومهارات وممارسات مرتبطة بصناعة واستخدام الكحل العربي عبر عدة بلدان.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'bisht',title:'Bisht Skills and Practices',kind:'Traditional Craft',country:'Qatar; Bahrain; Iraq; Jordan; Kuwait; Oman; Saudi Arabia; Syria; United Arab Emirates',language:'Arabic',description:'معارف ومهارات صناعة البشت وممارساتها التقليدية في الخليج والعراق وبلاد الشام.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'zaffa',title:'Traditional Wedding Zaffa',kind:'Wedding Tradition',country:'Djibouti; Comoros; United Arab Emirates; Iraq; Jordan; Mauritania; Somalia',language:'Arabic; multiple',description:'تقليد احتفالي في حفلات الزواج يجمع الموسيقى والغناء والحركة والذاكرة الاجتماعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'mvet_oyeng',title:'Mvet Oyeng',kind:'Musical Oral Heritage',country:'Gabon; Cameroon; Republic of the Congo',language:'Multiple',description:'فن موسيقي وممارسات ومهارات مرتبطة بمجتمع Ekang وتحمل تقاليد السرد والذاكرة.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'joropo_venezuela',title:'Joropo in Venezuela',kind:'Music & Dance Tradition',country:'Venezuela',language:'Spanish',description:'تراث موسيقي ورقصي فنّي يحمل قصصاً وذاكرة اجتماعية في فنزويلا.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'kobyz_kazakh',title:'Kobyz and Jirau Epic Tradition',kind:'Music & Epic Tradition',country:'Uzbekistan',language:'Karakalpak',description:'تقليد يجمع آلة Kobyz والسرد الملحمي وفن الجيراو في كاراكالباكستان.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'lahuta_albania',title:'Art of Playing, Singing and Making the Lahuta',kind:'Music & Oral Tradition',country:'Albania',language:'Albanian',description:'تقليد موسيقي مرتبط بصناعة آلة اللَاهوتا وعزفها والغناء المصاحب لها.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'mvet_ekang',title:'Ekang Oral and Musical Traditions',kind:'Oral & Musical Heritage',country:'Gabon; Cameroon; Republic of the Congo',language:'Multiple',description:'مدخل لفهرسة الروايات والأغاني والشخصيات والذاكرة المرتبطة بتقاليد Ekang.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'yemen_hadrami_dan',title:'Hadrami Dan Gathering',kind:'Performing & Oral Tradition',country:'Yemen',language:'Arabic',description:'تقليد احتفالي وأدائي حضرمي يفتح مدخلاً لفهرسة الشعر والقصص والذاكرة المجتمعية في اليمن.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'indonesia_pantun',title:'Pantun',kind:'Oral Poetry',country:'Indonesia; Malaysia; Brunei Darussalam',language:'Malay',description:'تقليد شعري شفهي يستخدم الأبيات القصيرة للتعبير عن الحكمة والمشاعر والتواصل الاجتماعي.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'mauritania_mahadra',title:'Mahadra',kind:'Knowledge & Oral Expression',country:'Mauritania',language:'Arabic; Hassaniya',description:'نظام مجتمعي لنقل المعرفة والتعبير الشفهي والتعليم التقليدي في موريتانيا.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'uae_al_ahalla',title:'Al Ahalla',kind:'Living Performing Art',country:'United Arab Emirates',language:'Arabic',description:'فن أدائي حي في الإمارات يمكن ربطه بالشعر والإيقاع والذاكرة المجتمعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'ethiopia_xeer',title:'Xeer Ciise Oral Customary Laws',kind:'Oral Customary Heritage',country:'Ethiopia; Djibouti; Somalia',language:'Somali',description:'معرفة وقواعد عرفية شفهية لمجتمعات Somali-Issa، تُفهرس ضمن التراث القانوني الشفهي.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2024'},
  {id:'central_asia_nawrouz',title:'Nawrouz / Nowruz',kind:'Festival & Oral Heritage',country:'Afghanistan; Azerbaijan; India; Iran; Iraq; Kazakhstan; Kyrgyzstan; Pakistan; Tajikistan; Türkiye; Turkmenistan; Uzbekistan; Mongolia',language:'Multiple',description:'تراث مشترك متعدد الدول يجمع الطقوس والحكايات والأغاني والمعرفة المرتبطة بالعام الجديد.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2024'},
  {id:'west_africa_balafon',title:'Balafon and Kolintang Cultural Practices',kind:'Music & Oral Heritage',country:'Mali; Burkina Faso; Côte d’Ivoire; Indonesia',language:'Multiple',description:'ممارسات ثقافية مرتبطة بالموسيقى والآلات والذاكرة المجتمعية في عدة بلدان.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2024'},
  {id:'bosnia_sevdalinka',title:'Sevdalinka, Traditional Urban Folk Song',kind:'Folk Song & Storytelling',country:'Bosnia and Herzegovina',language:'Bosnian',description:'غناء شعبي حضري يحمل قصصاً ومشاعر وذاكرة اجتماعية من البلقان.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2024'},
  {id:'grenada_shakespeare_mas',title:'Shakespeare Mas’',kind:'Carnival Story Tradition',country:'Grenada',language:'English; Creole',description:'تقليد كرنفالي يجمع الأداء والشخصيات والسرد والذاكرة المجتمعية في غرينادا.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2024'},
  {id:'brazil_minas_cheese',title:'Traditional Ways of Making Artisan Minas Cheese',kind:'Traditional Knowledge',country:'Brazil',language:'Portuguese',description:'معرفة تقليدية مرتبطة بالمجتمع والطعام ونقل المهارات بين الأجيال في البرازيل.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2024'},
  {id:'zambia_mangwengwe',title:'Mangwengwe Dance',kind:'Dance & Oral Heritage',country:'Zambia',language:'Multiple',description:'تقليد أدائي ورقصي يمكن فهرسة الأغاني والقصص والممارسات المجتمعية المرتبطة به.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2024'},
  {id:'jamaica_moore',title:'Maroon Heritage of Moore Town',kind:'Community Heritage',country:'Jamaica',language:'English; Creole',description:'تراث مجتمعي حي يحمل الذاكرة والقصص والممارسات الثقافية لمجتمع Moore Town.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'ireland_uillean',title:'Uilleann Piping Tradition',kind:'Music & Oral Tradition',country:'Ireland',language:'Irish; English',description:'تقليد موسيقي حي يمكن من خلاله فهرسة الحكايات والأغاني والذاكرة الشعبية الأيرلندية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2017'},
  {id:'spain_flamenco',title:'Flamenco Heritage',kind:'Performance Tradition',country:'Spain',language:'Spanish',description:'تراث أدائي يجمع الموسيقى والغناء والرقص ويحفظ ذاكرة ثقافية محلية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2010'},
  {id:'france_compagnonnage',title:'Compagnonnage',kind:'Traditional Knowledge',country:'France',language:'French',description:'تقليد لنقل المعرفة والحرف والمهارات عبر الأجيال والمجتمعات المهنية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2010'},
  {id:'italy_sardinian',title:'Canto a Tenore',kind:'Folk Singing',country:'Italy',language:'Sardinian; Italian',description:'غناء شعبي جماعي من سردينيا يحمل الذاكرة المحلية والتقاليد الشفوية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'greece_rebetiko',title:'Rebetiko',kind:'Music & Storytelling',country:'Greece',language:'Greek',description:'تقليد غنائي حضري يحمل قصص الحياة اليومية والهوية الاجتماعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2017'},
  {id:'serbia_guvno',title:'Kolo, Traditional Folk Dance',kind:'Folk Tradition',country:'Serbia',language:'Serbian',description:'رقص جماعي تقليدي مرتبط بالمناسبات والذاكرة الاجتماعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2017'},
  {id:'armenia_duduk',title:'Duduk Music',kind:'Music Tradition',country:'Armenia',language:'Armenian',description:'تقليد موسيقي يحمل ألحاناً وذاكرة ثقافية تنتقل بين الأجيال.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'georgia_qvevri',title:'Qvevri Wine-making Tradition',kind:'Living Tradition',country:'Georgia',language:'Georgian',description:'معرفة وممارسات تقليدية مرتبطة بالمجتمع والاحتفال ونقل المعرفة.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2013'},
  {id:'iran_naqqali',title:'Naqqali, Persian Dramatic Storytelling',kind:'Storytelling',country:'Iran',language:'Persian',description:'فن حكواتي وأداء درامي ينقل القصص والشخصيات والذاكرة عبر الأداء الشفهي.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2011'},
  {id:'iraq_maqaam',title:'Iraqi Maqam Tradition',kind:'Music & Oral Tradition',country:'Iraq',language:'Arabic',description:'تقليد موسيقي عراقي غني بالسرد والأداء والذاكرة الثقافية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'saudi_al_sadu',title:'Al Sadu Weaving',kind:'Traditional Knowledge',country:'Saudi Arabia',language:'Arabic',description:'معرفة حرفية بدوية تحمل رموزاً وأنماطاً وذاكرة اجتماعية متوارثة.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2020'},
  {id:'uae_al_ayyala',title:'Al-Ayyala',kind:'Performance Tradition',country:'United Arab Emirates; Oman',language:'Arabic',description:'تقليد أداء جماعي يجمع الشعر والحركة والإيقاع ويظهر في المناسبات المجتمعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2014'},
  {id:'oman_al_bar_ah',title:'Al-Bar’ah',kind:'Dance & Poetry',country:'Oman',language:'Arabic',description:'تقليد يجمع الشعر والرقص والموسيقى في محافظة ظفار.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2018'},
  {id:'yemen_sanaani',title:'Song of Sana’a',kind:'Music & Oral Heritage',country:'Yemen',language:'Arabic',description:'تراث غنائي يمني يحمل أشكالاً من الشعر والذاكرة والأداء التقليدي.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'nepal_charya',title:'Charya Dance',kind:'Traditional Performance',country:'Nepal',language:'Nepali; Newar',description:'تقليد أدائي مرتبط بالقصص والرموز والممارسات الثقافية في وادي كاتماندو.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2024'},
  {id:'vietnam_don_ca',title:'Don Ca Tai Tu',kind:'Music & Oral Tradition',country:'Vietnam',language:'Vietnamese',description:'فن موسيقي جنوبي يجمع الأداء والتقاليد الشفوية والمجالس الاجتماعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2013'},
  {id:'thailand_khon',title:'Khon Masked Dance Drama',kind:'Epic Theatre',country:'Thailand',language:'Thai',description:'مسرح راقص مقنع يروي حلقات من تقاليد راماكين عبر الأداء والموسيقى.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2018'},
  {id:'malaysia_dondang',title:'Dondang Sayang',kind:'Poetic Singing',country:'Malaysia',language:'Malay',description:'تقليد غنائي شعري يعتمد على الارتجال والحوار ونقل القصص الاجتماعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2018'},
  {id:'indonesia_noken',title:'Noken Cultural Tradition',kind:'Community Heritage',country:'Indonesia',language:'Multiple',description:'تقليد مجتمعي يحمل معرفة وصناعة ورموزاً متوارثة لدى مجتمعات بابوا.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2012'},
  {id:'mongolia_urtiin',title:'Urtiin Duu, Long Song',kind:'Folk Singing',country:'Mongolia',language:'Mongolian',description:'تقليد غنائي طويل يحمل صور الطبيعة والحياة البدوية والذاكرة الشعبية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'canada_micmac',title:'Mi’kmaq Storytelling Heritage',kind:'Indigenous Oral Tradition',country:'Canada',language:'Mi’kmaq; English',description:'مدخل لفهرسة القصص والمعرفة الشفوية للشعوب الأصلية وربطها بالمصادر الموثوقة.',sourceUrl:'https://ich.unesco.org/en/lists',year:'Global Index'},
  {id:'peru_qoyllur',title:'Qoyllurit’i Pilgrimage Tradition',kind:'Living Heritage',country:'Peru',language:'Spanish; Quechua',description:'تقليد مجتمعي يجمع الطقوس والموسيقى والحكايات والذاكرة المحلية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2011'},
  {id:'bolivia_kallawaya',title:'Kallawaya Healing Knowledge',kind:'Traditional Knowledge',country:'Bolivia',language:'Quechua; Spanish',description:'معرفة تقليدية تنتقل شفهياً وتحمل مفردات وقصصاً وممارسات مجتمعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2008'},
  {id:'colombia_marimba',title:'Marimba Music and Traditional Chants',kind:'Music & Oral Tradition',country:'Colombia; Ecuador',language:'Spanish; Afro-descendant languages',description:'موسيقى وأناشيد تقليدية تحمل الذاكرة والتاريخ والاحتفال في مجتمعات ساحل المحيط الهادئ.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2015'},
  {id:'argentina_tango',title:'Tango',kind:'Music & Dance',country:'Argentina; Uruguay',language:'Spanish',description:'تراث أدائي حضري يجمع الموسيقى والرقص والشعر والذاكرة الاجتماعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2009'},
  {id:'haiti_soup_joumou',title:'Joumou Cultural Tradition',kind:'Living Heritage',country:'Haiti',language:'Haitian Creole; French',description:'تقليد غذائي وذاكرة مجتمعية يمكن فهرستها ضمن قصص الشعوب والممارسات الحية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2021'},
  {id:'australia_aboriginal',title:'Australian Aboriginal Story Traditions',kind:'Indigenous Oral Heritage',country:'Australia',language:'Multiple Indigenous languages',description:'بوابة لفهرسة تقاليد السرد والمعرفة لدى الشعوب الأصلية الأسترالية حسب المجتمع واللغة والمصدر.',sourceUrl:'https://ich.unesco.org/en/lists',year:'Global Index'},
  {id:'new_zealand_moko',title:'Māori Cultural Story Traditions',kind:'Indigenous Heritage',country:'New Zealand',language:'Māori; English',description:'مدخل لفهرسة القصص والرموز والمعرفة الشفوية المرتبطة بالتراث الماوري.',sourceUrl:'https://ich.unesco.org/en/lists',year:'Global Index'},
  {id:'czech_amateur_theatre',title:'Amateur Theatre Acting in Czechia',kind:'Performing Arts',country:'Czechia',language:'Czech',description:'تقليد المسرح الهواةي ونقل مهارات الأداء المسرحي داخل المجتمعات المحلية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'turkiye_antep_isi',title:'Antep İşi, Drawn Thread Embroidery of Gaziantep',kind:'Traditional Craft',country:'Türkiye',language:'Turkish',description:'حرفة تطريز تقليدية في غازي عنتاب تحمل تقنيات وأنماطاً متوارثة.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'iran_ayeneh_kari',title:'Ayeneh-Kari, Mirror-Work in Persian Architecture',kind:'Traditional Craft',country:'Iran',language:'Persian',description:'فن زخرفة العمارة الفارسية بالمرايا ومعارفه ومهاراته التقليدية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'ghana_highlife',title:'Highlife Music and Dance',kind:'Music & Dance Heritage',country:'Ghana',language:'English; local languages',description:'موسيقى ورقص حضريان يحملان تاريخاً وذاكرة اجتماعية في غانا.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'italy_cooking',title:'Italian Cooking, Between Sustainability and Biocultural Diversity',kind:'Food Heritage',country:'Italy',language:'Italian',description:'معارف وممارسات الطبخ الإيطالي المرتبطة بالاستدامة والتنوع الحيوي والثقافي.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'morocco_caftar',title:'Moroccan Caftan: Art, Traditions and Skills',kind:'Traditional Craft & Dress',country:'Morocco',language:'Arabic; Amazigh',description:'فن وتقنيات وتقاليد القفطان المغربي ونقل مهاراته بين الأجيال.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'sao_tome_tchiloli',title:'Tchiloli, Living Theatre of São Tomé and Príncipe',kind:'Traditional Theatre',country:'Sao Tome and Principe',language:'Portuguese; local varieties',description:'مسرح حي يجمع الأداء والسرد والعدالة والذاكرة المجتمعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'kuwait_diwaniya',title:'The Diwaniya, a Unifying Cultural Practice',kind:'Social Tradition',country:'Kuwait',language:'Arabic',description:'ممارسة اجتماعية تجمع الناس للحوار والضيافة ونقل الذاكرة والمعرفة.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'cuba_son',title:'The Practice of Cuban Son',kind:'Music & Dance Heritage',country:'Cuba',language:'Spanish',description:'تقليد موسيقي ورقصي كوبي يجمع الإيقاع والأداء والذاكرة الاجتماعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'bangladesh_saree',title:'Traditional Saree Weaving Art of Tangail',kind:'Textile Heritage',country:'Bangladesh',language:'Bengali',description:'معارف ومهارات نسج الساري التقليدي في منطقة Tangail.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'japan_washi',title:'Washi, Traditional Japanese Hand-Made Paper',kind:'Traditional Craft',country:'Japan',language:'Japanese',description:'حرفة صناعة الورق الياباني التقليدي باليد ونقل مهاراتها عبر الأجيال.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'japan_float_festivals',title:'Yama, Hoko, Yatai Float Festivals in Japan',kind:'Festival Heritage',country:'Japan',language:'Japanese',description:'مهرجانات تقليدية تستخدم العربات الاحتفالية والموسيقى والطقوس والذاكرة المحلية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'switzerland_yodelling',title:'Yodelling',kind:'Vocal Tradition',country:'Switzerland',language:'Swiss German; multiple',description:'تقليد غنائي صوتي يستخدم تقنيات النداء وتبادل الأصوات في المجتمعات المحلية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'turkmen_alabay',title:'The Art of Breeding Turkmen Alabay',kind:'Animal Heritage',country:'Turkmenistan',language:'Turkmen',description:'معارف وممارسات تربية كلب Alabay التركماني المرتبطة بالهوية والمعرفة المحلية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'uae_sadu_2025',title:'Al Sadu, Traditional Weaving Skills in the United Arab Emirates',kind:'Textile Heritage',country:'United Arab Emirates',language:'Arabic',description:'مهارات نسج تقليدية إماراتية تحمل أنماطاً ورموزاً وذاكرة مجتمعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'madagascar_tsapiky',title:'Tsapiky, Rhythm and Musical Style of South-West Madagascar',kind:'Music Heritage',country:'Madagascar',language:'Malagasy',description:'إيقاع وأسلوب موسيقي متجذر في جنوب غرب مدغشقر.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'2025_kobyz_urgent',title:'Art of Crafting and Playing Kobyz',kind:'Urgent Safeguarding Heritage',country:'Uzbekistan',language:'Karakalpak; Uzbek',description:'معارف صناعة وعزف آلة Kobyz التقليدية ونقلها بين الأجيال.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'2025_boreendo',title:'Boreendo, Bhorindo: Ancient Folk Musical Instrument',kind:'Urgent Safeguarding Heritage',country:'Pakistan',language:'Sindhi; local languages',description:'آلة موسيقية شعبية قديمة ومعارفها وألحانها ومهارات صناعتها.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'2025_dong_ho',title:'Đông Hồ Folk Woodblock Printing',kind:'Urgent Safeguarding Craft',country:'Viet Nam',language:'Vietnamese',description:'حرفة الطباعة الخشبية الشعبية في Đông Hồ وتقنياتها ورسومها التقليدية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},
  {id:'2025_mwazindika',title:'Mwazindika Spiritual Dance of the Daida Community',kind:'Urgent Safeguarding Dance',country:'Kenya',language:'Digo; local languages',description:'رقصة روحية تقليدية لدى مجتمع Daida ومعارفها وممارساتها الاجتماعية.',sourceUrl:'https://ich.unesco.org/en/lists',year:'2025'},

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
    const countries = [...new Set(GLOBAL_HERITAGE_STORIES.flatMap((x) => x.country.split(';').map((c) => c.trim()).filter(Boolean)))].sort();
    const languages = [...new Set(GLOBAL_HERITAGE_STORIES.flatMap((x) => x.language.split(';').map((c) => c.trim()).filter(Boolean)))].sort();
    const years = [...new Set(GLOBAL_HERITAGE_STORIES.map((x) => String(x.year || '')).filter(Boolean))].sort((a,b) => b.localeCompare(a));
    const typeCounts = {};
    const countryCounts = {};
    for (const x of GLOBAL_HERITAGE_STORIES) {
      typeCounts[x.kind] = (typeCounts[x.kind] || 0) + 1;
      for (const country of x.country.split(';').map((v) => v.trim()).filter(Boolean)) countryCounts[country] = (countryCounts[country] || 0) + 1;
    }
    return {
      status:'ok',
      regions:GLOBAL_HERITAGE_REGIONS,
      types:GLOBAL_HERITAGE_TYPES,
      countries,
      languages,
      years,
      statistics:{
        indexedStories:GLOBAL_HERITAGE_STORIES.length,
        countries:countries.length,
        languages:languages.length,
        recordsWithDetails:Object.keys(GLOBAL_HERITAGE_STORY_DETAILS || {}).length,
        typeCounts,
        countryCounts,
      },
      navigation:{
        levels:['Region','Country','Language','Heritage Type','Tradition','Story','Character','Variant','Source'],
        filters:['region','country','language','type','year','query'],
        actions:['browse','search','openDetail','openSource'],
      },
      coverage:{
        model:'region → country → language → heritage type → tradition → story → character → variant → source',
        source:'UNESCO Intangible Cultural Heritage and open/public-domain library sources',
        note:'Records are metadata/source indexes unless content rights permit full text. Source links remain the canonical place for nomination files, photos, videos and community-consent evidence.',
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
    const type = clean(request.data?.type, 100).toLowerCase();
    const year = clean(request.data?.year, 40).toLowerCase();
    const region = clean(request.data?.region, 100).toLowerCase();
    const query = clean(request.data?.query, 160).toLowerCase();
    const stories = GLOBAL_HERITAGE_STORIES
      .filter((x) => !country || x.country.toLowerCase().includes(country))
      .filter((x) => !language || x.language.toLowerCase().includes(language))
      .filter((x) => !type || x.kind.toLowerCase().includes(type))
      .filter((x) => !year || String(x.year).toLowerCase().includes(year))
      .filter((x) => {
        if (!region) return true;
        const r = GLOBAL_HERITAGE_REGIONS.find((entry) => entry.id === region || entry.title.toLowerCase() === region);
        return r ? r.countries.some((c) => x.country.toLowerCase().includes(c.toLowerCase())) : false;
      })
      .filter((x) => !query || [x.title,x.kind,x.country,x.language,x.description,x.year].join(' ').toLowerCase().includes(query))
      .map((x) => {
        const detail = GLOBAL_HERITAGE_STORY_DETAILS?.[x.id];
        const detailRegions = detail?.regions || [];
        const matchedRegion = GLOBAL_HERITAGE_REGIONS.find((entry) => entry.countries.some((c) => x.country.toLowerCase().includes(c.toLowerCase())));
        return result({
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
        });
      }).map((item) => ({
        ...item,
        heritageType:item.kind,
        hasDetail:Boolean(GLOBAL_HERITAGE_STORY_DETAILS?.[item.externalId]),
        region:GLOBAL_HERITAGE_REGIONS.find((entry) => entry.countries.some((c) => item.country.toLowerCase().includes(c.toLowerCase())))?.title || '',
        detailLanguages:GLOBAL_HERITAGE_STORY_DETAILS?.[item.externalId]?.languages || [],
        detailRegions:GLOBAL_HERITAGE_STORY_DETAILS?.[item.externalId]?.regions || [],
      }));
    return {
      status:'ok',
      results:stories,
      countries:[...new Set(GLOBAL_HERITAGE_STORIES.flatMap((x) => x.country.split(';').map((c) => c.trim())))].sort(),
      languages:[...new Set(GLOBAL_HERITAGE_STORIES.flatMap((x) => x.language.split(';').map((c) => c.trim())))].sort(),
      types:[...new Set(GLOBAL_HERITAGE_STORIES.map((x) => x.kind))].sort(),
      regions:GLOBAL_HERITAGE_REGIONS,
      total:stories.length,
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
  chad_guruna:{stories:[{title:'Guruna',summary:'ممارسة رعوية واجتماعية وفنية مرتبطة بالماشية لدى مجتمعات Massa.',languages:['Multiple'],regions:['Chad','Cameroon']}],characters:[],variants:['ممارسات مجتمعية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  romania_cobza:{stories:[{title:'Cobza',summary:'معرفة ومهارات وموسيقى مرتبطة بصناعة وعزف آلة Cobza.',languages:['Romanian'],regions:['Romania','Republic of Moldova']}],characters:[],variants:['أساليب محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  turkic_yurt:{stories:[{title:'Traditional Turkic Yurts',summary:'معارف ومهارات صناعة وتجهيز الخيام التقليدية لدى مجتمعات آسيا الوسطى.',languages:['Multiple Turkic languages'],regions:['Kazakhstan','Kyrgyzstan','Uzbekistan']}],characters:[],variants:['أنماط محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  sudan_jertiq_2025:{stories:[{title:'Al-Jertiq',summary:'ممارسات وطقوس وتعبيرات سودانية مرتبطة بالحفظ والحماية والوفرة والخصوبة.',languages:['Arabic','multiple'],regions:['Sudan']}],characters:[],variants:['ممارسات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  egypt_koshary:{stories:[{title:'Koshary',summary:'معرفة وممارسات مرتبطة بطبق الكشري في الحياة اليومية والمجتمع المصري.',languages:['Arabic'],regions:['Egypt']}],characters:[],variants:['ممارسات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  georgia_wheat:{stories:[{title:'Georgian Wheat Culture',summary:'تقاليد وطقوس ومعارف مرتبطة بزراعة القمح والثقافة الغذائية في جورجيا.',languages:['Georgian'],regions:['Georgia']}],characters:[],variants:['تقاليد إقليمية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  ethiopia_gifaataa:{stories:[{title:'Gifaataa',summary:'احتفال سنوي يحمل الطقوس والأغاني والقصص والذاكرة المجتمعية لدى شعب Wolaita.',languages:['Wolaita'],regions:['Ethiopia']}],characters:[],variants:['ممارسات مجتمعية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  sri_lanka_kithul:{stories:[{title:'Kithul Madeema/Kithul Kapeema',summary:'تقنيات ومعارف تقليدية مرتبطة باستخراج عصارة نخيل Kithul.',languages:['Sinhala','Tamil'],regions:['Sri Lanka']}],characters:[],variants:['تقنيات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  togo_guin_newyear:{stories:[{title:'Guin New Year Sacred Stone Rites',summary:'طقوس وممارسات مرتبطة بحمل الحجر المقدس واحتفالات رأس السنة في مجتمع Guin.',languages:['Guin'],regions:['Togo']}],characters:[],variants:['ممارسات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  kyrgyz_maksym:{stories:[{title:'Maksym',summary:'معرفة وممارسات مرتبطة بإعداد مشروب Maksym التقليدي وسياقه الثقافي.',languages:['Kyrgyz'],regions:['Kyrgyzstan']}],characters:[],variants:['وصفات وممارسات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  jordan_mihrass:{stories:[{title:'Al-Mihrass',summary:'معرفة ومهارات وطقوس مرتبطة بشجرة الميحرص في الأردن.',languages:['Arabic'],regions:['Jordan']}],characters:[],variants:['ممارسات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  iraq_muhaibis:{stories:[{title:'Al-Muhaibis',summary:'ممارسات اجتماعية وتراثية مرتبطة بلعبة المحيبس والذاكرة الجماعية العراقية.',languages:['Arabic'],regions:['Iraq']}],characters:[],variants:['تقاليد محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  arabic_kohl:{stories:[{title:'Arabic Kohl',summary:'معرفة ومهارات وممارسات مرتبطة بصناعة واستخدام الكحل العربي عبر عدة مجتمعات.',languages:['Arabic'],regions:['Middle East','North Africa']}],characters:[],variants:['تقاليد محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  bisht:{stories:[{title:'Bisht',summary:'مهارات صناعة البشت وممارساتها التقليدية المتوارثة في عدة دول عربية.',languages:['Arabic'],regions:['Arabian Peninsula','Iraq','Levant']}],characters:[],variants:['أنماط إقليمية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  zaffa:{stories:[{title:'Traditional Wedding Zaffa',summary:'تقليد احتفالي يجمع الموسيقى والغناء والحركة في حفلات الزواج.',languages:['Arabic','multiple'],regions:['Arabian Peninsula','Horn of Africa','Levant']}],characters:[],variants:['تقاليد وطنية ومحلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  mvet_oyeng:{stories:[{title:'Mvet Oyeng',summary:'فن موسيقي وممارسات ومهارات مرتبطة بمجتمع Ekang وتحمل تقاليد السرد والذاكرة.',languages:['Multiple'],regions:['Gabon','Cameroon','Republic of the Congo']}],characters:[],variants:['تقاليد Ekang متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  joropo_venezuela:{stories:[{title:'Joropo',summary:'تراث موسيقي ورقصي فنّي يحمل قصصاً وذاكرة اجتماعية في فنزويلا.',languages:['Spanish'],regions:['Venezuela']}],characters:[],variants:['أنماط إقليمية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  kobyz_kazakh:{stories:[{title:'Kobyz and Jirau Epic Tradition',summary:'تقليد يجمع الموسيقى والسرد الملحمي وفن الجيراو في كاراكالباكستان.',languages:['Karakalpak'],regions:['Uzbekistan']}],characters:[],variants:['روايات وأداءات ملحمية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  lahuta_albania:{stories:[{title:'Lahuta Tradition',summary:'تقليد موسيقي يرتبط بصناعة آلة اللَاهوتا وعزفها والغناء المصاحب لها.',languages:['Albanian'],regions:['Albania']}],characters:[],variants:['أنماط محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  mvet_ekang:{stories:[{title:'Ekang Oral Traditions',summary:'مدخل لفهرسة الروايات والأغاني والشخصيات والذاكرة المرتبطة بتقاليد Ekang.',languages:['Multiple'],regions:['Gabon','Cameroon','Republic of the Congo']}],characters:[],variants:['تقاليد مجتمعية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  yemen_hadrami_dan:{stories:[{title:'Hadrami Dan',summary:'تقليد أدائي حي في اليمن يمكن من خلاله فهرسة الشعر والإيقاع والذاكرة المحلية.',languages:['Arabic'],regions:['Yemen']}],characters:[],variants:['أداءات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  indonesia_pantun:{stories:[{title:'Pantun',summary:'شعر شفهي قصير يعتمد على الإيقاع والصور البلاغية ويُستخدم في التواصل والحكمة والمناسبات.',languages:['Malay'],regions:['Indonesia','Malaysia','Brunei Darussalam']}],characters:[],variants:['تقاليد إقليمية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  mauritania_mahadra:{stories:[{title:'Mahadra',summary:'نظام مجتمعي لنقل المعرفة والتعبير الشفهي والتعليم التقليدي في موريتانيا.',languages:['Arabic','Hassaniya'],regions:['Mauritania']}],characters:[],variants:['مدارس ومجتمعات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  uae_al_ahalla:{stories:[{title:'Al Ahalla',summary:'فن أدائي حي في الإمارات يربط الشعر والإيقاع والأداء بالذاكرة المجتمعية.',languages:['Arabic'],regions:['United Arab Emirates']}],characters:[],variants:['أداءات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  ethiopia_xeer:{stories:[{title:'Xeer Ciise',summary:'معرفة وقواعد عرفية شفهية تنتقل داخل مجتمعات Somali-Issa عبر الذاكرة والتعليم المجتمعي.',languages:['Somali'],regions:['Ethiopia','Djibouti','Somalia']}],characters:[],variants:['تقاليد عرفية محلية'],sources:['UNESCO Intangible Cultural Heritage']},
  central_asia_nawrouz:{stories:[{title:'Nawrouz / Nowruz',summary:'تراث مشترك متعدد الدول يجمع الاحتفال والطقوس والأغاني والمعرفة والحكايات.',languages:['Multiple'],regions:['Central Asia','Middle East','South Asia']}],characters:[],variants:['تقاليد وطنية ومحلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  west_africa_balafon:{stories:[{title:'Balafon and Kolintang Practices',summary:'ممارسات موسيقية وثقافية مرتبطة بالذاكرة المجتمعية في غرب أفريقيا وإندونيسيا.',languages:['Multiple'],regions:['West Africa','Indonesia']}],characters:[],variants:['تقاليد مجتمعية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  bosnia_sevdalinka:{stories:[{title:'Sevdalinka',summary:'غناء شعبي حضري ينقل قصصاً ومشاعر وذاكرة اجتماعية في البوسنة والهرسك.',languages:['Bosnian'],regions:['Bosnia and Herzegovina']}],characters:[],variants:['أداءات ومدارس محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  grenada_shakespeare_mas:{stories:[{title:'Shakespeare Mas’',summary:'تقليد كرنفالي يجمع الشخصيات والأداء والسرد والذاكرة المجتمعية في غرينادا.',languages:['English','Creole'],regions:['Grenada']}],characters:[],variants:['أداءات كرنفالية محلية'],sources:['UNESCO Intangible Cultural Heritage']},
  brazil_minas_cheese:{stories:[{title:'Artisan Minas Cheese Tradition',summary:'معرفة تقليدية مرتبطة بالطعام والمجتمع ونقل المهارات بين الأجيال.',languages:['Portuguese'],regions:['Brazil']}],characters:[],variants:['تقاليد محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  zambia_mangwengwe:{stories:[{title:'Mangwengwe Dance',summary:'تقليد رقص وأداء يمكن فهرسة الأغاني والقصص والممارسات المجتمعية المرتبطة به.',languages:['Multiple'],regions:['Zambia']}],characters:[],variants:['أداءات مجتمعية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  ireland_uillean:{stories:[{title:'Uilleann Piping Tradition',summary:'تقليد موسيقي أيرلندي يمكن فهرسة الأغاني والحكايات والذاكرة المرتبطة به عبر المصادر الثقافية.',languages:['Irish','English'],regions:['Ireland']}],characters:[],variants:['تقاليد محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  spain_flamenco:{stories:[{title:'Flamenco',summary:'تراث أدائي يجمع الغناء والرقص والموسيقى ويحمل قصصاً وذاكرة اجتماعية.',languages:['Spanish'],regions:['Spain']}],characters:[],variants:['مدارس وأنماط أداء متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  iran_naqqali:{stories:[{title:'Naqqali',summary:'فن الحكواتي الفارسي الذي يعتمد على الأداء الشفهي والقصص والشخصيات.',languages:['Persian'],regions:['Iran']}],characters:[],variants:['روايات وأداءات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  iraq_maqaam:{stories:[{title:'Iraqi Maqam',summary:'تقليد موسيقي عراقي يجمع الأداء والشعر والذاكرة الثقافية.',languages:['Arabic'],regions:['Iraq']}],characters:[],variants:['مدارس وأداءات عراقية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  saudi_al_sadu:{stories:[{title:'Al Sadu',summary:'معرفة نسج تقليدية تحمل رموزاً وأنماطاً وذاكرة اجتماعية متوارثة.',languages:['Arabic'],regions:['Saudi Arabia']}],characters:[],variants:['أنماط محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  uae_al_ayyala:{stories:[{title:'Al-Ayyala',summary:'أداء جماعي يجمع الشعر والحركة والإيقاع في المناسبات المجتمعية.',languages:['Arabic'],regions:['United Arab Emirates','Oman']}],characters:[],variants:['أداءات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  oman_al_bar_ah:{stories:[{title:'Al-Bar’ah',summary:'تقليد يجمع الشعر والرقص والموسيقى في ظفار.',languages:['Arabic'],regions:['Oman']}],characters:[],variants:['أنماط محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  thailand_khon:{stories:[{title:'Khon',summary:'مسرح راقص مقنع يروي حلقات من تقاليد راماكين عبر الأداء والموسيقى.',languages:['Thai'],regions:['Thailand']}],characters:['شخصيات راماكين'],variants:['أداءات ومدارس محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  malaysia_dondang:{stories:[{title:'Dondang Sayang',summary:'تقليد غنائي شعري يعتمد على الارتجال والحوار ونقل القصص الاجتماعية.',languages:['Malay'],regions:['Malaysia']}],characters:[],variants:['أداءات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  mongolia_urtiin:{stories:[{title:'Urtiin Duu',summary:'غناء طويل يحمل صور الطبيعة والحياة البدوية والذاكرة الشعبية المنغولية.',languages:['Mongolian'],regions:['Mongolia']}],characters:[],variants:['أنماط إقليمية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  peru_qoyllur:{stories:[{title:'Qoyllurit’i',summary:'تقليد مجتمعي يجمع الطقوس والموسيقى والحكايات والذاكرة المحلية.',languages:['Spanish','Quechua'],regions:['Peru']}],characters:[],variants:['ممارسات محلية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  colombia_marimba:{stories:[{title:'Marimba Music and Traditional Chants',summary:'موسيقى وأناشيد تقليدية تحمل الذاكرة والتاريخ والاحتفال في مجتمعات ساحل المحيط الهادئ.',languages:['Spanish','local languages'],regions:['Colombia','Ecuador']}],characters:[],variants:['تقاليد مجتمعية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  argentina_tango:{stories:[{title:'Tango',summary:'تراث أدائي حضري يجمع الموسيقى والرقص والشعر والذاكرة الاجتماعية.',languages:['Spanish'],regions:['Argentina','Uruguay']}],characters:[],variants:['مدارس وأنماط متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  indonesia_noken:{stories:[{title:'Noken',summary:'تقليد مجتمعي يحمل معرفة وصناعة ورموزاً متوارثة لدى مجتمعات بابوا.',languages:['Multiple'],regions:['Indonesia','Papua']}],characters:[],variants:['تقاليد مجتمعية متعددة'],sources:['UNESCO Intangible Cultural Heritage']},
  australia_aboriginal:{stories:[{title:'Australian Aboriginal Story Traditions',summary:'مدخل لفهرسة تقاليد السرد والمعرفة لدى الشعوب الأصلية الأسترالية حسب المجتمع واللغة والمصدر.',languages:['Multiple Indigenous languages'],regions:['Australia']}],characters:[],variants:['تقاليد مئات المجتمعات واللغات'],sources:['AUREN Global Heritage Index']},
  new_zealand_moko:{stories:[{title:'Māori Cultural Story Traditions',summary:'مدخل لفهرسة القصص والرموز والمعرفة الشفوية المرتبطة بالتراث الماوري.',languages:['Māori','English'],regions:['New Zealand']}],characters:[],variants:['تقاليد iwi وhapū متعددة'],sources:['AUREN Global Heritage Index']},
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
