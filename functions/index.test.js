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
