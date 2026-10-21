'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { inspectEnvironment, renderMarkdown, parseMajor } = require('./auren_developer_preflight');

function fakeRunner(results) {
  return (command) => results[command] || { status: 127, stdout: '', stderr: '', error: 'not found' };
}

test('passes required tools and marks optional tools without failing the required summary', () => {
  const report = inspectEnvironment({
    runCommand: fakeRunner({
      git: { status: 0, stdout: 'git version 2.45.0' },
      node: { status: 0, stdout: 'v22.1.0' },
      flutter: { status: 0, stdout: 'Flutter 3.30.0' },
      dart: { status: 0, stdout: 'Dart SDK version: 3.8.0' },
    }),
    platform: 'test-platform',
    env: {},
  });
  assert.equal(report.summary.requiredMissing, 0);
  assert.equal(report.summary.requiredUnverified, 0);
  assert.equal(report.summary.optionalMissing, 2);
  assert.ok(report.checks.every((item) => item.status === 'pass' || item.status === 'optional-missing'));
});

test('warns when Node is older than the recommended major version', () => {
  const report = inspectEnvironment({
    runCommand: fakeRunner({
      git: { status: 0, stdout: 'git version 2.45.0' },
      node: { status: 0, stdout: 'v20.9.0' },
      flutter: { status: 0, stdout: 'Flutter 3.30.0' },
      dart: { status: 0, stdout: 'Dart SDK version: 3.8.0' },
    }),
    env: {},
  });
  assert.equal(report.summary.requiredMissing, 1);
  assert.equal(report.checks.find((x) => x.name === 'node').status, 'version-warning');
});

test('handles thrown command errors and unknown version strings', () => {
  const report = inspectEnvironment({
    runCommand: (command) => {
      if (command === 'node') return { status: 0, stdout: 'node version unknown' };
      if (command === 'git') throw new Error('missing command');
      return { status: 127, stdout: '', stderr: '' };
    },
    env: {},
  });
  assert.equal(report.summary.requiredUnverified, 1);
  assert.equal(report.checks.find((x) => x.name === 'git').status, 'missing');
  assert.equal(parseMajor('not a version'), null);
});

test('renders sanitized markdown and never prints environment values', () => {
  const report = inspectEnvironment({
    runCommand: fakeRunner({ node: { status: 0, stdout: 'v22.0.0' } }),
    env: { NODE_ENV: 'production', SECRET_TOKEN: 'do-not-print-this' },
  });
  const markdown = renderMarkdown(report);
  assert.ok(markdown.includes('AUREN Developer Environment Preflight'));
  assert.ok(markdown.includes('Read-only'));
  assert.ok(!markdown.includes('do-not-print-this'));
  assert.ok(!markdown.includes('production'));
});
