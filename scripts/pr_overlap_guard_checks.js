'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeFileList } = require('./auren_pr_overlap_guard');

test('normalizes and deduplicates changed file paths', () => {
  assert.deepEqual(
    normalizeFileList([{ filename: 'scripts/a.js' }, 'scripts/a.js', { filename: 'docs/readme.md' }, null]),
    ['docs/readme.md', 'scripts/a.js'],
  );
});
