const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {searchUNESCO} = require('./unesco_heritage_datahub');

exports.searchAurenUNESCOHeritage = onCall(
  {region: 'us-central1', timeoutSeconds: 30, memory: '256MiB'},
  async (request) => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required.');
    const data = request.data || {};
    const query = String(data.query || '').trim().slice(0, 120);
    const country = String(data.country || '').trim().slice(0, 80);
    const year = String(data.year || '').trim().slice(0, 4);
    const list = String(data.list || '').trim().slice(0, 3).toUpperCase();
    const limit = Math.min(Math.max(Number(data.limit || 40), 1), 60);
    try {
      const results = await searchUNESCO({query, country, year, list, limit});
      return {
        results,
        total: results.length,
        source: 'UNESCO Intangible Cultural Heritage DataHub',
        dataset: 'ich001',
        license: 'CC BY-SA 4.0',
        attribution: 'UNESCO',
      };
    } catch (error) {
      console.error('searchAurenUNESCOHeritage failed', error);
      throw new HttpsError('unavailable', 'UNESCO heritage search is temporarily unavailable.');
    }
  }
);
