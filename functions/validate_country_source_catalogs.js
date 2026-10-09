'use strict';

const fs = require('node:fs');
const path = require('node:path');

const BATCHES = [8, 9, 10, 11, 12];
const ROOT = __dirname;

function validateCatalog(catalog, expectedBatch) {
  const errors = [];
  if (!catalog || typeof catalog !== 'object' || Array.isArray(catalog)) {
    return ['catalog must be a JSON object'];
  }
  if (catalog.batch !== expectedBatch) errors.push(`batch must equal ${expectedBatch}`);
  if (!Array.isArray(catalog.countries) || catalog.countries.length !== 10) {
    errors.push('countries must contain exactly 10 entries');
  }
  if (!Array.isArray(catalog.sources) || catalog.sources.length !== 50) {
    errors.push('sources must contain exactly 50 entries');
  }
  if (catalog.country_count !== 10) errors.push('country_count must equal 10');
  if (catalog.source_count !== 50) errors.push('source_count must equal 50');
  const countryCodes = new Set();
  for (const country of catalog.countries || []) {
    if (!country || typeof country.name !== 'string' || !country.name.trim()) errors.push('country name missing');
    if (!country || typeof country.iso2 !== 'string' || !/^[A-Z]{2}$/.test(country.iso2)) errors.push(`invalid ISO alpha-2 code: ${country && country.iso2}`);
    else if (countryCodes.has(country.iso2)) errors.push(`duplicate country code: ${country.iso2}`);
    else countryCodes.add(country.iso2);
  }
  const ids = new Set();
  const countByCountry = new Map();
  for (const source of catalog.sources || []) {
    if (!source || typeof source !== 'object') { errors.push('source record must be an object'); continue; }
    if (!source.id || typeof source.id !== 'string') errors.push('source id missing');
    else if (ids.has(source.id)) errors.push(`duplicate source id: ${source.id}`);
    else ids.add(source.id);
    if (!source.country || !countryCodes.has(source.country_code)) errors.push(`source has unknown country code: ${source.country_code}`);
    countByCountry.set(source.country_code, (countByCountry.get(source.country_code) || 0) + 1);
    if (!source.name || typeof source.name !== 'string') errors.push(`source name missing: ${source.id}`);
    if (!source.category || typeof source.category !== 'string') errors.push(`category missing: ${source.id}`);
    try {
      const parsed = new URL(source.url);
      if (parsed.protocol !== 'https:') errors.push(`non-HTTPS URL: ${source.id}`);
      if (!parsed.hostname || /\\s/.test(source.url)) errors.push(`malformed URL: ${source.id}`);
    } catch { errors.push(`invalid URL: ${source.id} (${source.url})`); }
    if (source.integration_status !== 'catalog_only') errors.push(`unexpected integration status: ${source.id}`);
  }
  for (const [code, count] of countByCountry) {
    if (count !== 5) errors.push(`${code} must have 5 sources; found ${count}`);
  }
  return errors;
}

function loadAndValidateAll() {
  const results = [];
  for (const batch of BATCHES) {
    const file = path.join(ROOT, `country_official_trade_sources_batch${batch}.json`);
    if (!fs.existsSync(file)) {
      results.push({ batch, file, errors: ['file missing'] });
      continue;
    }
    try {
      const catalog = JSON.parse(fs.readFileSync(file, 'utf8'));
      results.push({ batch, file, count: Array.isArray(catalog.sources) ? catalog.sources.length : 0, errors: validateCatalog(catalog, batch), catalog });
    } catch (error) {
      results.push({ batch, file, errors: [`invalid JSON: ${error.message}`] });
    }
  }
  const allCodes = new Map();
  for (const result of results) {
    for (const c of result.catalog?.countries || []) {
      if (allCodes.has(c.iso2)) result.errors.push(`country repeats across batches: ${c.iso2} (also batch ${allCodes.get(c.iso2)})`);
      else allCodes.set(c.iso2, result.batch);
    }
  }
  return results;
}

async function checkLinks(catalogs, { concurrency = 8, timeoutMs = 9000 } = {}) {
  const queue = [];
  for (const result of catalogs) for (const source of result.catalog?.sources || []) queue.push({ batch: result.batch, source });
  const results = [];
  let next = 0;
  async function worker() {
    while (true) {
      const index = next++;
      if (index >= queue.length) return;
      const { batch, source } = queue[index];
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);
      let status = null;
      let reachable = false;
      let note = '';
      try {
        const requestOptions = {
          redirect: 'follow',
          signal: controller.signal,
          headers: { 'user-agent': 'AUREN-SourceCatalog-Validator/1.0' }
        };
        let response = await fetch(source.url, { ...requestOptions, method: 'HEAD' });
        // Some official SharePoint/legacy portals answer HEAD with 404 while GET serves the page.
        // Retry GET for 404 as well as methods/auth restrictions before labeling a URL broken.
        if ([403, 404, 405, 501].includes(response.status)) {
          response = await fetch(source.url, {
            ...requestOptions,
            method: 'GET',
            headers: { ...requestOptions.headers, range: 'bytes=0-0' }
          });
        }
        status = response.status;
        reachable = response.ok || [401, 403, 405, 429].includes(status);
        if ([401, 403, 405, 429].includes(status)) note = 'host responded; automated access may be restricted';
        else if (status >= 500) note = 'server error; retry later';
        else if (status >= 400) note = 'HTTP error; manual review needed';
      } catch (error) {
        note = error.name === 'AbortError' ? 'timeout' : `network error: ${error.message}`;
      } finally {
        clearTimeout(timer);
      }
      results.push({ batch, id: source.id, country: source.country, url: source.url, status, reachable, note });
    }
  }
  await Promise.all(Array.from({ length: Math.min(concurrency, queue.length) }, worker));
  results.sort((a, b) => a.batch - b.batch || a.id.localeCompare(b.id));
  return results;
}

if (require.main === module) {
  const catalogs = loadAndValidateAll();
  let failed = false;
  for (const result of catalogs) {
    const errors = result.errors || [];
    console.log(`Batch ${result.batch}: ${result.count ?? 0} records; ${errors.length ? 'FAIL' : 'PASS'}`);
    for (const error of errors) console.error(`  - ${error}`);
    if (errors.length) failed = true;
  }
  if (process.argv.includes('--check-links')) {
    checkLinks(catalogs).then(results => {
      const reportPath = path.join(ROOT, 'country_official_trade_sources_link_check_report.json');
      const summary = {
        checked_at: new Date().toISOString(),
        checked_count: results.length,
        reachable_count: results.filter(r => r.reachable).length,
        needs_review_count: results.filter(r => !r.reachable).length,
        note: 'HTTP reachability is not proof of official ownership, legal reuse rights, current registry data, or API availability.',
        results
      };
      fs.writeFileSync(reportPath, JSON.stringify(summary, null, 2) + '\n');
      console.log(`Link check: ${summary.reachable_count}/${summary.checked_count} responded or restricted automated access; report: ${reportPath}`);
      if (failed || summary.needs_review_count) process.exitCode = 1;
    }).catch(error => { console.error(error); process.exitCode = 1; });
  } else if (failed) {
    process.exitCode = 1;
  }
}

module.exports = { BATCHES, validateCatalog, loadAndValidateAll, checkLinks };
