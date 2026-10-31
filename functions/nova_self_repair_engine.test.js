'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeRepairPath,
  validatePatchSet,
  createRepairProposal,
  redactRepairEvidence,
  approveRepairProposal,
  canApplyRepairProposal,
  evaluateRepairValidation,
} = require('./nova_self_repair_engine');

const sha = 'a'.repeat(40);
const validFile = {path:'functions/nova_example.js', content:'module.exports = true;\n', expectedSha:sha, reason:'Fix verified null handling.'};
const validInput = {
  provider:'github_actions',
  failureVerified:true,
  commitSha:sha,
  summary:'Fix the verified NOVA task worker failure.',
  evidence:[{source:'github_actions', line:42, text:'TypeError: expected value was undefined'}],
  files:[validFile],
};

test('allows only bounded NOVA source and test paths', () => {
  assert.equal(normalizeRepairPath('nova_ai/lib/features/tasks/repair.dart'), 'nova_ai/lib/features/tasks/repair.dart');
  assert.throws(() => normalizeRepairPath('functions/nova_worker.test.js'), /outside/);
  for (const path of [
    '../functions/index.js',
    'functions/index.js',
    'functions/.env',
    'firestore.rules',
    'functions/package-lock.json',
    'nova_ai/android/app/google-services.json',
    'functions/nova_task_worker.js/../../secrets.js',
  ]) assert.throws(() => normalizeRepairPath(path), /invalid|outside|cannot modify/i, path);
});

test('redacts credential evidence and rejects patches containing known secret formats', () => {
  const proposal = createRepairProposal({...validInput, evidence:[{text:'circle-token=ci_secret_value ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'}]});
  assert.equal(proposal.evidence[0].text.includes('ci_secret_value'), false);
  assert.equal(proposal.evidence[0].text.includes('ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'), false);
  assert.match(redactRepairEvidence('Authorization: Bearer verylongsecretvalue'), /REDACTED/);
  assert.doesNotMatch(redactRepairEvidence('CI log: sk-or-v1-abcdefghijklmnopqrstuvwxyz1234567890'), /sk-or-v1-/);
  assert.doesNotMatch(redactRepairEvidence('CI log: sk-proj-abcdefghijklmnopqrstuvwxyz1234567890'), /sk-proj-/);
  const providerTokens = [
    'xoxb-' + 'A'.repeat(24), 'glpat-' + 'B'.repeat(24), 'npm_' + 'C'.repeat(24),
    'sk_live_' + 'D'.repeat(24), 'ya29.' + 'E'.repeat(24),
    'SG.' + 'F'.repeat(24) + '.' + 'G'.repeat(24),
  ];
  for (const token of providerTokens) assert.doesNotMatch(redactRepairEvidence('CI output: ' + token), /A{24}|B{24}|C{24}|D{24}|E{24}|F{24}|G{24}/);
  assert.throws(() => validatePatchSet([{...validFile, content:'const token = "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";'}]), /credential material/);
  assert.throws(() => validatePatchSet([{...validFile, content:'const api_key = "this-is-a-hardcoded-secret-value";'}]), /credential material/);
  const awsEvidence = createRepairProposal({...validInput, evidence:[{text:'Error: AKIA1234567890ABCDEF'}]});
  assert.doesNotMatch(awsEvidence.evidence[0].text, /AKIA1234567890ABCDEF/);
});

test('rejects quoted and unquoted hardcoded credentials in repair patches', () => {
  for (const content of [
    'api_key: sk_live_1234567890abcdef',
    'OPENROUTER_API_KEY=sk-or-v1-1234567890abcdef',
    'password: long-password-value-123',
    'token = abcdefghijklmnopqrstuvwxyz123456',
    'const access_token = "this-is-a-long-hardcoded-secret";',
  ]) {
    assert.throws(() => validatePatchSet([{...validFile, content}]), /credential material/);
  }
  assert.doesNotThrow(() => validatePatchSet([{...validFile, content:'const token = process.env.API_KEY;'}]));
  assert.throws(() => validatePatchSet([{...validFile, content:'console.error("sk-or-v1-abcdefghijklmnopqrstuvwxyz1234567890");'}]), /credential material/);
});

test('validates patch count, content size, expected SHA and duplicate paths', () => {
  assert.equal(validatePatchSet([validFile]).files.length, 1);
  assert.throws(() => validatePatchSet([{...validFile, expectedSha:'bad'}]), /blob SHA/);
  assert.throws(() => validatePatchSet([validFile, validFile]), /duplicate/);
  assert.throws(() => validatePatchSet([{...validFile, content:'x'.repeat(65537)}]), /64 KiB/);
  assert.throws(() => validatePatchSet(Array(6).fill(validFile)), /between 1 and 5/);
});

test('requires verified CI failure and bounded evidence before proposing', () => {
  assert.equal(createRepairProposal(validInput).state, 'awaiting_approval');
  assert.throws(() => createRepairProposal({...validInput, failureVerified:false}), /verified CI failure/);
  assert.throws(() => createRepairProposal({...validInput, evidence:[]}), /evidence/);
  assert.throws(() => createRepairProposal({...validInput, commitSha:'bad'}), /commit SHA/);
});

test('requires explicit approval from the owning user before a patch can be applied', () => {
  const proposal = createRepairProposal(validInput);
  assert.throws(() => approveRepairProposal(proposal, 'owner-1', 'owner-2'), /owning user/);
  const approved = approveRepairProposal(proposal, 'owner-1', 'owner-1');
  assert.equal(canApplyRepairProposal(approved, 'owner-1', 'nova/repairs/fix-null-check'), true);
  assert.equal(canApplyRepairProposal(approved, 'owner-2', 'nova/repairs/fix-null-check'), false);
  assert.equal(canApplyRepairProposal(approved, 'owner-1', 'main'), false);
});

test('marks a repair verified only when every required check passes on the exact commit', () => {
  const applied = {...createRepairProposal(validInput), state:'validation_pending', repairCommitSha:sha};
  const passed = evaluateRepairValidation(applied, {
    commitSha:sha,
    validatedCommitSha:sha,
    requiredChecks:['functions_tests', 'flutter_ci'],
    checks:[{name:'functions_tests', conclusion:'success'}, {name:'flutter_ci', conclusion:'success'}],
  });
  assert.equal(passed.state, 'verified');
  const failed = evaluateRepairValidation(applied, {
    commitSha:sha,
    validatedCommitSha:'b'.repeat(40),
    requiredChecks:['functions_tests'],
    checks:[{name:'functions_tests', conclusion:'success'}],
  });
  assert.equal(failed.state, 'failed');
  const red = evaluateRepairValidation(applied, {
    commitSha:sha,
    validatedCommitSha:sha,
    requiredChecks:['functions_tests', 'flutter_ci'],
    checks:[{name:'functions_tests', conclusion:'failure'}, {name:'flutter_ci', conclusion:'success'}],
  });
  assert.equal(red.state, 'failed');
  const missing = evaluateRepairValidation(applied, {
    commitSha:sha,
    validatedCommitSha:sha,
    requiredChecks:['functions_tests', 'flutter_ci'],
    checks:[{name:'functions_tests', conclusion:'success'}],
  });
  assert.equal(missing.state, 'failed');
});
