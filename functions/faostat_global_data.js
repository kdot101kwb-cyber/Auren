'use strict';

const {onCall} = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const FAOSTAT_API_BASE = process.env.FAOSTAT_API_BASE || 'https://faostat-app-lb.fao.org/api/v1';
const DOMAINS = {
  crops_livestock: 'QCL',
  land_use: 'RL',
  trade: 'TCL',
  food_balances: 'FB',
  prices: 'PP',
  fertilizers: 'RF'
};

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function getJson(url, attempts = 3) {
  let lastError;
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      const res = await fetch(url, {
        headers: {accept:'application/json'},
        signal: AbortSignal.timeout(30000)
      });
      if (!res.ok) {
        const body = await res.text().catch(() => '');
        throw new Error('FAOSTAT request failed: ' + res.status + (body ? ' ' + body.slice(0, 200) : ''));
      }
      return await res.json();
    } catch (e) {
      lastError = e;
      if (attempt < attempts) await sleep(500 * Math.pow(2, attempt - 1));
    }
  }
  throw lastError;
}

function buildDataUrl(domain, iso3, page = 1, pageSize = 1000) {
  const params = new URLSearchParams({
    area_code: iso3,
    page: String(page),
    page_size: String(Math.min(Math.max(pageSize, 1), 1000))
  });
  return FAOSTAT_API_BASE + '/data/' + domain + '?' + params.toString();
}

function extractRows(payload) {
  if (Array.isArray(payload)) return payload;
  return payload?.data || payload?.items || payload?.results || [];
}

function hasNextPage(payload, page, rowCount, pageSize) {
  if (payload?.next) return true;
  if (payload?.next_page) return true;
  if (payload?.pagination?.next) return true;
  if (Number(payload?.total_pages) > page) return true;
  if (Number(payload?.total) > page * pageSize) return true;
  return rowCount >= pageSize;
}

async function fetchCountryDomain(iso3, domainKey, options = {}) {
  const domain = DOMAINS[domainKey];
  if (!domain) throw new Error('Unsupported FAOSTAT domain.');
  const pageSize = Math.min(Math.max(Number(options.pageSize) || 1000, 1), 1000);
  const maxPages = Math.min(Math.max(Number(options.maxPages) || 100, 1), 100);
  const rows = [];
  let page = 1;
  let lastPayload = null;

  while (page <= maxPages) {
    const payload = await getJson(buildDataUrl(domain, iso3, page, pageSize));
    lastPayload = payload;
    const pageRows = extractRows(payload);
    rows.push(...pageRows);
    if (!hasNextPage(payload, page, pageRows.length, pageSize)) break;
    page++;
  }

  return {
    data: rows,
    pagesFetched: page,
    pageSize,
    truncated: page > maxPages,
    raw: lastPayload
  };
}

exports.aurenFaostatCatalog = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  return {
    status:'ok',
    source:'FAOSTAT',
    apiBase:FAOSTAT_API_BASE,
    domains:DOMAINS,
    coverage:'245+ countries and territories; availability varies by domain and country',
    note:'API base is configurable with FAOSTAT_API_BASE so the deployed project can track the current official FAOSTAT Developer Portal endpoint.'
  };
});

exports.aurenFaostatCountryData = onCall(async (request) => {
  if (!request.auth?.uid) throw new Error('Authentication is required.');
  const iso3 = String(request.data?.iso3 || '').trim().toUpperCase();
  const domainKey = String(request.data?.domain || 'crops_livestock').trim();
  if (!/^[A-Z]{3}$/.test(iso3)) throw new Error('iso3 is required.');
  if (!DOMAINS[domainKey]) throw new Error('Unsupported FAOSTAT domain.');

  const result = await fetchCountryDomain(iso3, domainKey, {
    pageSize: request.data?.pageSize,
    maxPages: request.data?.maxPages
  });

  await db.collection('auren_faostat').doc(iso3 + '_' + DOMAINS[domainKey]).set({
    iso3,
    domain:domainKey,
    domainCode:DOMAINS[domainKey],
    data:result.data,
    pagesFetched:result.pagesFetched,
    pageSize:result.pageSize,
    truncated:result.truncated,
    source:'FAOSTAT',
    apiBase:FAOSTAT_API_BASE,
    updatedAt:admin.firestore.FieldValue.serverTimestamp()
  }, {merge:true});

  return {
    status:'ok',
    iso3,
    domain:domainKey,
    rows:result.data.length,
    pagesFetched:result.pagesFetched,
    truncated:result.truncated,
    stored:true
  };
});

exports.fetchFaostatCountryDomain = fetchCountryDomain;
