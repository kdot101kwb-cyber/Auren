'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {
  buildInventory,
  parseWorkflow,
  parseScheduledFunctions,
  renderMarkdown,
} = require('./auren_automation_inventory');

function makeRepo() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'auren-automation-inventory-'));
  fs.mkdirSync(path.join(root, '.github', 'workflows'), { recursive: true });
  fs.mkdirSync(path.join(root, 'functions'), { recursive: true });
  return root;
}

function write(root, relativePath, content) {
  const fullPath = path.join(root, relativePath);
  fs.mkdirSync(path.dirname(fullPath), { recursive: true });
  fs.writeFileSync(fullPath, content, 'utf8');
}

test('parses workflow triggers, cron, permissions, and concurrency', () => {
  const workflow = parseWorkflow('.github/workflows/health.yml', 'name: Health Watch\non:\n  workflow_dispatch:\n  pull_request:\n    branches: [main]\n  schedule:\n    - cron: \'20 3 * * *\'\npermissions:\n  contents: read\nconcurrency:\n  group: health\n');
  assert.deepEqual(workflow.triggers, ['pull_request', 'schedule', 'workflow_dispatch']);
  assert.deepEqual(workflow.cronSchedules, ['20 3 * * *']);
  assert.equal(workflow.explicitPermissions, true);
  assert.equal(workflow.concurrencyConfigured, true);
  assert.equal(workflow.findings.length, 0);
});

test('discovers exported scheduled Cloud Functions without running them', () => {
  const functions = parseScheduledFunctions('functions/index.js', 'exports.recoverJobs = onSchedule({schedule:\'every 5 minutes\'}, async () => {});\nexports.dailyAudit = onSchedule({ schedule: "0 4 * * *" }, async () => {});');
  assert.deepEqual(functions.map((fn) => ({ name: fn.name, schedule: fn.schedule })), [
    { name: 'recoverJobs', schedule: 'every 5 minutes' },
    { name: 'dailyAudit', schedule: '0 4 * * *' },
  ]);
});

test('fails closed when a Firebase deployment omits an explicit project', () => {
  const root = makeRepo();
  try {
    write(root, '.github/workflows/release.yml', 'name: Release\non:\n  workflow_dispatch:\npermissions:\n  contents: read\njobs:\n  deploy:\n    steps:\n      - run: npx firebase-tools deploy --only firestore:rules\n');
    const inventory = buildInventory(root);
    assert.equal(inventory.violations.length, 1);
    assert.equal(inventory.violations[0].code, 'firebase_deploy_missing_explicit_project');
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('rejects a staging-labelled workflow that targets a non-staging project', () => {
  const root = makeRepo();
  try {
    write(root, '.github/workflows/deploy-staging.yml', 'name: Deploy STAGING\non:\n  workflow_dispatch:\npermissions:\n  contents: read\njobs:\n  deploy:\n    steps:\n      - run: npx firebase-tools deploy --project auren-90ccc\n');
    const inventory = buildInventory(root);
    assert.equal(inventory.violations.length, 1);
    assert.equal(inventory.violations[0].code, 'staging_deploy_wrong_project');
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('accepts a staging deployment with an explicit staging project', () => {
  const root = makeRepo();
  try {
    write(root, '.github/workflows/deploy-staging.yml', 'name: Deploy STAGING\non:\n  workflow_dispatch:\npermissions:\n  contents: read\njobs:\n  deploy:\n    steps:\n      - run: npx firebase-tools deploy --project auren-staging\n');
    const inventory = buildInventory(root);
    assert.equal(inventory.violations.length, 0);
    assert.equal(inventory.firebaseDeployCommandCount, 1);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('reports static metadata only and never emits secret-like workflow values', () => {
  const root = makeRepo();
  try {
    write(root, '.github/workflows/health.yml', 'name: Health\non: [workflow_dispatch, push]\nenv:\n  API_TOKEN: do-not-print-this-value\n');
    write(root, 'functions/index.js', 'exports.hourlyJob = onSchedule({schedule:\'every 60 minutes\'}, async () => {});');
    const inventory = buildInventory(root);
    const report = renderMarkdown(inventory);
    assert.match(report, /Health/);
    assert.match(report, /hourlyJob/);
    assert.doesNotMatch(report, /do-not-print-this-value/);
    assert.equal(inventory.violations.length, 0);
    assert.ok(inventory.warnings.some((finding) => finding.code === 'implicit_workflow_permissions'));
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});
