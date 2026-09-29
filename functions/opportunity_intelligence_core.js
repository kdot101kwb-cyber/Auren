'use strict';

const admin = require('firebase-admin');

const db = admin.firestore();

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

async function runOpportunityIntelligence({query = '', iso3 = '', region = '', limit = 10} = {}) {
  const normalizedQuery = text(query, 240);
  const normalizedIso3 = text(iso3, 3).toUpperCase();
  const normalizedRegion = text(region, 120);
  const boundedLimit = Math.min(Math.max(Number(limit) || 10, 1), 25);

  const countrySnap = normalizedIso3
    ? await db.collection('auren_global_countries').doc(normalizedIso3).get()
    : null;
  const country = countrySnap?.exists ? countrySnap.data() : null;

  const countryDataSnap = normalizedIso3
    ? await db.collection('auren_global_data').doc(normalizedIso3).get()
    : null;
  const countryData = countryDataSnap?.exists ? countryDataSnap.data() || {} : {};
  const indicators = countryData.indicators || {};

  const [suppliers, businesses, opportunities] = await Promise.all([
    searchCollection('auren_suppliers', 'supplier', normalizedQuery, boundedLimit),
    searchCollection('auren_businesses', 'business', normalizedQuery, boundedLimit),
    searchCollection('auren_opportunities', 'opportunity', normalizedQuery, boundedLimit),
  ]);

  const countryQuery = normalizedQuery || normalizedIso3 || normalizedRegion;
  let countryMatches = [];
  if (countryQuery) {
    try {
      const snap = await db.collection('auren_global_countries').orderBy('name').limit(250).get();
      countryMatches = snap.docs.filter((doc) => {
        const d = doc.data() || {};
        return [d.name, d.iso2, d.iso3, d.capitalCity, d.region]
          .some((v) => text(v, 200).includes(text(countryQuery, 200)));
      }).slice(0, boundedLimit).map((doc) => ({
        iso2: doc.data()?.iso2 || null,
        iso3: doc.data()?.iso3 || doc.id,
        name: doc.data()?.name || doc.id,
        region: doc.data()?.region || null,
        capitalCity: doc.data()?.capitalCity || null,
      }));
    } catch (_) {}
  }

  return {
    status: 'ok',
    query: normalizedQuery || null,
    country: country ? {
      iso2: country.iso2 || null,
      iso3: country.iso3 || normalizedIso3,
      name: country.name || null,
      region: country.region || null,
      incomeLevel: country.incomeLevel || null,
      capitalCity: country.capitalCity || null,
      indicators,
    } : null,
    countryMatches,
    suppliers,
    businesses,
    opportunities,
    counts: {
      suppliers: suppliers.length,
      businesses: businesses.length,
      opportunities: opportunities.length,
      countries: countryMatches.length,
    },
  };
}

module.exports = {runOpportunityIntelligence};
