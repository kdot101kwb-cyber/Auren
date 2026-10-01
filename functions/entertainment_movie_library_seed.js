const {onCall, HttpsError} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const db = admin.firestore();

function clean(value, max = 3000) {
  return String(value || '').replace(/\\s+/g, ' ').trim().slice(0, max);
}

async function getJson(url) {
  const response = await fetch(url, {
    headers: {'user-agent': 'AUREN/1.0 public-domain-movie-library'},
  });
  if (!response.ok) throw new Error('HTTP ' + response.status);
  return response.json();
}

function movieDoc(item) {
  const identifier = clean(item.identifier, 180);
  const title = clean(item.title, 180);
  const year = clean(item.year, 20);
  const description = clean(item.description || 'Public-domain movie catalog entry.', 3000);
  const creator = Array.isArray(item.creator) ? item.creator[0] : clean(item.creator, 200);
  const licenseUrl = clean(item.licenseurl, 1000);
  return {
    id: 'movie_ia_' + identifier.replace(/[^a-zA-Z0-9_-]/g, '_'),
    title: title || identifier,
    type: 'Movie',
    description: creator ? 'By ' + creator + (year ? ' • ' + year : '') + '. ' + description : description,
    imageUrl: 'https://archive.org/services/img/' + encodeURIComponent(identifier),
    mediaUrl: 'https://archive.org/details/' + encodeURIComponent(identifier),
    mediaKind: 'catalog',
    creatorId: 'auren-public-domain',
    channelId: 'auren-public-domain-movies',
    country: '',
    language: '',
    year,
    genres: Array.isArray(item.subject) ? item.subject.slice(0, 8).map((x) => clean(x, 80)) : [],
    seasons: 0,
    episodes: 0,
    trailerUrl: '',
    artistName: creator || '',
    albumName: '',
    visibility: 'public',
    source: 'Internet Archive / Public Domain search',
    sourceUrl: 'https://archive.org/details/' + encodeURIComponent(identifier),
    licenseNote: licenseUrl
      ? 'Catalog entry selected from an Internet Archive public-domain search. Verify the item-level rights and local copyright status before redistribution.'
      : 'Catalog metadata only. Verify item-level rights before redistribution.',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

exports.seedAurenPublicDomainMovies = onCall(
  {region: 'us-central1', timeoutSeconds: 120, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Authentication is required.');
    }

    const marker = db.collection('entertainment_library_meta').doc('public_domain_movies_v1');
    const existing = await marker.get();
    if (existing.exists && existing.data()?.status === 'ready') {
      return {status: 'ready', seeded: false, message: 'Public-domain movie catalog is already populated.'};
    }

    const query = encodeURIComponent(
      'mediatype:movies AND licenseurl:(publicdomain OR public-domain)',
    );
    const url = 'https://archive.org/advancedsearch.php?q=' + query +
      '&fl[]=identifier&fl[]=title&fl[]=description&fl[]=creator&fl[]=year&fl[]=subject&fl[]=licenseurl' +
      '&rows=100&page=1&output=json';

    const response = await getJson(url);
    const docs = (response.response?.docs || [])
      .filter((item) => item.identifier && item.title)
      .slice(0, 100)
      .map(movieDoc);

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
      source: 'Internet Archive / Public Domain search',
    }, {merge: true});

    return {
      status: 'ready',
      seeded: true,
      count: docs.length,
      source: 'Internet Archive / Public Domain search',
    };
  },
);
