'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { analyzeLogs, renderReport } = require('./auren_ci_failure_triage');

function withLogs(files, callback) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'auren-ci-triage-'));
  try {
    for (const [name, content] of Object.entries(files)) {
      const target = path.join(root, name);
      fs.mkdirSync(path.dirname(target), { recursive: true });
      fs.writeFileSync(target, content, 'utf8');
    }
    callback(root);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

test('classifies known signals without copying raw log lines', () => {
  withLogs({
    'flutter-test.log': 'Some tests failed\nMissingPluginException(secret-value)\n',
    'backend/ci-test.log': 'not ok 2 - sample test\n',
    'ignored.json': 'BUILD FAILED',
  }, (root) => {
    const result = analyzeLogs(root);
    assert.equal(result.filesScanned, 2);
    assert.equal(result.filesWithSignals, 2);
    assert.ok(result.categories.some((item) => item.id === 'flutter-test' && item.count === 1));
    assert.ok(result.categories.some((item) => item.id === 'missing-plugin' && item.count === 1));
    assert.ok(result.categories.some((item) => item.id === 'node-test' && item.count === 1));
    const report = renderReport({ root });
    assert.ok(!report.includes('secret-value'));
    assert.ok(report.includes('Missing platform plugin / channel'));
  });
});

test('returns a cautious empty report for missing or unrecognized artifacts', () => {
  withLogs({ 'unknown.log': 'routine output only\n' }, (root) => {
    const report = renderReport({ root, conclusion: 'failure' });
    assert.ok(report.includes('Original workflow conclusion: **failure**'));
    assert.ok(report.includes('No known failure patterns were found'));
    assert.ok(report.includes('does not prove the run was healthy'));
  });
});

test('counts multiple matching lines and sorts file paths', () => {
  withLogs({
    'z.log': 'BUILD FAILED\nBUILD FAILED\n',
    'a.txt': 'ETIMEDOUT\n',
  }, (root) => {
    const result = analyzeLogs(root);
    assert.equal(result.filesScanned, 2);
    assert.equal(result.categories.find((item) => item.id === 'gradle-build').count, 2);
    assert.equal(result.perFile[0].file, 'a.txt');
  });
});

test('omits non-GitHub and malformed run URLs', () => {
  withLogs({}, (root) => {
    assert.ok(renderReport({ root, runUrl: 'https://example.com/steal' }).includes('URL omitted'));
    assert.ok(renderReport({ root, runUrl: 'not-a-url' }).includes('URL omitted'));
  });
});
