const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {searchUNESCO} = require('./unesco_heritage_datahub');

const WORLD_API = 'https://data.unesco.org/api/explore/v2.1/catalog/datasets/whc001/records';
const clean = (v, max=5000) => String(v ?? '').replace(/\s+/g, ' ').trim().slice(0, max);
const arr = (v) => Array.isArray(v) ? v.map(x => clean(x)).filter(Boolean)
  : typeof v === 'string' ? v.split(/[;,|]/).map(x => clean(x)).filter(Boolean) : [];

async function getJson(url) {
  const r = await fetch(url, {headers: {accept: 'application/json', 'user-agent': 'AUREN/1.0'}});
  if (!r.ok) throw new Error('UNESCO API ' + r.status);
  return r.json();
}

function mapWorld(record) {
  const r = record?.record?.fields || record?.fields || record || {};
  const title = clean(r.name_en || r.name_ar || r.name_fr || r.name_es);
  if (!title) return null;
  return {
    id: 'world_' + clean(r.id_no || r.uuid, 120),
    title,
    titleAr: clean(r.name_ar, 500),
    description: clean(r.short_description_en || r.description_en || r.short_description_ar, 4000),
    year: clean(r.date_inscribed, 50),
    category: clean(r.category, 100),
    danger: Boolean(r.danger),
    dangerList: clean(r.danger_list, 1000),
    countries: arr(r.states_names),
    isoCodes: arr(r.iso_codes),
    region: clean(r.region, 200),
    coordinates: clean(r.coordinates, 200),
    criteria: clean(r.criteria_txt || r.cultural_criteria || r.natural_criteria, 500),
    transboundary: Boolean(r.transboundary),
    areaHectares: r.area_hectares ?? null,
    imageUrl: clean(r.main_image_url, 1000),
    imageAuthor: clean(r.main_image_author, 300),
    imageCopyright: clean(r.main_image_copyright, 500),
    images: arr(r.images_urls),
    videoUrl: clean(r.main_video_url, 1000),
    videos: arr(r.videos_urls),
    source: 'UNESCO World Heritage Centre',
    sourceUrl: 'https://whc.unesco.org/en/list/' + clean(r.id_no, 30),
    license: 'CC BY-SA 4.0',
    externalId: clean(r.id_no || r.uuid, 120),
    heritageScope: 'World Heritage List',
  };
}

async function searchWorld({query='', country='', region='', year='', category='', limit=40}) {
  const where = [];
  if (query) where.push('search(name_en, ' + JSON.stringify(clean(query, 200)) + ')');
  if (country) where.push('states_names like ' + JSON.stringify('%' + clean(country, 100) + '%'));
  if (region) where.push('region = ' + JSON.stringify(clean(region, 100)));
  if (year && /^\d{4}$/.test(String(year))) where.push('date_inscribed = ' + String(year));
  if (category) where.push('category = ' + JSON.stringify(clean(category, 100)));
  const p = new URLSearchParams({
    limit: String(Math.min(Math.max(Number(limit) || 40, 1), 100)),
    offset: '0',
  });
  if (where.length) p.set('where', where.join(' AND '));
  const data = await getJson(WORLD_API + '?' + p.toString());
  return (data.results || []).map(mapWorld).filter(Boolean);
}

exports.searchAurenUNESCOHeritage = onCall(
  {region: 'us-central1', timeoutSeconds: 30, memory: '256MiB'},
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
    const data = request.data || {};
    const query = clean(data.query, 120);
    const country = clean(data.country, 80);
    const region = clean(data.region, 80);
    const year = clean(data.year, 4);
    const list = clean(data.list, 3).toUpperCase();
    const category = clean(data.category, 80);
    const limit = Math.min(Math.max(Number(data.limit || 40), 1), 60);
    try {
      const [intangible, world] = await Promise.all([
        searchUNESCO({query, country, year, list, limit}),
        searchWorld({query, country, region, year, category, limit}),
      ]);
      const all = [
        ...intangible.map(x => ({...x, heritageScope: 'Intangible Cultural Heritage'})),
        ...world,
      ];
      const seen = new Set();
      const results = all.filter(x => {
        const key = String(x.title || '').toLowerCase() + '|' + String(x.source || '');
        if (seen.has(key)) return false;
        seen.add(key);
        return true;
      }).slice(0, 100);
      return {
        results,
        total: results.length,
        intangibleCount: intangible.length,
        worldCount: world.length,
        sources: [
          'UNESCO Intangible Cultural Heritage DataHub',
          'UNESCO World Heritage Centre / DataHub',
        ],
        datasets: ['ich001', 'whc001'],
        license: 'CC BY-SA 4.0',
        attribution: 'UNESCO',
        updatedAt: new Date().toISOString(),
      };
    } catch (error) {
      console.error('searchAurenUNESCOHeritage failed', error);
      throw new HttpsError('unavailable', 'UNESCO heritage search is temporarily unavailable.');
    }
  }
);
