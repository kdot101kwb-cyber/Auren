const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const index = fs.readFileSync(require.resolve('./index.js'), 'utf8');

function assertModuleWired(name) {
  assert.ok(
    index.includes(`require('./${name}')`) || index.includes(`require("./${name}")`),
    `functions/index.js must wire ${name}.js`,
  );
}

test('Functions index keeps the modular backend composition', () => {
  for (const name of [
    'global_data',
    'global_data_country_registry',
    'match_everything_actions',
    'supplier_requests',
    'entertainment_library_seed',
    'gaez_global_data',
    'production_lifecycle',
  ]) assertModuleWired(name);
});

test('Functions index retains core multiplayer and tournament exports', () => {
  for (const name of [
    'submitAurenGameMove',
    'createAurenTournament',
    'joinAurenTournament',
    'startAurenTournament',
    'submitAurenTournamentMatchResult',
  ]) assert.match(index, new RegExp(`exports\\.${name}\\s*=`));
});

test('Global data endpoints are composed through module exports', () => {
  assert.match(index, /Object\.assign\(module\.exports, require\('\.\/global_data'\)\)/);
  assert.match(index, /Object\.assign\(module\.exports, require\('\.\/global_data_country_registry'\)\)/);
});

test('Production lifecycle exports are explicitly re-exported', () => {
  assert.match(index, /exports\.cancelAurenProduction = productionLifecycle\.cancelAurenProduction/);
  assert.match(index, /exports\.retryAurenProduction = productionLifecycle\.retryAurenProduction/);
  assert.match(index, /exports\.recordAurenProductionOutput = productionLifecycle\.recordAurenProductionOutput/);
});

test('No client-controlled Firebase function credentials are embedded in the index', () => {
  assert.doesNotMatch(index, /REPLICATE_API_TOKEN\s*=\s*['"]/);
  assert.doesNotMatch(index, /OPENAI_API_KEY\s*=\s*['"]/);
  assert.doesNotMatch(index, /GEMINI_API_KEY\s*=\s*['"]/);
});

test('Action intent logic remains isolated from the Firebase function index', () => {
  const intent = fs.readFileSync(path.join(__dirname, 'action_intent.js'), 'utf8');
  assert.match(intent, /normalizeAurenActionIntent/);
  assert.match(intent, /assertAurenActionPayload/);
});


test('Action Engine external effects are bound to the server idempotency key', () => {
  assert.match(index, /users\\/\\$\\{uid\\}\\/notes\\/\\$\\{action\.idempotencyKey\\}/);
  assert.match(index, /users\\/\\$\\{uid\\}\\/memory\\/\\$\\{action\.idempotencyKey\\}/);
  assert.match(index, /users\\/\\$\\{uid\\}\\/goals\\/\\$\\{action\.idempotencyKey\\}/);
  assert.match(index, /conversations\\/\\$\\{conversationId\\}\\/messages\\/\\$\\{\\'action_\\' \\+ action\.idempotencyKey\\}/);
});

test('Action Engine has server recovery and manual-review lifecycle gates', () => {
  assert.match(index, /status:\\'recovery_required\\'/);
  assert.match(index, /status:\\'manual_review\\'/);
  assert.match(index, /reasonCode:\\'execution_timeout\\'/);
  assert.match(index, /reasonCode:\\'manual_review_opened\\'/);
});

test('Action reject and cancel paths write transactional audit records', () => {
  assert.match(index, /reasonCode:\\'action_rejected\\'/);
  assert.match(index, /reasonCode:\\'action_cancelled\\'/);
});


test('Action recovery creates a durable deduplicated alert and manual review acknowledges it', () => {
  assert.match(index, /db\.collection\('action_recovery_alerts'\)\.doc\(actionDoc\.id\)/);
  assert.match(index, /type:'action_recovery_required'/);
  assert.match(index, /reasonCode:'recovery_alert_created'/);
  assert.match(index, /status:'acknowledged'/);
  assert.match(index, /acknowledgedBy:uid/);
});

test('Action Engine lifecycle contains the complete approved execution recovery path', () => {
  assert.match(index, /status:'approved'/);
  assert.match(index, /fromStatus:'pending',\s*toStatus:'approved'/s);
  assert.match(index, /status:'executing'/);
  assert.match(index, /fromStatus:'approved',\s*toStatus:'executing'/s);
  assert.match(index, /status:'completed'/);
  assert.match(index, /fromStatus:'executing',\s*toStatus:'completed'/s);
  assert.match(index, /nextStatus = errorClass === 'validation' \? 'failed' : 'recovery_required'/);
  assert.match(index, /status:'manual_review'/);
  assert.match(index, /fromStatus:'manual_review',\s*toStatus:outcome/s);
});

test('Action Engine execution gate binds identity, action type, payload hash, expiry, and idempotency', () => {
  assert.match(index, /approvedBy !== uid/);
  assert.match(index, /approvedActionType !== actionType/);
  assert.match(index, /constantTimeEqual\(approvedPayloadHash, currentPayloadHash\)/);
  assert.match(index, /actionIsExpired\(data\)/);
  assert.match(index, /String\(data\.idempotencyKey \|\| ''\)/);
});

test('Action Engine never retries an unknown external outcome automatically', () => {
  const start=index.indexOf("const nextStatus = errorClass === 'validation'");
  const end=index.indexOf("exports.recoverStaleAurenActions", start);
  const block=index.slice(start,end);
  assert.match(block, /'recovery_required'/);
  assert.doesNotMatch(block, /executeAurenAction\(/);
});

test('Manual review reconciliation closes only with an explicit outcome and evidence reference', () => {
  assert.match(index, /exports\.resolveAurenManualReview\s*=\s*require\('firebase-functions\/v2\/https'\)\.onCall/);
  assert.match(index, /data\.status !== 'manual_review'/);
  assert.match(index, /\['completed','failed'\]\.includes\(outcome\)/);
  assert.match(index, /reconciliationReference/);
  assert.match(index, /reasonCode:'manual_review_reconciled'/);
});

test('Manual review reconciliation never re-executes the external action', () => {
  const start = index.indexOf('exports.resolveAurenManualReview');
  const end = index.indexOf('exports.cancelAurenAction', start);
  const block = index.slice(start, end);
  assert.doesNotMatch(block, /action\.type ===/);
  assert.doesNotMatch(block, /executeAurenAction/);
});
