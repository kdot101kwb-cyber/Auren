'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const db = admin.firestore();

const COLLECTIONS = {
  suppliers: 'auren_suppliers',
  businesses: 'auren_businesses',
  opportunities: 'auren_opportunities',
};

function text(value, max = 160) {
  return String(value || '').trim().toLowerCase().slice(0, max);
}

function matches(doc, query) {
  if (!query) return true;
  const d = doc.data() || {};
  return [
    d.name, d.companyName, d.title, d.description, d.category,
    d.product, d.products, d.country, d.countryName, d.iso2, d.iso3,
    d.city, d.region, d.industry, d.tags,
  ].flatMap((v) => Array.isArray(v) ? v : [v])
    .some((v) => text(v, 500).includes(query));
}

function publicDoc(doc, kind) {
  const d = doc.data() || {};
  return {
    id: doc.id,
    kind,
    name: d.name || d.companyName || d.title || doc.id,
    description: d.description || null,
    category: d.category || d.industry || null,
    country: d.country || d.countryName || null,
    iso2: d.iso2 || null,
    iso3: d.iso3 || null,
    city: d.city || null,
    region: d.region || null,
    website: d.website || d.url || null,
    source: d.source || 'auren',
  };
}

async function searchCollection(name, kind, query, limit) {
  try {
    const snap = await db.collection(name).limit(250).get();
    return snap.docs.filter((doc) => matches(doc, query))
      .slice(0, limit)
      .map((doc) => publicDoc(doc, kind));
  } catch (_) {
    return [];
  }
}

exports.aurenOpportunityIntelligence = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');

  const query = text(request.data?.query, 240);
  const iso3 = text(request.data?.iso3, 3).toUpperCase();
  const region = text(request.data?.region, 120);
  const limit = Math.min(Math.max(Number(request.data?.limit) || 10, 1), 25);

  const countrySnap = iso3
    ? await db.collection('auren_global_countries').doc(iso3).get()
    : null;

  const country = countrySnap?.exists ? countrySnap.data() : null;
  const countryDataSnap = iso3
    ? await db.collection('auren_global_data').doc(iso3).get()
    : null;
  const countryData = countryDataSnap?.exists ? countryDataSnap.data() || {} : {};
  const indicators = countryData.indicators || {};

  const [suppliers, businesses, opportunities] = await Promise.all([
    searchCollection(COLLECTIONS.suppliers, 'supplier', query, limit),
    searchCollection(COLLECTIONS.businesses, 'business', query, limit),
    searchCollection(COLLECTIONS.opportunities, 'opportunity', query, limit),
  ]);

  const countryQuery = query || iso3 || region;
  let countryResults = [];
  if (countryQuery) {
    const snap = await db.collection('auren_global_countries').orderBy('name').limit(250).get();
    countryResults = snap.docs.filter((doc) => {
      const d = doc.data() || {};
      return [d.name, d.iso2, d.iso3, d.capitalCity, d.region]
        .some((v) => text(v, 200).includes(text(countryQuery, 200)));
    }).slice(0, limit).map((doc) => ({
      iso2: doc.data()?.iso2 || null,
      iso3: doc.data()?.iso3 || doc.id,
      name: doc.data()?.name || doc.id,
      region: doc.data()?.region || null,
      capitalCity: doc.data()?.capitalCity || null,
    }));
  }

  return {
    status: 'ok',
    query: query || null,
    country: country ? {
      iso2: country.iso2 || null,
      iso3: country.iso3 || iso3,
      name: country.name || null,
      region: country.region || null,
      incomeLevel: country.incomeLevel || null,
      capitalCity: country.capitalCity || null,
      indicators,
    } : null,
    countryMatches: countryResults,
    suppliers,
    businesses,
    opportunities,
    counts: {
      suppliers: suppliers.length,
      businesses: businesses.length,
      opportunities: opportunities.length,
      countries: countryResults.length,
    },
    routing: {
      supplierFinder: 'supplier',
      businessSearch: 'business',
      opportunityRadar: 'opportunity',
      countryIntelligence: 'country',
    },
  };
});
