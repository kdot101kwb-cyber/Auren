const {onCall, HttpsError} = require('firebase-functions/v2/https');

function clean(value, max = 500) {
  return String(value || '').trim().slice(0, max);
}

exports.searchAurenPodcasts = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB'},
  async (request) => {
    const query = clean(request.data?.query, 120);
    const category = clean(request.data?.category, 80);
    const country = clean(request.data?.country || 'US', 8).toUpperCase();

    if (!query && !category) {
      throw new HttpsError('invalid-argument', 'query or category is required.');
    }

    const term = query || category;
    const url =
      'https://itunes.apple.com/search?media=podcast&entity=podcast&limit=25' +
      '&country=' + encodeURIComponent(country) +
      '&term=' + encodeURIComponent(term);

    const response = await fetch(url, {
      headers: {'user-agent': 'AUREN-Podcast-Discovery/1.0'},
    });
    if (!response.ok) {
      throw new HttpsError('unavailable', 'Podcast directory is temporarily unavailable.');
    }

    const data = await response.json();
    const results = Array.isArray(data?.results) ? data.results : [];

    return {
      status: 'ok',
      source: 'Apple Podcasts catalog',
      results: results.map((item) => ({
        id: String(item.collectionId || item.trackId || ''),
        name: clean(item.collectionName || item.trackName, 180),
        artist: clean(item.artistName, 180),
        description: clean(item.description || item.collectionCensoredName, 1000),
        artworkUrl: clean(item.artworkUrl600 || item.artworkUrl100, 1000),
        feedUrl: clean(item.feedUrl, 1000),
        genre: clean(item.primaryGenreName, 100),
        genres: Array.isArray(item.genres) ? item.genres.slice(0, 8).map((x) => clean(x, 80)) : [],
        country: clean(item.country, 80),
        language: clean(item.language, 40),
        url: clean(item.collectionViewUrl || item.trackViewUrl, 1000),
        explicit: Boolean(item.collectionExplicitness === 'explicit'),
      })).filter((item) => item.name),
    };
  },
);


async function fetchPodcastDirectory(term, country) {
  const url =
    'https://itunes.apple.com/search?media=podcast&entity=podcast&limit=25' +
    '&country=' + encodeURIComponent(country) +
    '&term=' + encodeURIComponent(term);
  const response = await fetch(url, {headers: {'user-agent': 'AUREN-Podcast-Discovery/1.0'}});
  if (!response.ok) return [];
  const data = await response.json().catch(() => ({}));
  return Array.isArray(data?.results) ? data.results : [];
}

function normalizePodcastResult(item, country) {
  return {
    id: String(item.collectionId || item.trackId || ''),
    name: clean(item.collectionName || item.trackName, 180),
    artist: clean(item.artistName, 180),
    description: clean(item.description || item.collectionCensoredName, 1000),
    artworkUrl: clean(item.artworkUrl600 || item.artworkUrl100, 1000),
    feedUrl: clean(item.feedUrl, 1000),
    genre: clean(item.primaryGenreName, 100),
    genres: Array.isArray(item.genres) ? item.genres.slice(0, 8).map((x) => clean(x, 80)) : [],
    country: clean(item.country || country, 80),
    language: clean(item.language, 40),
    url: clean(item.collectionViewUrl || item.trackViewUrl, 1000),
    explicit: Boolean(item.collectionExplicitness === 'explicit'),
  };
}

exports.searchAurenPodcastsSmart = onCall(
  {region: 'us-central1', timeoutSeconds: 30, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');

    const query = clean(request.data?.query, 160);
    const category = clean(request.data?.category, 100);
    const requestedCountries = Array.isArray(request.data?.countries)
      ? request.data.countries.map((x) => String(x || '').trim().toUpperCase()).filter((x) => /^[A-Z]{2}$/.test(x)).slice(0, 8))
      : [];
    const countries = requestedCountries.length ? requestedCountries : ['US', 'GB', 'CA', 'AU', 'AE', 'EG', 'SA', 'TR'];

    if (!query && !category) {
      throw new HttpsError('invalid-argument', 'query or category is required.');
    }

    const term = query || category;
    const directoryResults = await Promise.all(
      countries.map((country) => fetchPodcastDirectory(term, country).catch(() => []))
    );

    const tokens = term.toLowerCase().split(/\s+/).map((x) => x.trim()).filter(Boolean).slice(0, 12);
    const seen = new Set();
    const results = [];

    for (let i = 0; i < directoryResults.length; i++) {
      for (const raw of directoryResults[i]) {
        const item = normalizePodcastResult(raw, countries[i]);
        if (!item.name || seen.has(item.id || item.name.toLowerCase())) continue;
        seen.add(item.id || item.name.toLowerCase());

        const haystack = [
          item.name, item.artist, item.description, item.genre, ...(item.genres || []),
          item.country, item.language,
        ].join(' ').toLowerCase();
        let score = 0;
        for (const token of tokens) {
          if (haystack.includes(token)) score += 2;
          if (item.name.toLowerCase().includes(token)) score += 2;
          if (item.genre.toLowerCase().includes(token)) score += 1;
        }
        if (category && item.genre.toLowerCase().includes(category.toLowerCase())) score += 3;
        results.push({...item, smartScore: score});
      }
    }

    results.sort((a, b) => b.smartScore - a.smartScore || a.name.localeCompare(b.name));
    const top = results.slice(0, 30);

    const profileSnap = await db.collection('users').doc(uid).collection('memory')
      .where('enabled', '==', true).limit(20).get().catch(() => null);
    const profileTerms = profileSnap
      ? profileSnap.docs.map((doc) => doc.data()?.value).filter(Boolean).join(' ').toLowerCase().slice(0, 3000)
      : '';

    const recommendations = profileTerms
      ? top.map((item) => {
          const haystack = [item.name, item.description, item.genre, ...(item.genres || [])].join(' ').toLowerCase();
          const matches = profileTerms.split(/\s+/).filter((word) => word.length > 3 && haystack.includes(word)).slice(0, 5);
          return {...item, recommendationScore: item.smartScore + matches.length * 2, matchedInterests: matches};
        }).sort((a, b) => b.recommendationScore - a.recommendationScore).slice(0, 10)
      : top.slice(0, 10);

    return {
      status: 'ok',
      source: 'global podcast discovery',
      query: term,
      countries,
      results: top,
      recommendations,
    };
  }
);
