'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore} = require('firebase-admin/firestore');

const DATA_SOURCES = Object.freeze([
  {
    id: 'world_bank_wdi',
    name: 'World Bank World Development Indicators',
    category: 'global_country_intelligence',
    endpoint: 'https://api.worldbank.org/v2/',
    access: 'public_api',
    integrationStatus: 'implemented',
    dataKinds: [
      'country_registry', 'population', 'demographics', 'health', 'gdp',
      'inflation', 'employment', 'imports', 'exports', 'foreign_direct_investment',
      'internet_access', 'electricity_access', 'agriculture', 'environment'
    ],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Provides country-level indicators where published; availability and reporting years vary by country and indicator. Not a company directory or a guarantee of complete coverage.',
  },
  {
    id: 'un_comtrade',
    name: 'UN Comtrade',
    category: 'trade_statistics',
    endpoint: 'https://comtradeapi.un.org/',
    access: 'public_api',
    integrationStatus: 'implemented',
    dataKinds: ['aggregate_import_export_statistics'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Aggregate trade statistics only; does not identify individual companies or prove a supplier relationship.',
  },
  {
    id: 'faostat',
    name: 'FAOSTAT',
    category: 'agriculture',
    endpoint: 'https://www.fao.org/faostat/',
    access: 'public_api',
    integrationStatus: 'implemented',
    dataKinds: ['agriculture', 'production', 'food_balances', 'prices', 'land_use'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Country/domain integration exists; endpoint and availability must be checked before scheduled production ingestion.',
  },
  {
    id: 'licensed_business_records',
    name: 'Licensed business records',
    category: 'business_directory',
    endpoint: null,
    access: 'admin_import',
    integrationStatus: 'implemented',
    dataKinds: ['supplier', 'exporter', 'importer', 'manufacturer'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Admin import accepts records only with HTTPS provenance and an explicit licence; imported businesses remain unverified.',
  },
  {
    id: 'ted_europe',
    name: 'Tenders Electronic Daily (TED)',
    category: 'tenders',
    endpoint: 'https://api.ted.europa.eu/',
    access: 'public_api',
    integrationStatus: 'catalog_only',
    dataKinds: ['public_procurement_notices'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Catalogued for implementation; no tender records are shown until a tested API adapter is deployed.',
  },
  {
    id: 'ungm',
    name: 'UN Global Marketplace',
    category: 'tenders',
    endpoint: 'https://www.ungm.org/',
    access: 'provider_access',
    integrationStatus: 'catalog_only',
    dataKinds: ['un_procurement_opportunities'],
    requiresCredentials: 'check_provider_terms',
    licenseReviewRequired: true,
    notes: 'Requires confirmation of permitted API/feed access and reuse terms before automated ingestion.',
  },
  {
    id: 'world_bank_wits',
    name: 'World Bank WITS',
    category: 'trade_intelligence',
    endpoint: 'https://wits.worldbank.org/',
    access: 'public_data_service',
    integrationStatus: 'catalog_only',
    dataKinds: ['trade_flows', 'tariffs'],
    requiresCredentials: 'check_current_api_access',
    licenseReviewRequired: true,
    notes: 'Potential source for trade and tariff indicators; not a company lead database.',
  },
  {
    id: 'opencorporates',
    name: 'OpenCorporates',
    category: 'business_registry',
    endpoint: 'https://api.opencorporates.com/',
    access: 'api_key_or_plan',
    integrationStatus: 'catalog_only',
    dataKinds: ['company_registry_records'],
    requiresCredentials: true,
    licenseReviewRequired: true,
    notes: 'Commercial display, caching, and redistribution rights must be confirmed for the selected plan.',
  },
  {
    id: 'grants_gov',
    name: 'Grants.gov',
    category: 'funding',
    endpoint: 'https://www.grants.gov/',
    access: 'public_api',
    integrationStatus: 'catalog_only',
    dataKinds: ['us_federal_grants'],
    requiresCredentials: 'verify_current_api_terms',
    licenseReviewRequired: true,
    notes: 'US-focused source; it does not represent all global grants and eligibility must be checked per notice.',
  },
]);

function getDataSourceCatalog() {
  return DATA_SOURCES.map((source) => ({...source}));
}

function sourceIdForRun(run) {
  const explicit = String(run.sourceId || run.sourceKey || '').trim();
  if (explicit) return explicit;
  const source = String(run.source || '').trim().toLowerCase();
  const aliases = {
    'un comtrade': 'un_comtrade',
    'faostat': 'faostat',
    'licensed_business_record_import': 'licensed_business_records',
  };
  return aliases[source] || '';
}

function summarizeReadiness(catalog, runs) {
  const latestBySource = new Map();
  for (const run of runs) {
    const key = sourceIdForRun(run);
    if (!key || latestBySource.has(key)) continue;
    latestBySource.set(key, {
      status: String(run.status || 'unknown'),
      completedAt: run.completedAt || null,
      importedRows: Number.isFinite(Number(run.importedRows)) ? Number(run.importedRows) : 0,
      rejectedRows: Number.isFinite(Number(run.rejectedRows)) ? Number(run.rejectedRows) : 0,
    });
  }
  return catalog.map((source) => ({
    ...source,
    latestIngestion: latestBySource.get(source.id) || null,
    dataReady: source.integrationStatus === 'implemented' &&
      latestBySource.get(source.id)?.status === 'completed',
  }));
}

exports.aurenDataSourceCatalog = onCall({region: 'us-central1', timeoutSeconds: 30, memory: '128MiB'}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in to view AUREN data sources.');
  }
  return {
    status: 'ok',
    sources: getDataSourceCatalog(),
    count: DATA_SOURCES.length,
    note: 'Catalog entries are not claims that live data is already loaded. Each source exposes its integration status and data readiness separately.',
  };
});

exports.aurenDataSourceReadiness = onCall({region: 'us-central1', timeoutSeconds: 30, memory: '128MiB'}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in to view AUREN data readiness.');
  }
  const db = getFirestore();
  const snapshot = await db.collection('auren_data_ingestion_runs')
    .orderBy('completedAt', 'desc')
    .limit(100)
    .get();
  const runs = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
  return {
    status: 'ok',
    sources: summarizeReadiness(DATA_SOURCES, runs),
    checkedAt: new Date().toISOString(),
    note: 'A source is dataReady only when its integration is implemented and an ingestion run keyed to its sourceId exists. This is not a verification of the underlying businesses or opportunities.',
  };
});

module.exports.getDataSourceCatalog = getDataSourceCatalog;
module.exports.summarizeReadiness = summarizeReadiness;
