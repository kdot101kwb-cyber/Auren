#!/usr/bin/env node
'use strict';

// Conservative, read-only API discovery for AUREN source catalogs.
// Never guesses undocumented API endpoints, sends credentials, or submits data.
const fs = require('node:fs');
const path = require('node:path');

const ROOT = __dirname;
const REPORT = path.join(ROOT, 'global_source_api_discovery_report.json');
const TIMEOUT_MS = Math.max(1500, Math.min(15000, Number(process.env.API_AUDIT_TIMEOUT_MS) || 7000));
const CONCURRENCY = Math.max(1, Math.min(6, Number(process.env.API_AUDIT_CONCURRENCY) || 4));
const USER_AGENT = 'AUREN-ReadOnly-API-Discovery/1.0 (+https://github.com/kdot101kwb-cyber/Auren)';
const API_FIELDS = ['api_url', 'api_base_url', 'api_endpoint', 'endpoint_url', 'openapi_url', 'swagger_url', 'api_docs_url', 'documentation_url', 'developer_url'];
const API_LINK_HINT = /(?:\bapi\b|\/api(?:\/|$|[?#])|developer(?:s)?|openapi|swagger|redoc|graphql|data[-_/ ]?portal|webservice|web[-_/ ]?service|api[-_ ]?documentation|\/docs(?:\/|$|[?#]))/i;

function catalogFiles() {
  const requested = (process.env.API_AUDIT_CATALOG_FILES || '').split(',').map(x => x.trim()).filter(Boolean);
  const names = requested.length ? requested : fs.readdirSync(ROOT).filter(name =>
    /\.json$/i.test(name) &&
    /(?:source|sources|catalog|manufacturer|investor|trade|bank|factory)/i.test(name) &&
    !/(?:audit|link_check|report|schema|fixture|test)/i.test(name)
  );
  const available = new Set(fs.readdirSync(ROOT));
  const missing = names.filter(name => name !== path.basename(name) || !available.has(name));
  if (missing.length) throw new Error('Missing or unsafe catalog filenames: ' + missing.join(', '));
  return [...new Set(names)].sort().map(name => path.join(ROOT, name));
}

function recordsFrom(file) {
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!Array.isArray(data?.records)) return [];
  return data.records.filter(r => r && typeof r === 'object').map((r, index) => ({
    file: path.basename(file),
    batch_number: data.batch_number ?? null,
    id: r.id ?? r.source_id ?? r.record_id ?? null,
    name: r.name ?? r.source_name ?? r.organization ?? r.title ?? null,
    country: r.country ?? r.country_name ?? r.jurisdiction ?? null,
    homepage_url: r.url ?? r.website ?? r.source_url ?? null,
    declared_api_urls: API_FIELDS.map(k => r[k]).filter(v => typeof v === 'string' && /^https?:\/\//i.test(v)),
    declared_api_fields: API_FIELDS.filter(k => typeof r[k] === 'string' && r[k].trim()),
    existing_api_status: r.api_status ?? r.api_availability ?? 'not_assessed',
    record_index: index
  }));
}

async function request(url, method = 'GET') {
  const started = Date.now();
  try {
    const response = await fetch(url, {
      method,
      redirect: 'follow',
      signal: AbortSignal.timeout(TIMEOUT_MS),
      headers: { 'user-agent': USER_AGENT, accept: 'text/html,application/json,application/yaml,*/*;q=0.5' }
    });
    const result = {
      url, method, http_status: response.status, final_url: response.url,
      content_type: response.headers.get('content-type') || null,
      duration_ms: Date.now() - started
    };
    if (method === 'HEAD' || !response.ok) {
      await response.body?.cancel().catch(() => {});
      return result;
    }
    const reader = response.body?.getReader();
    if (!reader) return { ...result, body_prefix: '' };
    const chunks = [];
    let size = 0;
    try {
      while (size < 300000) {
        const { value, done } = await reader.read();
        if (done) break;
        const chunk = value.subarray(0, 300000 - size);
        chunks.push(Buffer.from(chunk));
        size += chunk.length;
        if (size >= 300000) break;
      }
    } finally {
      await reader.cancel().catch(() => {});
    }
    return { ...result, body_prefix: Buffer.concat(chunks).toString('utf8') };
  } catch (error) {
    return {
      url, method, error: String(error?.cause?.code || error?.name || 'network_error'),
      duration_ms: Date.now() - started
    };
  }
}

function discoverLinks(html, baseUrl) {
  const links = new Set();
  const pattern = /<a\b[^>]*href\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))[^>]*>([\s\S]*?)<\/a\s*>/gi;
  let match;
  while ((match = pattern.exec(html)) !== null) {
    const raw = match[1] ?? match[2] ?? match[3] ?? '';
    const label = (match[4] || '').replace(/<[^>]*>/g, ' ').replace(/&amp;/g, '&').trim();
    if (!raw || /^(?:#|mailto:|javascript:|tel:)/i.test(raw)) continue;
    let resolved;
    try { resolved = new URL(raw, baseUrl); } catch { continue; }
    if (!['http:', 'https:'].includes(resolved.protocol)) continue;
    if (API_LINK_HINT.test(resolved.href) || API_LINK_HINT.test(label)) links.add(resolved.href);
  }
  // Also recognize machine-readable API descriptions explicitly linked in HTML.
  const machineHints = /(?:href|content)\s*=\s*["']([^"']*(?:openapi|swagger|api-docs)[^"']*)["']/gi;
  while ((match = machineHints.exec(html)) !== null) {
    try {
      const resolved = new URL(match[1], baseUrl);
      if (['http:', 'https:'].includes(resolved.protocol)) links.add(resolved.href);
    } catch {}
  }
  return [...links].slice(0, 12);
}

function classify(record, homepage, declared, discovered) {
  const good = r => r && r.http_status >= 200 && r.http_status < 400;
  const auth = r => r && [401, 403].includes(r.http_status);
  const limited = r => r && r.http_status === 429;
  if (record.declared_api_urls.length) {
    if (declared.some(good)) return 'declared_api_endpoint_responded';
    if (declared.some(auth)) return 'declared_api_endpoint_auth_or_access_restricted';
    if (declared.some(limited)) return 'declared_api_endpoint_rate_limited';
    if (declared.some(r => r?.http_status === 404 || r?.http_status === 410)) return 'declared_api_endpoint_not_found_review';
    return 'declared_api_endpoint_unconfirmed';
  }
  if (discovered.length) return 'api_or_developer_documentation_candidate_discovered';
  if (good(homepage)) return 'homepage_responded_api_not_identified';
  if (auth(homepage)) return 'homepage_access_restricted_api_not_identified';
  return 'homepage_unreachable_or_unconfirmed_api_not_identified';
}

async function mapLimit(items, limit, fn) {
  const out = new Array(items.length);
  let next = 0;
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (true) {
      const i = next++;
      if (i >= items.length) return;
      out[i] = await fn(items[i]);
    }
  }));
  return out;
}

async function main() {
  const files = catalogFiles();
  const records = files.flatMap(recordsFrom);
  if (!records.length) throw new Error('No source catalog records found.');
  const shouldProbe = process.argv.includes('--probe');
  const results = await mapLimit(records, CONCURRENCY, async record => {
    let homepage = null;
    let declared = [];
    let discovered = [];
    if (shouldProbe && typeof record.homepage_url === 'string') {
      try {
        const parsed = new URL(record.homepage_url);
        if (['http:', 'https:'].includes(parsed.protocol)) {
          homepage = await request(parsed.href, 'GET');
          if (homepage.body_prefix) discovered = discoverLinks(homepage.body_prefix, homepage.final_url || parsed.href);
        }
      } catch {}
    }
    if (shouldProbe && record.declared_api_urls.length) {
      declared = await mapLimit(record.declared_api_urls, Math.min(2, CONCURRENCY), async url => {
        try {
          const parsed = new URL(url);
          if (!['http:', 'https:'].includes(parsed.protocol)) return { url, error: 'invalid_protocol' };
          return await request(parsed.href, 'GET');
        } catch { return { url, error: 'invalid_url' }; }
      });
    }
    return {
      file: record.file, batch_number: record.batch_number, id: record.id,
      name: record.name, country: record.country, homepage_url: record.homepage_url,
      existing_api_status: record.existing_api_status,
      declared_api_fields: record.declared_api_fields,
      declared_api_urls: record.declared_api_urls,
      homepage_probe: homepage && { url: homepage.url, http_status: homepage.http_status, final_url: homepage.final_url, content_type: homepage.content_type, error: homepage.error },
      declared_api_probes: declared.map(({ body_prefix, ...safe }) => safe),
      discovered_api_or_docs_links: discovered,
      api_assessment: shouldProbe
        ? classify(record, homepage, declared, discovered)
        : (record.declared_api_urls.length ? 'declared_api_url_requires_probe' : 'not_assessed_probe_disabled')
    };
  });
  const counts = results.reduce((acc, row) => {
    acc[row.api_assessment] = (acc[row.api_assessment] || 0) + 1;
    return acc;
  }, {});
  const report = {
    generated_at: new Date().toISOString(),
    catalogs_checked: files.length,
    records_checked: records.length,
    probe_enabled: shouldProbe,
    assessment_counts: counts,
    results,
    interpretation: 'Read-only triage only. A homepage or documentation link does not prove a working API. A responding endpoint does not prove authentication, data quality, official ownership, licensing, rate limits, or permission to reuse data. No credentials are sent, no write requests are made, and undocumented endpoint paths are not guessed. 401/403/429 and network errors require manual review.'
  };
  fs.writeFileSync(REPORT, JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify({
    catalogs_checked: report.catalogs_checked,
    records_checked: report.records_checked,
    probe_enabled: report.probe_enabled,
    assessment_counts: report.assessment_counts,
    report_path: path.basename(REPORT)
  }, null, 2));
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
