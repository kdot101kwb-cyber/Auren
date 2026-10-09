const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const source = fs.readFileSync(require.resolve('./global_data_country_registry.js'), 'utf8');
const index = fs.readFileSync(require.resolve('./index.js'), 'utf8');

test('global data ingestion requires admin claims and excludes aggregate regions', () => {
  assert.match(source, /request\.auth\.token\?\.admin !== true/);
  assert.match(source, /permission-denied/);
  assert.match(source, /AbortController/);
  assert.match(source, /timeoutSeconds: 120/);
  assert.match(source, /c\.region\?\.value === 'Aggregates'/);
  assert.match(source, /auren_global_countries/);
  assert.match(source, /source: 'world_bank_wdi'/);
});

test('global country registry preserves ISO identity and geographic metadata', () => {
  assert.match(source, /iso2: c\.iso2Code/);
  assert.match(source, /iso3: c\.iso3Code/);
  assert.match(source, /capitalCity: c\.capitalCity/);
  assert.match(source, /longitude: coordinate\(c\.longitude\)/);
  assert.match(source, /latitude: coordinate\(c\.latitude\)/);
});

test('global indicator ingestion uses the canonical core feasibility indicators', () => {
  for (const indicator of [
    'SP.POP.TOTL',
    'NY.GDP.MKTP.CD',
    'NY.GDP.PCAP.CD',
    'SP.URB.TOTL.IN.ZS',
    'SL.UEM.TOTL.ZS',
    'AG.LND.AGRI.ZS',
    'AG.LND.ARBL.ZS',
    'SP.POP.GROW',
    'SP.DYN.LE00.IN',
    'NY.GDP.MKTP.KD.ZG',
    'FP.CPI.TOTL.ZG',
    'NE.EXP.GNFS.CD',
    'NE.IMP.GNFS.CD',
    'BX.KLT.DINV.CD.WD',
    'IT.NET.USER.ZS',
    'EG.ELC.ACCS.ZS',
    'NV.AGR.TOTL.ZS',
    'EG.FEC.RNEW.ZS',
  ]) assert.match(source, new RegExp(indicator.replaceAll('.', '\\.'), 'g'));
  assert.match(source, /INDICATOR_CATEGORIES/);
  assert.match(source, /category: INDICATOR_CATEGORIES/);
  assert.match(source, /auren_global_data/);
  assert.match(source, /indicatorName/);
  assert.match(source, /year: latest\.date/);
});

test('global data ingestion is bounded and stores provenance', () => {
  assert.match(source, /Math\.min\(Math\.max\(Number\(request\.data\?\.limit\) \|\| 25, 1\), 25\)/);
  assert.match(source, /source:'world_bank_wdi'/);
  assert.match(source, /updatedAt: admin\.firestore\.FieldValue\.serverTimestamp\(\)/);
});

test('global data callable endpoints are exported through the function index', () => {
  assert.match(index, /Object\.assign\(module\.exports, require\('\.\/global_data_country_registry'\)\)/);
  assert.match(index, /Object\.assign\(module\.exports, require\('\.\/global_data'\)\)/);
});


test('country intelligence endpoint supports bounded search and indicator hydration', () => {
  const globalData = fs.readFileSync(require.resolve('./global_data.js'), 'utf8');
  assert.match(globalData, /exports\.aurenCountryIntelligence/);
  assert.match(globalData, /orderBy\('name'\)\.limit\(250\)/);
  assert.match(globalData, /auren_global_data/);
});

test('opportunity country scan returns transparent data signals and deterministic ordering', () => {
  const globalData = fs.readFileSync(require.resolve('./global_data.js'), 'utf8');
  assert.match(globalData, /exports\.aurenOpportunityCountryScan/);
  assert.match(globalData, /dataCompleteness/);
  assert.match(globalData, /gdpPerCapita/);
  assert.match(globalData, /agriculturalLand/);
  assert.match(globalData, /candidates\.sort\(/);
});

test('global registry fails closed when the upstream returns no usable countries', () => {
  assert.match(source, /rows\.length === 0/);
  assert.match(source, /World Bank country registry returned no usable countries/);
});

test('global indicator ingestion caps work per invocation', () => {
  assert.match(source, /Math\.min\(Math\.max\(Number\(request\.data\?\.limit\) \|\| 25, 1\), 25\)/);
});

test('global indicator ingestion processes small country chunks with parallel indicators', () => {
  assert.match(source, /const countryChunkSize = 5/);
  assert.match(source, /Promise\.all\(countryChunk\.map/);
  assert.match(source, /Promise\.all\(CORE\.map/);
  assert.match(source, /1\), 25\)/);
});


test('global indicator ingestion tolerates upstream failures and reports partial results', () => {
  const globalDataSource = fs.readFileSync(require.resolve('./global_data_country_registry.js'), 'utf8');
  assert.match(globalDataSource, /catch \(_\) \{/);
  assert.match(globalDataSource, /Number\.isFinite\(value\)/);
  assert.match(globalDataSource, /failedIndicators/);
  assert.match(globalDataSource, /indicatorValuesStored/);
  assert.match(globalDataSource, /countriesWithNoIndicators/);
  assert.match(globalDataSource, /status: failedIndicators > 0 \|\| countriesWithNoIndicators > 0 \? 'partial' : 'ok'/);
});


test('country registry preserves zero coordinates and rejects invalid coordinate values', () => {
  const globalRegistry = fs.readFileSync(require.resolve('./global_data_country_registry.js'), 'utf8');
  assert.match(globalRegistry, /function coordinate\(value\)/);
  assert.match(globalRegistry, /longitude: coordinate\(c\.longitude\)/);
  assert.match(globalRegistry, /latitude: coordinate\(c\.latitude\)/);
  assert.match(globalRegistry, /number >= -180 && number <= 180/);
  assert.match(globalRegistry, /number >= -180 && number <= 180/);
});


test('global indicator ingestion can page through every country deterministically', () => {
  assert.match(source, /startAfterIso3/);
  assert.match(source, /orderBy\(admin\.firestore\.FieldPath\.documentId\(\)\)/);
  assert.match(source, /nextStartAfterIso3/);
  assert.match(source, /hasMoreCountries/);
});

test('global indicator ingestion searches history for the newest available value', () => {
  assert.match(source, /per_page=20/);
  assert.match(source, /history\.find\(\(entry\) => entry && entry\.value !== null/);
});
