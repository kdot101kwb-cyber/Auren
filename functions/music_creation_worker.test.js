'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const source = fs.readFileSync(require.resolve('./music_creation_worker.js'), 'utf8');

test('terminal provider failure is reflected on the parent music job and unlocks it', () => {
  assert.match(source, /if\(d\.status==='failed'\)\{/);
  assert.match(source, /musicProductionStage:'failed',musicProductionStatus:'failed',musicWorkerLockUntilMs:0/);
  assert.match(source, /d\.lastError\|\|'Music generation failed\.'/);
});

test('completed provider job without a materialized artifact is QC-failed without resubmission', () => {
  assert.match(source, /if\(d\.status==='waiting_provider'&&!d\.externalJobId\)\{/);
  assert.match(source, /musicProductionStage:'qc_failed',musicProductionStatus:'qc_failed',musicWorkerLockUntilMs:0/);
  assert.match(source, /reason:'artifact_not_materialized'/);
  assert.match(source, /Provider completed without a materialized audio artifact\./);
  assert.ok(source.indexOf("if(d.status==='waiting_provider'&&!d.externalJobId)") < source.indexOf('const result=await submitAurenProviderJob'));
});
