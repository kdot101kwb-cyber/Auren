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
  {
    id: 'world_bank_financial_sector',
    name: 'World Bank Financial Sector data',
    category: 'banking_and_finance',
    endpoint: 'https://api.worldbank.org/v2/',
    access: 'public_api',
    integrationStatus: 'catalog_only',
    dataKinds: ['financial_sector_indicators', 'domestic_credit', 'banking_access'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Country-level financial indicators only; not a directory of individual banks or a real-time account service.',
  },
  {
    id: 'imf_data',
    name: 'International Monetary Fund data',
    category: 'banking_and_finance',
    endpoint: 'https://www.imf.org/en/Data',
    access: 'public_data_service',
    integrationStatus: 'catalog_only',
    dataKinds: ['macroeconomic_indicators', 'exchange_rates', 'financial_statistics'],
    requiresCredentials: 'check_dataset_access',
    licenseReviewRequired: true,
    notes: 'Dataset-specific access and reuse terms must be checked; values may differ by release date.',
  },
  {
    id: 'bis_statistics',
    name: 'Bank for International Settlements statistics',
    category: 'banking_and_finance',
    endpoint: 'https://www.bis.org/statistics/',
    access: 'public_data_service',
    integrationStatus: 'catalog_only',
    dataKinds: ['global_banking_statistics', 'credit', 'exchange_rates', 'debt_securities'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Primarily aggregated banking and financial statistics, not a list of consumer bank accounts or offers.',
  },
  {
    id: 'central_bank_directories',
    name: 'National central banks and financial regulators',
    category: 'bank_directory',
    endpoint: null,
    access: 'official_registry_links',
    integrationStatus: 'catalog_only',
    dataKinds: ['central_banks', 'licensed_banks', 'financial_regulators', 'official_license_status'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Country-by-country official-source adapters are required. A listed institution must not be called licensed until its regulator record is checked.',
  },
  {
    id: 'regional_local_bank_directories',
    name: 'Regional and Local Banking Institutions',
    category: 'central_bank_directories',
    endpoint: null,
    access: 'official_source_ingestion',
    integrationStatus: 'implemented',
    dataKinds: ['regional_banks', 'local_commercial_banks', 'microfinance', 'cooperatives', 'islamic_banks', 'regulator_links', 'licence_status'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Search endpoint reads only records ingested with source provenance. Populate country-by-country from official central banks and banking regulators; an empty result is not proof that no bank exists.',
  },
  {
    id: 'grants_gov_opportunities',
    name: 'Grants.gov Federal Funding Opportunities',
    category: 'grant_and_prize_programs',
    endpoint: 'https://api.grants.gov/v1/api/search2',
    access: 'public_api',
    integrationStatus: 'implemented',
    dataKinds: ['us_federal_grants', 'opportunity_titles', 'agencies', 'deadlines', 'listing_status'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Live public search adapter. Coverage is US federal opportunities only; eligibility and award availability must be confirmed on each official listing.',
  },
  {
    id: 'world_bank_projects',
    name: 'World Bank Projects & Operations',
    category: 'development_finance',
    endpoint: 'https://api.worldbank.org/v2/country/{countryCode}/projects',
    access: 'public_api',
    integrationStatus: 'implemented',
    dataKinds: ['development_projects', 'project_financing', 'country_project_status', 'approval_and_closing_dates'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Live country-specific project search. Project financing is not itself an open grant, private investment offer, or complete list of funding opportunities.',
  },
  {
    id: 'gleif_lei_records',
    name: 'GLEIF Global Legal Entity Identifier records',
    category: 'global_entity_directory',
    endpoint: 'https://api.gleif.org/api/v1/lei-records',
    access: 'public_api',
    integrationStatus: 'implemented',
    dataKinds: ['legal_entity_names', 'LEI_identifiers', 'registered_addresses', 'entity_status', 'registration_updates'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Live search adapter is available. LEI coverage is not universal; an LEI record does not prove a bank licence, investment activity, solvency, or willingness to fund.',
  },
  {
    id: 'stock_exchanges_official',
    name: 'Official stock exchanges and market operators',
    category: 'capital_markets',
    endpoint: null,
    access: 'official_exchange_sources',
    integrationStatus: 'catalog_only',
    dataKinds: ['stock_exchanges', 'listed_companies', 'market_disclosures'],
    requiresCredentials: 'check_exchange_terms',
    licenseReviewRequired: true,
    notes: 'Exchange coverage and delayed/live market data rights vary; no real-time pricing is implied.',
  },
  {
    id: 'development_finance_institutions',
    name: 'Development finance institutions',
    category: 'development_finance',
    endpoint: null,
    access: 'official_institution_sources',
    integrationStatus: 'catalog_only',
    dataKinds: ['development_finance', 'project_finance', 'trade_finance', 'private_sector_funding'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Candidate official institutions include multilateral and regional development banks; product availability and eligibility must be checked per institution.',
  },
  {
    id: 'global_investor_directory',
    name: 'Investor and venture capital directory',
    category: 'investors',
    endpoint: null,
    access: 'licensed_or_official_records',
    integrationStatus: 'catalog_only',
    dataKinds: ['venture_capital_firms', 'angel_networks', 'impact_investors', 'private_equity', 'investment_thesis', 'funding_stage'],
    requiresCredentials: 'depends_on_provider',
    licenseReviewRequired: true,
    notes: 'Investor profiles require source URLs, last-checked dates, geography, sector, stage, and evidence. Never imply an investor is accepting pitches without current proof.',
  },
  {
    id: 'startup_accelerators_incubators',
    name: 'Startup accelerators and incubators',
    category: 'entrepreneurship_funding',
    endpoint: null,
    access: 'official_program_sources',
    integrationStatus: 'catalog_only',
    dataKinds: ['accelerators', 'incubators', 'startup_programs', 'mentorship', 'demo_days'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Program dates, country eligibility, fees, equity terms, and application status must be sourced from each official program.',
  },
  {
    id: 'crowdfunding_platforms',
    name: 'Crowdfunding and startup finance platforms',
    category: 'entrepreneurship_funding',
    endpoint: null,
    access: 'provider_directory',
    integrationStatus: 'catalog_only',
    dataKinds: ['equity_crowdfunding', 'reward_crowdfunding', 'startup_funding_platforms'],
    requiresCredentials: 'check_provider_terms',
    licenseReviewRequired: true,
    notes: 'Availability is country-specific and may be regulated; do not promise access to investment or payouts.',
  },
  {
    id: 'trade_finance_and_insurance',
    name: 'Trade finance, export credit, and trade insurance providers',
    category: 'trade_finance',
    endpoint: null,
    access: 'official_institution_sources',
    integrationStatus: 'catalog_only',
    dataKinds: ['letters_of_credit', 'export_credit', 'trade_insurance', 'invoice_finance', 'working_capital'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Products, eligibility, sanctions screening, and country availability must be verified directly with each regulated provider.',
  },
  {
    id: 'grant_and_prize_programs',
    name: 'Global grants, prizes, and innovation funding',
    category: 'funding',
    endpoint: null,
    access: 'official_program_sources',
    integrationStatus: 'catalog_only',
    dataKinds: ['grants', 'innovation_prizes', 'research_funding', 'startup_competitions'],
    requiresCredentials: false,
    licenseReviewRequired: true,
    notes: 'Global catalog requires official program adapters; eligibility, deadline, funding amount, and application links must be checked against current notices.',
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
  if (DATA_SOURCES.some((entry) => entry.id === source)) return source;
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
