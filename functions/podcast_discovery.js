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
