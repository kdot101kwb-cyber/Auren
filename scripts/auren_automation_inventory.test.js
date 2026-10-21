'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const { inventory, markdown, escapeMarkdownCell } = require('./auren_automation_inventory');

function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'auren-inventory-'));
  fs.mkdirSync(path.join(root, '.github', 'workflows'), { recursive: true });
  fs.mkdirSync(path.join(root, 'functions', 'nested'), { recursive: true });
  return root;
}

test('discovers workflow metadata and scheduled exports', () => {
  const root = fixture();
  fs.writeFileSync(path.join(root, '.github/workflows/ci.yml'), [
    'name: CI', 'on:', '  push:', '  pull_request:', 'permissions:', '  contents: read',
    'concurrency:', '  group: ci', 'jobs:', '  test:', '    runs-on: ubuntu-latest'
  ].join('\n'));
  fs.writeFileSync(path.join(root, 'functions/nested/schedules.js'), [
    "const { onSchedule } = require('firebase-functions/scheduler');",
    'exports.refreshCache = onSchedule({ schedule: "every 24 hours" }, async () => {});'
  ].join('\n'));
  const result = inventory(root);
  assert.equal(result.workflows.length, 1);
  assert.deepEqual(result.workflows[0].triggers, ['push', 'pull_request']);
  assert.deepEqual(result.workflows[0].jobs, ['test']);
  assert.equal(result.workflows[0].permissionsDeclared, true);
  assert.equal(result.workflows[0].permissionCoverage, 'workflow-level');
  assert.equal(result.workflows[0].concurrencyDeclared, true);
  assert.deepEqual(result.scheduledFunctions, [{ path: 'functions/nested/schedules.js', name: 'refreshCache' }]);
});

test('flags deployment commands without explicit project and non-staging target', () => {
  const root = fixture();
  fs.writeFileSync(path.join(root, '.github/workflows/deploy.yml'), [
    'name: Deploy', 'on:', '  workflow_dispatch:', 'jobs:', '  deploy:', '    steps:',
    '      - run: firebase deploy --only functions',
    '      - run: firebase deploy --project auren-production',
    '      - run: firebase deploy --project auren-staging'
  ].join('\n'));
  const result = inventory(root);
  assert.deepEqual(result.findings.map(item => item.code), ['missing-explicit-project', 'non-staging-target']);
  assert.equal(result.workflows[0].deployCommands.length, 3);
});


test('recognizes explicit job-level permissions across every job', () => {
  const root = fixture();
  fs.writeFileSync(path.join(root, '.github/workflows/publish.yml'), [
    'name: Publish', 'on:', '  workflow_dispatch:', 'jobs:',
    '  image-a:', '    permissions:', '      contents: read', '      packages: write',
    '    runs-on: ubuntu-latest',
    '  image-b:', '    permissions:', '      contents: read', '      packages: write',
    '    runs-on: ubuntu-latest'
  ].join('\n'));
  const workflow = inventory(root).workflows[0];
  assert.equal(workflow.permissionsDeclared, false);
  assert.deepEqual(workflow.jobPermissionsDeclared, ['image-a', 'image-b']);
  assert.equal(workflow.permissionCoverage, 'all-jobs');
});

test('report labels its limits and does not dump scanned source', () => {
  const root = fixture();
  fs.writeFileSync(path.join(root, '.github/workflows/ci.yml'), 'name: CI\non:\n  push:\njobs:\n  test:\n    runs-on: ubuntu-latest\n');
  const output = markdown(inventory(root));
  assert.match(output, /Static inspection only/);
  assert.doesNotMatch(output, /TOKEN_VALUE|SECRET_VALUE/);
});

test('escapes untrusted values before writing Markdown table cells', () => {
  assert.equal(escapeMarkdownCell('a|b'), 'a\\|b');
  assert.equal(escapeMarkdownCell('a\\\\b'), 'a\\\\\\\\b');
  assert.equal(escapeMarkdownCell('first\nsecond'), 'first second');
});

test('detects aliased scheduled exports and multiline deploy commands', () => {
  const root = fixture();
  fs.writeFileSync(path.join(root, 'functions/nested/alias.js'), [
    "const { onSchedule } = require('firebase-functions/scheduler');",
    'const cleanupTask = onSchedule({ schedule: "every day" }, async () => {});',
    'exports.cleanupTask = cleanupTask;'
  ].join('\n'));
  fs.writeFileSync(path.join(root, '.github/workflows/deploy.yml'), [
    'name: Deploy', 'on:', '  workflow_dispatch:', 'jobs:', '  deploy:', '    steps:',
    '      - name: Deploy staging',
    '        run: |',
    '          set -eu',
    '          npx --yes firebase-tools@15.34.0 deploy --only firestore:rules --project auren-staging --non-interactive'
  ].join('\n'));
  const result = inventory(root);
  assert.ok(result.scheduledFunctions.some(item => item.name === 'cleanupTask'));
  assert.equal(result.workflows[0].deployCommands[0].safety, 'explicit-project');
});
