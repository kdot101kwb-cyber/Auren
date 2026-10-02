'use strict';

const test=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');

const source=fs.readFileSync(require.resolve('./live_production_worker.js'),'utf8');

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
  assert.match(source,/externalJobId:realOutput \? '' : \(result\.result\.externalJobId \|\| ''\)/);
  assert.match(source,/idempotencyKey/);
});

test('worker binds provider credentials as server secrets',()=>{
  assert.match(source,/defineSecret\('REPLICATE_API_TOKEN'\)/);
  assert.match(source,/secrets:\[REPLICATE_API_TOKEN\]/);
  assert.doesNotMatch(source,/request\.auth.*REPLICATE_API_TOKEN/);
});

test('worker never treats text-only Hugging Face output as a video artifact',()=>{
  assert.match(source,/No Replicate model version configured for this video task/);
  assert.match(source,/provider:'replicate'/);
});


test('video model version has a backend deployment configuration fallback',()=>{
  assert.match(source,/defineString\('REPLICATE_VIDEO_MODEL_VERSION'/);
  assert.match(source,/REPLICATE_VIDEO_MODEL_VERSION\.value\(\)/);
  assert.doesNotMatch(source,/task\.providerVersion \|\| task\.replicateVersion/);
  assert.match(source,/Provider\/model selection and executable credentials are backend-controlled only/);
});


test('provider-pending tasks remain claimable for later polling',()=>{
  assert.match(source,/\['generation','provider_pending','processing'\]/);
  assert.match(source,/if \(!\['generation','provider_pending','processing'\]\.includes/);
});

test('terminal provider failure clears the external job before retry',()=>{
  assert.match(source,/status:'failed'/);
  assert.match(source,/externalJobId:''/);
  assert.match(source,/lastError:String\(polled\.error/);
});


test('generation retry budget is not consumed by provider polling',()=>{
  assert.match(source,/String\(data\.status \|\| ''\) === 'generation'/);
  assert.match(source,/generationAttempts:admin\.firestore\.FieldValue\.increment\(1\)/);
  assert.match(source,/provider_pending/);
});

test('completed provider output skips an unnecessary polling cycle',()=>{
  assert.match(source,/const realOutput=result\.result\.output/);
  assert.match(source,/status:realOutput \? 'output' : 'processing'/);
  assert.match(source,/externalJobId:realOutput \? '' :/);
});


test('cancelled tasks cannot be revived after provider polling',()=>{
  assert.match(source,/latestTask\.status \|\| ''\) === 'cancelled'/);
  assert.match(source,/latestTask\.cancelRequested === true/);
});

test('lifecycle output and history writes are deterministic',()=>{
  assert.match(source,/outputKey\(ref\.id, output\)/);
  assert.match(source,/lifecycleEventId\(\{\.\.\.task, id:ref\.id\}, event\)/);
});

test('generation attempts are terminally exhausted instead of silently stalling',()=>{
  assert.match(source,/async function exhaustGenerationAttempts/);
  assert.match(source,/Number\(data\.generationAttempts \|\| 0\) < MAX_ATTEMPTS/);
  assert.match(source,/providerState:'attempts_exhausted'/);
  assert.match(source,/Generation attempt limit/);
  assert.match(source,/await exhaustGenerationAttempts\(\)/);
});

test('transient provider polling failures use bounded backoff instead of terminal failure',()=>{
  assert.match(source,/function isTransientProviderError/);
  assert.match(source,/status === 408/);
  assert.match(source,/status === 429/);
  assert.match(source,/status >= 500/);
  assert.match(source,/providerState:'poll_backoff'/);
  assert.match(source,/providerPollFailures/);
  assert.match(source,/nextPollAtMs/);
  assert.match(source,/POLL_BACKOFF_MAX_MS/);
});

test('scheduled worker skips tasks during provider backoff',()=>{
  assert.match(source,/if \(Number\(data\.nextPollAtMs \|\| 0\) > Date\.now\(\)\) return false/);
});

test('provider request timeouts are treated as transient',()=>{
  assert.match(source,/error\?\.name === 'AbortError'/);
});


test('expired provider locks are recovered and released for retry',()=>{
  assert.match(source,/async function recoverStaleLocks/);
  assert.match(source,/providerLockUntilMs:0/);
  assert.match(source,/providerState:'stale_lock_recovered'/);
  assert.match(source,/Worker lock expired; task released for safe recovery/);
  assert.match(source,/await recoverStaleLocks\(\)/);
});


test('transient provider submission failures use bounded backoff',()=>{
  assert.match(source,/function nextSubmitAtMs/);
  assert.match(source,/SUBMIT_BACKOFF_BASE_MS/);
  assert.match(source,/SUBMIT_BACKOFF_MAX_MS/);
  assert.match(source,/isTransientProviderError\(result\)/);
  assert.match(source,/providerState:'submit_backoff'/);
  assert.match(source,/providerSubmitFailures/);
  assert.match(source,/nextPollAtMs:nextSubmitAtMs/);
});

test('provider submission uses async creation to reduce lost-response duplicates',()=>{assert.match(source,/externalJobId:result\.result\.externalJobId/);assert.doesNotMatch(source,/prefer:'wait'/);});
