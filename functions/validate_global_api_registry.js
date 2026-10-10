#!/usr/bin/env node
'use strict';

// Structural guard for the curated AUREN API registry.
// This validates metadata only; it does not probe providers or claim live integration.
const fs = require('node:fs');
const path = require('node:path');

const file = path.join(__dirname, 'global_verified_api_registry_v1.json');
let registry;
try {
  registry = JSON.parse(fs.readFileSync(file, 'utf8'));
} catch (error) {
  console.error(`FAIL: registry is not valid JSON: ${error.message}`);
  process.exit(1);
}

const errors = [];
const isHttps = value => {
  try { return new URL(value).protocol === 'https:'; } catch { return false; }
};

if (registry.schema_version !== '1.0.0') errors.push('schema_version must be 1.0.0');
if (!registry.policy || registry.policy.only_official_documentation !== true) errors.push('policy.only_official_documentation must be true');
if (registry.policy?.no_credentials_stored !== true) errors.push('policy.no_credentials_stored must be true');
if (registry.policy?.no_undocumented_endpoint_guessing !== true) errors.push('policy.no_undocumented_endpoint_guessing must be true');
if (!Array.isArray(registry.apis) || registry.apis.length === 0) errors.push('apis must be a non-empty array');

const seen = new Set();
for (const [index, api] of (Array.isArray(registry.apis) ? registry.apis : []).entries()) {
  const prefix = `apis[${index}]`;
  for (const field of ['id', 'name', 'provider', 'base_url', 'documentation_url', 'authentication', 'access_tier']) {
    if (typeof api[field] !== 'string' || api[field].trim() === '') errors.push(`${prefix}.${field} is required`);
  }
  if (api.id && seen.has(api.id)) errors.push(`${prefix}.id duplicates ${api.id}`);
  if (api.id) seen.add(api.id);
  if (api.base_url && !isHttps(api.base_url)) errors.push(`${prefix}.base_url must use HTTPS`);
  if (api.documentation_url && !isHttps(api.documentation_url)) errors.push(`${prefix}.documentation_url must use HTTPS`);
  if (api.example_endpoint && !isHttps(api.example_endpoint)) errors.push(`${prefix}.example_endpoint must use HTTPS`);
  if (api.officially_documented !== true) errors.push(`${prefix}.officially_documented must be true`);
  if (api.verification_status !== 'official_docs_verified') errors.push(`${prefix}.verification_status must be official_docs_verified`);
  if (api.integration_status !== 'catalog_only') errors.push(`${prefix}.integration_status must remain catalog_only until integration tests and approvals`);
}

if (errors.length) {
  console.error('Global API registry validation failed:');
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log(`Global API registry valid: ${registry.apis.length} unique HTTPS API entries; metadata-only verification, no live integration asserted.`);
