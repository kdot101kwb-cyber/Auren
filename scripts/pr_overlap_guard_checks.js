'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  auditPullRequestOverlap,
  comparePullRequestChanges,
  fetchPagedJson,
  normalizeFileList,
  parsePullRequestEvent,
  renderMarkdown,
} = require('./auren_pr_overlap_guard');

function response(status, payload) {
  return {
    ok: status >= 200 && status < 300,
    status,
    json: async () => payload,
  };
}

test('normalizes, trims, sorts, and deduplicates changed file paths', () => {
  assert.deepEqual(
    normalizeFileList([
      { filename: ' scripts/a.js ' },
      'scripts/a.js',
      'docs\\guide.md',
      null,
      '',
    ]),
    ['docs/guide.md', 'scripts/a.js'],
  );
});

test('finds shared file paths with another open pull request', () => {
  const result = comparePullRequestChanges(
    { number: 2, files: ['scripts/a.js', 'docs/a.md'] },
    [
      { number: 3, state: 'open', title: 'Other', files: ['scripts/a.js'] },
      { number: 4, state: 'closed', title: 'Closed', files: ['docs/a.md'] },
      { number: 2, state: 'open', title: 'Self', files: ['docs/a.md'] },
    ],
  );
  assert.deepEqual(result.overlaps, [
    { number: 3, title: 'Other', sharedFiles: ['scripts/a.js'] },
  ]);
});

test('rejects invalid current pull request numbers and event payloads', () => {
  assert.throws(
    () => comparePullRequestChanges({ number: 0, files: [] }, []),
    /positive integer number/,
  );
  assert.throws(() => parsePullRequestEvent({ action: 'opened' }), /pull_request/);
});

test('requires a token and does not call the network without one', async () => {
  let called = false;
  await assert.rejects(
    () => fetchPagedJson('/repos/acme/app/pulls', {
      token: ' ',
      fetchImpl: async () => { called = true; return response(200, []); },
    }),
    /token.*required/i,
  );
  assert.equal(called, false);
});

test('stops pagination on a short page and fails safely at the page limit', async () => {
  const urls = [];
  const pages = await fetchPagedJson('/repos/acme/app/pulls', {
    token: 'test-token',
    pageSize: 1,
    maxPages: 3,
    fetchImpl: async (url) => {
      urls.push(new URL(url).searchParams.get('page'));
      return response(200, urls.length === 1 ? [{ number: 1 }] : []);
    },
  });
  assert.deepEqual(pages, [{ number: 1 }]);
  assert.deepEqual(urls, ['1', '2']);

  await assert.rejects(
    () => fetchPagedJson('/repos/acme/app/pulls', {
      token: 'test-token',
      pageSize: 1,
      maxPages: 1,
      fetchImpl: async () => response(200, [{ number: 1 }]),
    }),
    /pagination exceeded the safety limit/,
  );
});

test('reports API errors without leaking token values', async () => {
  await assert.rejects(
    () => fetchPagedJson('/repos/acme/app/pulls', {
      token: 'secret-token-for-test',
      fetchImpl: async () => response(403, { message: 'forbidden' }),
    }),
    (error) => {
      assert.match(error.message, /HTTP 403/);
      assert.doesNotMatch(error.message, /secret-token-for-test/);
      return true;
    },
  );
});

test('fails closed on unexpected list responses and network errors', async () => {
  await assert.rejects(
    () => fetchPagedJson('/repos/acme/app/pulls', {
      token: 'test-token',
      fetchImpl: async () => response(200, { items: [] }),
    }),
    /unexpected list response/,
  );
  await assert.rejects(
    () => fetchPagedJson('/repos/acme/app/pulls', {
      token: 'test-token',
      fetchImpl: async () => { throw new Error('private transport detail'); },
    }),
    /network request failed/,
  );
});

test('completes a read-only audit and renders shared paths', async () => {
  const fetchImpl = async (url) => {
    const parsed = new URL(url);
    const path = parsed.pathname;
    if (path.endsWith('/pulls')) {
      return response(200, [
        { number: 12, title: 'Current', state: 'open' },
        { number: 13, title: 'Other work', state: 'open' },
      ]);
    }
    if (path.endsWith('/pulls/12/files')) {
      return response(200, [{ filename: 'scripts/shared.js' }]);
    }
    if (path.endsWith('/pulls/13/files')) {
      return response(200, [{ filename: 'scripts/shared.js' }, { filename: 'docs/other.md' }]);
    }
    return response(404, {});
  };

  const report = await auditPullRequestOverlap({
    repository: 'acme/app',
    currentPullRequest: { number: 12, title: 'Current' },
    token: 'read-only-test-token',
    fetchImpl,
  });
  assert.equal(report.auditComplete, true);
  assert.equal(report.changedFilesCount, 1);
  assert.deepEqual(report.overlaps, [{
    number: 13,
    title: 'Other work',
    sharedFiles: ['scripts/shared.js'],
  }]);
  const markdown = renderMarkdown(report);
  assert.ok(markdown.includes('scripts/shared.js'));
  assert.ok(markdown.includes('never edits, closes, approves, or merges'));
});

test('does not return a completed report if one pull request file list fails', async () => {
  const fetchImpl = async (url) => {
    const path = new URL(url).pathname;
    if (path.endsWith('/pulls')) {
      return response(200, [{ number: 12, title: 'Current', state: 'open' }]);
    }
    return response(500, {});
  };
  await assert.rejects(
    () => auditPullRequestOverlap({
      repository: 'acme/app',
      currentPullRequest: { number: 12, title: 'Current' },
      token: 'read-only-test-token',
      fetchImpl,
    }),
    /HTTP 500/,
  );
});
