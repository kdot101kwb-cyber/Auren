'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore} = require('firebase-admin/firestore');

const BUSINESS_COLLECTIONS = Object.freeze({
  supplier: 'auren_suppliers',
  exporter: 'auren_exporters',
  importer: 'auren_importers',
  manufacturer: 'auren_manufacturers',
});
const SCAN_LIMIT_PER_COLLECTION = 100;
const MAX_RESULTS = 50;

function normalizeInput(input = {}) {
  const query = typeof input.query === 'string' ? input.query.trim().replace(/\s+/g, ' ') : '';
  const countryCode = typeof input.countryCode === 'string' ? input.countryCode.trim().toUpperCase() : '';
  const businessType = typeof input.businessType === 'string' ? input.businessType.trim().toLowerCase() : '';
  const limitValue = Number(input.limit ?? 20);
  const limit = Number.isFinite(limitValue) ? Math.max(1, Math.min(MAX_RESULTS, Math.floor(limitValue))) : 20;
  if (query.length > 100) throw new HttpsError('invalid-argument', 'query must be 100 characters or fewer.');
  if (countryCode && !/^[A-Z]{2}$/.test(countryCode)) {
    throw new HttpsError('invalid-argument', 'countryCode must be a two-letter ISO country code.');
  }
  if (businessType && !Object.hasOwn(BUSINESS_COLLECTIONS, businessType)) {
    throw new HttpsError('invalid-argument', 'businessType must be supplier, exporter, importer, or manufacturer.');
  }
  return {query: query.toLocaleLowerCase(), countryCode, businessType, limit};
}

function normalizeBusinessHit(doc, businessType) {
  const data = doc.data() || {};
  const name = String(data.name || data.companyName || '').trim();
  if (!name) return null;
  return {
    id: doc.id,
    name,
    businessType: String(data.businessType || businessType).toLowerCase(),
    countryCode: String(data.countryCode || '').trim().toUpperCase() || null,
    city: String(data.city || '').trim() || null,
    products: Array.isArray(data.products) ? data.products.filter((item) => typeof item === 'string').slice(0, 30) : [],
    website: String(data.website || '').trim() || null,
    publicEmail: String(data.publicEmail || '').trim() || null,
    publicPhone: String(data.publicPhone || '').trim() || null,
    source: String(data.source || '').trim() || null,
    sourceUrl: String(data.sourceUrl || '').trim() || null,
    sourceLicense: String(data.sourceLicense || '').trim() || null,
    provenanceStatus: String(data.provenanceStatus || 'unknown'),
    verificationStatus: String(data.verificationStatus || 'unverified'),
    lastCheckedAt: data.lastCheckedAt?.toDate?.()?.toISOString?.() || null,
  };
}

async function searchGlobalBusinessDirectory(input, db = getFirestore()) {
  const filters = normalizeInput(input);
  const types = filters.businessType
    ? [filters.businessType]
    : Object.keys(BUSINESS_COLLECTIONS);

  const snapshots = await Promise.all(types.map(async (type) => {
    let query = db.collection(BUSINESS_COLLECTIONS[type]);
    if (filters.countryCode) query = query.where('countryCode', '==', filters.countryCode);
    const snapshot = await query.limit(SCAN_LIMIT_PER_COLLECTION).get();
    return snapshot.docs.map((doc) => normalizeBusinessHit(doc, type)).filter(Boolean);
  }));

  const scanned = snapshots.flat();
  const matches = scanned.filter((record) => {
    if (!filters.query) return true;
    const haystack = [
      record.name, record.businessType, record.countryCode, record.city,
      ...record.products,
    ].filter(Boolean).join(' ').toLocaleLowerCase();
    return haystack.includes(filters.query);
  });

  matches.sort((a, b) => a.name.localeCompare(b.name));
  return {
    status: 'ok',
    scope: filters.countryCode ? 'country' : 'global',
    filters: {
      query: filters.query || null,
      countryCode: filters.countryCode || null,
      businessType: filters.businessType || null,
    },
    count: Math.min(matches.length, filters.limit),
    results: matches.slice(0, filters.limit),
    sourceCollections: types.map((type) => BUSINESS_COLLECTIONS[type]),
    scannedRecords: scanned.length,
    scanLimitPerCollection: SCAN_LIMIT_PER_COLLECTION,
    source: 'AUREN licensed business-record imports',
    retrievedAt: new Date().toISOString(),
    coverageNote: 'This search returns only business records already ingested into AUREN from sources with declared provenance/licensing. It is not a complete global company directory. Results are not independently verified unless the record explicitly says so. Search is bounded to the first 100 records per selected collection; broad queries may omit matches beyond that scan window.',
  };
}

exports.aurenSearchGlobalBusinessDirectory = onCall(
  {region: 'us-central1', timeoutSeconds: 30, memory: '256MiB'},
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError('unauthenticated', 'Sign in to search AUREN global business records.');
    }
    return searchGlobalBusinessDirectory(request.data || {});
  },
);

module.exports.BUSINESS_COLLECTIONS = BUSINESS_COLLECTIONS;
module.exports.normalizeInput = normalizeInput;
module.exports.normalizeBusinessHit = normalizeBusinessHit;
module.exports.searchGlobalBusinessDirectory = searchGlobalBusinessDirectory;
