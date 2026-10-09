#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');

const ROOT = __dirname;
const REPORT = path.join(ROOT, 'global_source_catalog_link_audit_report.json');
const TIMEOUT_MS = Math.max(1000, Math.min(20000, Number(process.env.AUDIT_TIMEOUT_MS) || 8000));
const CONCURRENCY = Math.max(1, Math.min(10, Number(process.env.AUDIT_CONCURRENCY) || 5));

function findCatalogFiles() {
  // Include legacy and newer catalogs regardless of whether their filenames
  // contain "global" or "batch". Exclude generated reports to prevent recursion.
  const available = fs.readdirSync(ROOT);
  const requested = (process.env.AUDIT_CATALOG_FILES || '')
    .split(',')
    .map(name => name.trim())
    .filter(Boolean);

  const selected = requested.length
    ? requested
    : available.filter(name =>
        /\.json$/i.test(name) &&
        /(?:source|sources|catalog|manufacturer|investor|trade|bank|factory)/i.test(name) &&
        !/(?:audit|link_check|report|schema|fixture|test)/i.test(name)
      );

  const missing = selected.filter(name =>
    name !== path.basename(name) || !available.includes(name)
  );
  if (missing.length) {
    throw new Error(`AUDIT_CATALOG_FILES contains missing or unsafe filenames: ${missing.join(', ')}`);
  }

  return [...new Set(selected)].sort().map(name => path.join(ROOT, name));
}

function loadCatalog(file) {
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!data || !Array.isArray(data.records)) {
    throw new Error(`${path.basename(file)}: expected a top-level records array`);
  }
  const errors = [];
  const ids = new Set();
  data.records.forEach((record, index) => {
    const label = `${path.basename(file)} record[${index}]`;
    if (!record || typeof record !== 'object') {
      errors.push(`${label}: record must be an object`);
      return;
    }
    for (const key of ['id', 'name', 'country', 'url', 'status', 'verification_status', 'api_status']) {
      if (typeof record[key] !== 'string' || !record[key].trim()) errors.push(`${label}: missing string ${key}`);
    }
    if (record.id) {
      if (ids.has(record.id)) errors.push(`${label}: duplicate id ${record.id}`);
      ids.add(record.id);
    }
    try {
      const parsed = new URL(record.url);
      if (!['http:', 'https:'].includes(parsed.protocol)) errors.push(`${label}: URL must use HTTP(S)`);
    } catch {
      errors.push(`${label}: invalid URL ${String(record.url)}`);
    }
  });
  return { file, data, errors };
}

async function probe(url) {
  const started = Date.now();
  let method = 'HEAD';
  try {
    let response = await fetch(url, {
      method,
      redirect: 'follow',
      signal: AbortSignal.timeout(TIMEOUT_MS),
      headers: { 'user-agent': 'AUREN-SourceCatalog-Audit/1.0 (+https://github.com/kdot101kwb-cyber/Auren)' }
    });
    if ([405, 501].includes(response.status)) {
      await response.body?.cancel().catch(() => {});
      method = 'GET';
      response = await fetch(url, {
        method,
        redirect: 'follow',
        signal: AbortSignal.timeout(TIMEOUT_MS),
        headers: {
          'user-agent': 'AUREN-SourceCatalog-Audit/1.0 (+https://github.com/kdot101kwb-cyber/Auren)',
          range: 'bytes=0-0'
        }
      });
    }
    const status = response.status;
    await response.body?.cancel().catch(() => {});
    let classification = 'http_response_needs_manual_review';
    if (status >= 200 && status < 400) classification = 'responded';
    else if ([401, 403, 407, 429].includes(status)) classification = 'restricted_or_rate_limited';
    else if ([404, 410].includes(status)) classification = 'possible_dead_link_review_required';
    return { url, method, http_status: status, classification, final_url: response.url, duration_ms: Date.now() - started };
  } catch (error) {
    const name = error && error.name === 'TimeoutError' ? 'timeout' : (error?.cause?.code || error?.name || 'network_error');
    return { url, method, classification: 'no_http_response_review_required', error: String(name), duration_ms: Date.now() - started };
  }
}

async function mapLimit(items, limit, fn) {
  const output = new Array(items.length);
  let next = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (true) {
      const index = next++;
      if (index >= items.length) return;
      output[index] = await fn(items[index]);
    }
  });
  await Promise.all(workers);
  return output;
}

async function main() {
  const files = findCatalogFiles();
  if (!files.length) throw new Error('No global source batch JSON catalogs found in functions/.');
  const catalogs = files.map(loadCatalog);
  const structuralErrors = catalogs.flatMap(c => c.errors);
  const entries = catalogs.flatMap(c => c.data.records.map(record => ({
    file: path.basename(c.file),
    batch_number: c.data.batch_number ?? null,
    id: record.id,
    name: record.name,
    country: record.country,
    url: record.url,
    status: record.status,
    verification_status: record.verification_status,
    api_status: record.api_status
  })));
  const ids = new Set();
  for (const item of entries) {
    const key = item.id;
    if (key && ids.has(key)) structuralErrors.push(`duplicate ID across catalogs: ${key}`);
    if (key) ids.add(key);
  }

  const shouldCheckLinks = process.argv.includes('--check-links');
  const linkResults = shouldCheckLinks
    ? await mapLimit(entries, CONCURRENCY, async item => ({ ...item, ...(await probe(item.url)) }))
    : [];

  const report = {
    generated_at: new Date().toISOString(),
    catalogs_checked: catalogs.length,
    records_checked: entries.length,
    structural_error_count: structuralErrors.length,
    structural_errors: structuralErrors,
    link_check_enabled: shouldCheckLinks,
    link_results_count: linkResults.length,
    link_classification_counts: linkResults.reduce((counts, result) => {
      counts[result.classification] = (counts[result.classification] || 0) + 1;
      return counts;
    }, {}),
    flagged_links: linkResults
      .filter(result => result.classification !== 'responded')
      .map(({ file, id, name, country, url, method, http_status, classification, error, final_url }) => ({
        file, id, name, country, url, method, http_status, classification, error, final_url
      })),
    interpretation: 'Automated HTTP checks are triage only. A response does not establish official ownership, accuracy, API availability, licensing, scraping permission, or reuse rights. HTTP 403/429, timeouts, and network errors are not automatically proof that a source is broken.',
    link_results: linkResults
  };
  fs.writeFileSync(REPORT, JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify({
    catalogs_checked: report.catalogs_checked,
    records_checked: report.records_checked,
    structural_error_count: report.structural_error_count,
    link_check_enabled: report.link_check_enabled,
    link_classification_counts: report.link_classification_counts,
    report_path: path.basename(REPORT)
  }, null, 2));
  if (structuralErrors.length) process.exitCode = 1;
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
