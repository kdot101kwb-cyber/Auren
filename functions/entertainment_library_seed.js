const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const db = admin.firestore();

async function getJson(url) {
  const response = await fetch(url, {headers: {'user-agent': 'AUREN/1.0 entertainment-library'}});
  if (!response.ok) throw new Error('HTTP ' + response.status + ' from ' + url);
  return response.json();
}

function clean(value, max = 3000) {
  return String(value || '').replace(/\\s+/g, ' ').trim().slice(0, max);
}

function bookDoc(book) {
  const id = 'book_gutenberg_' + String(book.id);
  const formats = book.formats || {};
  const html = formats['text/html; charset=utf-8'] || formats['text/html'] || '';
  const cover = formats['image/jpeg'] || '';
  const author = Array.isArray(book.authors) && book.authors[0] ? book.authors[0].name : '';
  const subjects = Array.isArray(book.subjects) ? book.subjects.slice(0, 6).map(clean) : [];
  return {
    id,
    title: clean(book.title, 160),
    type: 'Book',
    description: clean(author ? 'By ' + author + '. ' + subjects.join(' • ') : subjects.join(' • '), 3000),
    imageUrl: clean(cover, 2000),
    mediaUrl: clean(html || ('https://www.gutenberg.org/ebooks/' + book.id), 2000),
    mediaKind: 'book',
    creatorId: 'auren-library',
    channelId: 'auren-library',
    country: '',
    language: Array.isArray(book.languages) && book.languages[0] ? book.languages[0] : 'en',
    year: '',
    genres: subjects,
    seasons: 0,
    episodes: 0,
    trailerUrl: '',
    artistName: '',
    albumName: '',
    visibility: 'public',
    source: 'Project Gutenberg / Gutendex',
    sourceUrl: 'https://www.gutenberg.org/ebooks/' + book.id,
    licenseNote: 'Catalog metadata for a public-domain/openly distributed ebook; verify local copyright status before redistribution.',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

function mangaDoc(manga) {
  const id = 'manga_mal_' + String(manga.mal_id);
  const genres = Array.isArray(manga.genres) ? manga.genres.slice(0, 8).map((g) => clean(g?.name, 80)) : [];
  const image = manga.images?.jpg?.large_image_url || manga.images?.jpg?.image_url || '';
  return {id,title:clean(manga.title,160),type:'Manga',description:clean(manga.synopsis || 'Manga catalog entry.',3000),imageUrl:clean(image,2000),mediaUrl:'https://myanimelist.net/manga/' + manga.mal_id,mediaKind:'catalog',creatorId:'auren-library',channelId:'auren-library',country:'Japan',language:'ja',year:manga.published?.from ? String(new Date(manga.published.from).getFullYear()) : '',genres,seasons:0,episodes:0,trailerUrl:'',artistName:'',albumName:'',visibility:'public',source:'Jikan / MyAnimeList',sourceUrl:'https://myanimelist.net/manga/' + manga.mal_id,licenseNote:'Metadata/catalog entry only; AUREN does not host copyrighted manga scans.',createdAt:admin.firestore.FieldValue.serverTimestamp(),updatedAt:admin.firestore.FieldValue.serverTimestamp()};
}

function animeDoc(anime) {
  const id = 'anime_mal_' + String(anime.mal_id);
  const genres = Array.isArray(anime.genres) ? anime.genres.slice(0, 8).map((g) => clean(g?.name, 80)) : [];
  const image = anime.images?.jpg?.large_image_url || anime.images?.jpg?.image_url || '';
  const title = anime.title || anime.title_english || anime.title_japanese || 'Anime';
  return {
    id,
    title: clean(title, 160),
    type: 'Anime',
    description: clean(anime.synopsis || 'Anime catalog entry.', 3000),
    imageUrl: clean(image, 2000),
    mediaUrl: 'https://myanimelist.net/anime/' + anime.mal_id,
    mediaKind: 'catalog',
    creatorId: 'auren-library',
    channelId: 'auren-library',
    country: 'Japan',
    language: 'ja',
    year: anime.year ? String(anime.year) : '',
    genres,
    seasons: 0,
    episodes: Number(anime.episodes || 0),
    trailerUrl: anime.trailer?.url || '',
    artistName: '',
    albumName: '',
    visibility: 'public',
    source: 'Jikan / MyAnimeList',
    sourceUrl: 'https://myanimelist.net/anime/' + anime.mal_id,
    licenseNote: 'Metadata/catalog entry only; AUREN does not host copyrighted episodes.',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}



function journalDoc(journal, source) {
  const issn = journal.ISSN || journal.issn || '';
  const id = source + '_journal_' + String(issn || journal.id || journal.display_name || journal.title || 'unknown').replace(/[^a-zA-Z0-9]+/g, '_').slice(0, 100);
  const title = journal.title || journal.display_name || journal.name || 'Journal';
  const host = journal.publisher || journal.host_organization_name || '';
  return {
    id,
    title: clean(title, 160),
    type: 'Journal',
    description: clean(host ? 'Journal / periodical. Publisher: ' + host : 'Journal / periodical catalog entry.', 3000),
    imageUrl: '',
    mediaUrl: clean(journal.url || journal.homepage_url || ('https://api.crossref.org/journals/' + issn), 2000),
    mediaKind: 'catalog',
    creatorId: 'auren-library',
    channelId: 'auren-library',
    country: clean(journal.country || journal.country_code || '', 80),
    language: '',
    year: '',
    genres: ['Journal', 'Periodical'],
    seasons: 0,
    episodes: 0,
    trailerUrl: '',
    artistName: '',
    albumName: '',
    visibility: 'public',
    source: source,
    sourceUrl: clean(journal.url || journal.homepage_url || '', 2000),
    issn: clean(issn, 80),
    licenseNote: 'Metadata/catalog entry only; AUREN does not host copyrighted journal or magazine issues.',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

exports.seedAurenEntertainmentLibrary = onCall(
  {region: 'us-central1', timeoutSeconds: 120, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Authentication is required.');

    const marker = db.collection('entertainment_library_meta').doc('global_v2');
    const existing = await marker.get();
    if (existing.exists && existing.data()?.status === 'ready') {
      return {status: 'ready', seeded: false, message: 'AUREN Entertainment Library is already populated.'};
    }

    const [books, anime, manga, crossref, openalex] = await Promise.all([
      getJson('https://gutendex.com/books?languages=en&copyright=false&sort=popular&page=1'),
      getJson('https://api.jikan.moe/v4/top/anime?limit=25'),
      getJson('https://api.jikan.moe/v4/top/manga?limit=25'),
      getJson('https://api.crossref.org/journals?rows=100'),
      getJson('https://api.openalex.org/sources?filter=type:journal&sort=-works_count&per-page=100'),
    ]);

    const docs = [
      ...(books.results || []).slice(0, 40).map(bookDoc),
      ...(anime.data || []).slice(0, 25).map(animeDoc),
      ...(manga.data || []).slice(0, 25).map(mangaDoc),
      ...((crossref.message && crossref.message.items) || []).slice(0, 100).map((x) => journalDoc(x, 'Crossref')),
      ...((openalex.results) || []).slice(0, 100).map((x) => journalDoc(x, 'OpenAlex')),
    ];

    const batchSize = 400;
    for (let i = 0; i < docs.length; i += batchSize) {
      const batch = db.batch();
      docs.slice(i, i + batchSize).forEach((item) => {
        const {id, ...data} = item;
        batch.set(db.collection('entertainment_items').doc(id), data, {merge: true});
      });
      await batch.commit();
    }

    await marker.set({
      status: 'ready',
      books: Math.min((books.results || []).length, 40),
      anime: Math.min((anime.data || []).length, 25),
      total: docs.length,
      seededBy: request.auth.uid,
      seededAt: admin.firestore.FieldValue.serverTimestamp(),
      sources: ['Gutendex / Project Gutenberg', 'Jikan / MyAnimeList', 'Crossref', 'OpenAlex'],
    }, {merge: true});

    return {status: 'ready', seeded: true, books: Math.min((books.results || []).length, 40), anime: Math.min((anime.data || []).length, 25), manga: Math.min((manga.data || []).length, 25), journals: Math.min(((crossref.message && crossref.message.items) || []).length, 100) + Math.min((openalex.results || []).length, 100), total: docs.length};
  },
);
