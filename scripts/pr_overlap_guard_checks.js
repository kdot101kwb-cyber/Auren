'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeFileList, comparePullRequestChanges } = require('./auren_pr_overlap_guard');

test('normalizes and deduplicates changed file paths', () => {
  assert.deepEqual(normalizeFileList([{ filename: 'scripts/a.js' }, 'scripts/a.js']), ['scripts/a.js']);
});

test('finds shared file paths with another open pull request', () => {
  const result = comparePullRequestChanges(
    { number: 2, files: ['scripts/a.js', 'docs/a.md'] },
    [{ number: 3, state: 'open', title: 'Other', files: ['scripts/a.js'] }],
  );
  assert.deepEqual(result.overlaps, [{ number: 3, title: 'Other', sharedFiles: ['scripts/a.js'] }]);
});

test('rejects an invalid current pull request number', () => {
  assert.throws(() => comparePullRequestChanges({ number: 0, files: [] }, []), /positive integer number/);
});
