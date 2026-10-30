'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {buildSelfRepairProposal, normalizeCandidatePath} = require('./nova_self_repair_engine');

const base = {
  provider:'github_actions',
  runUrl:'https://github.com/kdot101kwb-cyber/Auren/actions/runs/123456',
  commit:'b910fd35deccdc0c1e91fa03ba789c3325397052',
};

test('creates a read-only proposal for Flutter analyzer evidence', () => {
  const result = buildSelfRepairProposal({...base, evidence:['flutter analyze: nova_ai/lib/features/home.dart:20:4 - unused_import']});
  assert.equal(result.status, 'proposal_only');
  assert.equal(result.category, 'flutter_static_analysis');
  assert.deepEqual(result.likelyAreas, ['nova_ai/lib/']);
  assert.equal(result.safety.filesChanged, 0);
  assert.equal(result.safety.patchGenerated, false);
  assert.equal(result.safety.humanApprovalRequired, true);
});

test('classifies Node test failures without allowing broad functions paths', () => {
  const result = buildSelfRepairProposal({
    provider:'circleci',
    runUrl:'https://circleci.com/gh/kdot101kwb-cyber/Auren/28210',
    evidence:['node --test nova_task_worker.test.js: AssertionError'],
    candidatePaths:['functions/nova_task_worker.js','functions/index.js','firebase.json'],
  });
  assert.equal(result.category, 'node_functions_test');
  assert.deepEqual(result.candidatePaths, ['functions/nova_task_worker.js']);
  assert.deepEqual(result.likelyAreas, ['functions/nova_', 'functions/']);
});

test('returns insufficient evidence without inventing a diagnosis', () => {
  const result = buildSelfRepairProposal({...base, evidence:[]});
  assert.equal(result.status, 'insufficient_evidence');
  assert.equal(result.category, 'unclassified');
  assert.deepEqual(result.candidatePaths, []);
});

test('rejects URLs outside the configured repository and invalid providers', () => {
  assert.throws(() => buildSelfRepairProposal({...base, runUrl:'https://github.com/other/repo/actions/runs/1'}), /outside the configured AUREN project/);
  assert.throws(() => buildSelfRepairProposal({...base, provider:'gitlab'}), /Unsupported CI provider/);
});

test('path allowlist rejects traversal and protected configuration', () => {
  for (const path of ['../nova_ai/lib/a.dart','firebase.json','.github/workflows/build.yml','functions/index.js','functions/.env']) {
    assert.equal(normalizeCandidatePath(path), null, path);
  }
  assert.equal(normalizeCandidatePath('nova_ai/lib/main.dart'), 'nova_ai/lib/main.dart');
});

test('redacts credentials and bounds untrusted evidence', () => {
  const result = buildSelfRepairProposal({...base, evidence:['token=super_secret_value', 'x'.repeat(900)]});
  assert.match(result.evidence[0], /REDACTED/);
  assert.equal(result.evidence[1].length, 500);
  assert.equal(result.evidence.length, 2);
});
