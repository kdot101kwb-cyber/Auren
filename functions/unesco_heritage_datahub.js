const DATASET = 'ich001';
const API = 'https://data.unesco.org/api/explore/v2.1/catalog/datasets/' + DATASET + '/records';

function clean(value, max = 1200) {
  return String(value || '').replace(/\s+/g, ' ').trim().slice(0, max);
}

async function searchUNESCO({query = '', country = '', year = '', list = '', limit = 40} = {}) {
  const where = [];
  if (query) {
    const q = query.replace(/'/g, "''");
    where.push("(search(title_en, '" + q + "') OR search(description_en, '" + q + "') OR search(concepts_primary_names, '" + q + "') OR search(concepts_secondary_names, '" + q + "'))");
  }
  if (country) where.push("countries like '%" + country.replace(/'/g, "''") + "%'");
  if (year) where.push("inscription_year=" + Number(year));
  if (list) where.push("type_acronym='" + list.replace(/'/g, "''") + "'");
  const params = new URLSearchParams({
    limit: String(Math.min(Math.max(Number(limit) || 40, 1), 100)),
    offset: '0',
  });
  if (where.length) params.set('where', where.join(' AND '));
  const response = await fetch(API + '?' + params.toString(), {
    headers: {'user-agent': 'AUREN/1.0 global-library-index'},
  });
  if (!response.ok) throw new Error('UNESCO DataHub HTTP ' + response.status);
  const data = await response.json();
  return (data.records || []).map((row) => {
    const x = row.fields || {};
    let videos = [];
    let images = [];
    try { videos = JSON.parse(x.videos || '[]'); } catch (_) {}
    try { images = JSON.parse(x.images || '[]'); } catch (_) {}
    return {
      id: 'unesco_ich_' + clean(x.ich_public_ref || x.uuid, 100),
      title: clean(x.title_en || x.title_fr, 240),
      description: clean(x.description_en || x.description_fr, 1800),
      year: String(x.inscription_year || '').slice(0, 4),
      list: clean(x.type_acronym, 20),
      listName: clean(x.type_of_element_en || '', 100),
      countries: clean(x.countries, 300),
      source: 'UNESCO Intangible Cultural Heritage DataHub',
      sourceUrl: clean(x.http_url_en, 2000),
      imageUrl: clean(x.main_image_url, 2000),
      imageCopyright: clean(x.main_image_copyright, 300),
      images: images.slice(0, 10),
      videos: videos.slice(0, 10),
      concepts: clean([x.concepts_primary_names, x.concepts_secondary_names].filter(Boolean).join(', '), 1200),
      externalId: clean(x.ich_public_ref || x.uuid, 100),
    };
  }).filter((x) => x.title);
}

module.exports = {searchUNESCO};
