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
  const workflow = parseWorkflow('.github/workflows/health.yml', `name: Health Watch
on:
  workflow_dispatch:
  pull_request:
    branches: [main]
  schedule:
    - cron: '20 3 * * *'
permissions:
  contents: read
concurrency:
  group: health
`);
  assert.deepEqual(workflow.triggers, ['pull_request', 'schedule', 'workflow_dispatch']);
  assert.deepEqual(workflow.cronSchedules, ['20 3 * * *']);
  assert.equal(workflow.explicitPermissions, true);
  assert.equal(workflow.concurrencyConfigured, true);
  assert.equal(workflow.findings.length, 0);
});

test('discovers exported scheduled Cloud Functions without running them', () => {
  const functions = parseScheduledFunctions('functions/index.js', `exports.recoverJobs = onSchedule({schedule:'every 5 minutes'}, async () => {});
exports.dailyAudit = onSchedule({ schedule: "0 4 * * *" }, async () => {});`);
  assert.deepEqual(functions.map((fn) => ({ name: fn.name, schedule: fn.schedule })), [
    { name: 'recoverJobs', schedule: 'every 5 minutes' },
    { name: 'dailyAudit', schedule: '0 4 * * *' },
  ]);
});

test('fails closed when a Firebase deployment omits an explicit project', () => {
  const root = makeRepo();
  try {
    write(root, '.github/workflows/release.yml', `name: Release
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  deploy:
    steps:
      - run: npx firebase-tools deploy --only firestore:rules
`);
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
    write(root, '.github/workflows/deploy-staging.yml', `name: Deploy STAGING
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  deploy:
    steps:
      - run: npx firebase-tools deploy --project auren-90ccc
`);
    const inventory = buildInventory(root);
    assert.equal(inventory.violations.length, 1);
    assert.equal(inventory.violations[0].code, 'staging_deploy_wrong_project');
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('accepts an explicit auren-staging target and emits a useful report', () => {
  const root = makeRepo();
  try {
    write(root, '.github/workflows/deploy-staging.yml', `name: Deploy STAGING
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  deploy:
    steps:
      - run: npx firebase-tools deploy --project auren-staging
`);
    const inventory = buildInventory(root);
    assert.equal(inventory.violations.length, 0);
    assert.match(renderMarkdown(inventory), /Firebase targets/);
    assert.match(renderMarkdown(inventory), /auren-staging/);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('escapes backslashes and pipes in Markdown table cells', () => {
  const root = makeRepo();
  try {
    write(root, '.github/workflows/odd-name.yml', `name: Odd \\\\ path | label
on:
  workflow_dispatch:
permissions:
  contents: read
`);
    const report = renderMarkdown(buildInventory(root));
    assert.match(report, /Odd \\\\\\\\ path \\| label/);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('does not include environment values or secret-like test input in report', () => {
  const root = makeRepo();
  try {
    write(root, '.github/workflows/health.yml', `name: Health
on:
  workflow_dispatch:
env:
  API_TOKEN: DO_NOT_LEAK_TEST_VALUE
permissions:
  contents: read
`);
    const report = renderMarkdown(buildInventory(root));
    assert.equal(report.includes('DO_NOT_LEAK_TEST_VALUE'), false);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('ignores cron declarations inside inline YAML comments', () => {
  const workflow = parseWorkflow('.github/workflows/inline-comment.yml', `name: Inline Comment
on:
  workflow_dispatch: # schedule: - cron: '0 0 * * *'
permissions:
  contents: read
`);
  assert.deepEqual(workflow.cronSchedules, []);
  assert.equal(workflow.findings.some((finding) => finding.code === 'scheduled_workflow_without_concurrency'), false);
});

test('ignores cron declarations inside full-line YAML comments', () => {
  const workflow = parseWorkflow('.github/workflows/commented.yml', `name: Commented
on:
  workflow_dispatch:
# schedule:
#   - cron: '0 0 * * *'
permissions:
  contents: read
`);
  assert.deepEqual(workflow.cronSchedules, []);
  assert.equal(workflow.findings.some((finding) => finding.code === 'scheduled_workflow_without_concurrency'), false);
});
