'use strict';

const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');

const source=fs.readFileSync(new URL('./live_production_worker.js',import.meta.url),'utf8');

test('live production worker is fail-closed for unconfigured video providers',()=>{
  assert.match(source,/No Replicate model version configured for this video task/);
  assert.match(source,/status:'waiting_provider'/);
  assert.match(source,/providerState:'configuration_required'/);
});

test('video output requires a real provider artifact',()=>{
  assert.match(source,/polled.output && (polled.output.url || polled.output.storagePath || polled.output.externalId)/);
  assert.match(source,/status:'output'/);
  assert.doesNotMatch(source,/url:\s*['"]https?:\/\/.*fake/i);
});

test('provider jobs persist external ids and poll instead of duplicate submission',()=>{
  assert.match(source,/if \(task\.externalJobId && task\.providerId\)/);
  assert.match(source,/pollAurenProviderJob/);
  assert.match(source,/externalJobId:result\.result\.externalJobId/);
  assert.match(source,/idempotencyKey/);
});

test('worker binds provider credentials as server secrets',()=>{
  assert.match(source,/defineSecret\('REPLICATE_API_TOKEN'\)/);
  assert.match(source,/secrets:\[REPLICATE_API_TOKEN\]/);
  assert.doesNotMatch(source,/request\.auth.*REPLICATE_API_TOKEN/);
});

test('worker never treats text-only Hugging Face output as a video artifact',()=>{
  assert.match(source,/A video task must supply a Replicate model version/);
  assert.match(source,/provider:'replicate'/);
});


test('video model version has a backend deployment configuration fallback',()=>{
  assert.match(source,/defineString\('REPLICATE_VIDEO_MODEL_VERSION'/);
  assert.match(source,/task\.providerVersion \|\| task\.replicateVersion \|\| REPLICATE_VIDEO_MODEL_VERSION\.value\(\)/);
  assert.match(source,/never accept a provider URL, token, or model version from the client task payload as executable credentials/);
});
