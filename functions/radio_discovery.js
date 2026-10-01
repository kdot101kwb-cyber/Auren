const {onCall, HttpsError} = require('firebase-functions/v2/https');

function clean(value, max = 500) {
  return String(value || '').replace(/<[^>]*>/g, ' ').replace(/\\s+/g, ' ').trim().slice(0, max);
}

exports.searchAurenRadio = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Authentication is required.');
    }

    const query = clean(request.data?.query, 120);
    const countryCode = clean(request.data?.countryCode, 2).toUpperCase();
    const tag = clean(request.data?.tag, 80);
    const limit = Math.min(Math.max(Number(request.data?.limit) || 20, 1), 50);

    const params = new URLSearchParams();
    if (query) params.set('name', query);
    if (countryCode) params.set('countrycode', countryCode);
    if (tag) params.set('tag', tag);
    params.set('hidebroken', 'true');
    params.set('order', 'clickcount');
    params.set('reverse', 'true');
    params.set('limit', String(limit));

    const endpoint = 'https://de1.api.radio-browser.info/json/stations/search?' + params.toString();
    let response;
    try {
      response = await fetch(endpoint, {
        headers: {
          'user-agent': 'AUREN-Radio/1.0',
          'accept': 'application/json',
        },
      });
    } catch (_) {
      throw new HttpsError('unavailable', 'Radio directory is temporarily unavailable.');
    }

    if (!response.ok) {
      throw new HttpsError('unavailable', 'Radio directory is temporarily unavailable.');
    }

    const data = await response.json();
    const results = Array.isArray(data) ? data : [];

    return {
      status: 'ok',
      source: 'Radio Browser',
      results: results.map((station) => ({
        stationUuid: clean(station.stationuuid, 120),
        name: clean(station.name, 180) || 'Radio',
        country: clean(station.country, 100),
        countryCode: clean(station.countrycode, 2),
        language: clean(station.language, 80),
        tags: clean(station.tags, 240),
        favicon: clean(station.favicon, 1000),
        homepage: clean(station.homepage, 1000),
        streamUrl: clean(station.url_resolved || station.url, 2000),
        codec: clean(station.codec, 40),
        bitrate: Number(station.bitrate || 0),
        votes: Number(station.votes || 0),
        clickCount: Number(station.clickcount || 0),
        lastCheckOk: Boolean(station.lastcheckok),
      })).filter((station) => station.stationUuid && station.streamUrl),
    };
  },
);
