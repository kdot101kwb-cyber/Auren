'use strict';

const fs = require('node:fs');

const API_BASE = 'https://api.github.com';
const API_VERSION = '2022-11-28';
const DEFAULT_CONCURRENCY = 8;

function isValidRepository(repository) {
  return typeof repository === 'string' &&
    /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repository);
}

function normalizeFileList(entries) {
  if (!Array.isArray(entries)) return [];
  return [...new Set(entries
    .map((entry) => typeof entry === 'string' ? entry : entry?.filename)
    .filter((file) => typeof file === 'string' && file.trim().length > 0)
    .map((file) => file.trim().replace(/\\/g, '/')))]
    .sort((a, b) => a.localeCompare(b));
}

function comparePullRequestChanges(currentPullRequest, otherPullRequests) {
  const currentNumber = Number(currentPullRequest?.number);
  if (!Number.isSafeInteger(currentNumber) || currentNumber < 1) {
    throw new Error('Current pull request must have a positive integer number.');
  }

  const changedFiles = normalizeFileList(currentPullRequest.files);
  const currentFiles = new Set(changedFiles);
  const overlaps = [];

  for (const pullRequest of Array.isArray(otherPullRequests) ? otherPullRequests : []) {
    const number = Number(pullRequest?.number);
    if (!Number.isSafeInteger(number) || number < 1 || number === currentNumber) continue;
    if (pullRequest.state && pullRequest.state !== 'open') continue;

    const sharedFiles = normalizeFileList(pullRequest.files)
      .filter((file) => currentFiles.has(file));
    if (sharedFiles.length === 0) continue;

    overlaps.push({
      number,
      title: typeof pullRequest.title === 'string' ? pullRequest.title : 'Untitled pull request',
      sharedFiles,
    });
  }

  overlaps.sort((a, b) => a.number - b.number);
  return { changedFiles, overlaps };
}

async function requestJson(url, token, fetchImpl) {
  let parsedUrl;
  try {
    parsedUrl = new URL(url);
  } catch {
    throw new Error('GitHub API URL is invalid.');
  }
  if (parsedUrl.origin !== API_BASE) {
    throw new Error('Requests are restricted to the GitHub API host.');
  }

  let response;
  try {
    response = await fetchImpl(url, {
      headers: {
        Accept: 'application/vnd.github+json',
        Authorization: 'Bearer ' + token,
        'X-GitHub-Api-Version': API_VERSION,
        'User-Agent': 'AUREN-PR-Workstream-Overlap-Guard',
      },
    });
  } catch {
    throw new Error('GitHub API network request failed.');
  }

  if (!response || typeof response.ok !== 'boolean') {
    throw new Error('GitHub API returned an invalid response.');
  }
  if (!response.ok) {
    throw new Error('GitHub API request failed with HTTP ' + response.status +
      ' for ' + parsedUrl.pathname + '.');
  }
  try {
    return await response.json();
  } catch {
    throw new Error('GitHub API returned invalid JSON.');
  }
}

async function fetchPagedJson(pathname, options = {}) {
  const {
    token,
    fetchImpl = globalThis.fetch,
    pageSize = 100,
    maxPages = 1000,
  } = options;

  if (typeof token !== 'string' || token.trim().length === 0) {
    throw new Error('A GitHub token with read-only pull request access is required.');
  }
  if (typeof fetchImpl !== 'function') throw new Error('A fetch implementation is required.');
  if (!Number.isSafeInteger(pageSize) || pageSize < 1 || pageSize > 100) {
    throw new Error('Page size must be between 1 and 100.');
  }
  if (!Number.isSafeInteger(maxPages) || maxPages < 1) {
    throw new Error('Maximum page count must be a positive integer.');
  }
  if (typeof pathname !== 'string' || !pathname.startsWith('/repos/')) {
    throw new Error('GitHub API endpoint must be a repository endpoint.');
  }

  const results = [];
  for (let page = 1; page <= maxPages; page += 1) {
    const url = new URL(pathname, API_BASE);
    url.searchParams.set('per_page', String(pageSize));
    url.searchParams.set('page', String(page));
    const data = await requestJson(url.toString(), token, fetchImpl);
    if (!Array.isArray(data)) {
      throw new Error('GitHub API returned an unexpected list response for ' + url.pathname + '.');
    }
    results.push(...data);
    if (data.length < pageSize) return results;
  }
  throw new Error('GitHub API pagination exceeded the safety limit for ' + pathname + '.');
}

async function mapWithConcurrency(items, concurrency, mapper) {
  if (!Number.isSafeInteger(concurrency) || concurrency < 1) {
    throw new Error('Concurrency must be a positive integer.');
  }
  const results = new Array(items.length);
  let nextIndex = 0;
  const workerCount = Math.min(concurrency, items.length);
  await Promise.all(Array.from({ length: workerCount }, async () => {
    while (true) {
      const index = nextIndex;
      nextIndex += 1;
      if (index >= items.length) return;
      results[index] = await mapper(items[index], index);
    }
  }));
  return results;
}

function parsePullRequestEvent(payload) {
  const pullRequest = payload?.pull_request;
  const number = Number(pullRequest?.number ?? payload?.number);
  if (!pullRequest || !Number.isSafeInteger(number) || number < 1) {
    throw new Error('The event payload must describe a pull_request with a positive integer number.');
  }
  return {
    number,
    title: typeof pullRequest.title === 'string' ? pullRequest.title : 'Untitled pull request',
    state: typeof pullRequest.state === 'string' ? pullRequest.state : 'open',
  };
}

async function auditPullRequestOverlap({
  repository,
  currentPullRequest,
  token,
  fetchImpl = globalThis.fetch,
  pageSize = 100,
  concurrency = DEFAULT_CONCURRENCY,
}) {
  if (!isValidRepository(repository)) {
    throw new Error('GITHUB_REPOSITORY must be in owner/repository form.');
  }
  if (typeof token !== 'string' || token.trim().length === 0) {
    throw new Error('GITHUB_TOKEN is required for the read-only overlap audit.');
  }
  const currentNumber = Number(currentPullRequest?.number);
  if (!Number.isSafeInteger(currentNumber) || currentNumber < 1) {
    throw new Error('Current pull request must have a positive integer number.');
  }

  const parts = repository.split('/');
  const pullRequestsPath = '/repos/' + parts[0] + '/' + parts[1] + '/pulls?state=open';
  const openPullRequests = await fetchPagedJson(pullRequestsPath, {
    token, fetchImpl, pageSize,
  });
  const otherPullRequests = openPullRequests
    .filter((pullRequest) =>
      Number(pullRequest?.number) !== currentNumber && pullRequest?.state === 'open')
    .sort((a, b) => Number(a.number) - Number(b.number));

  const pullRequestsToInspect = [
    { ...currentPullRequest, number: currentNumber },
    ...otherPullRequests,
  ];
  const inspected = await mapWithConcurrency(
    pullRequestsToInspect,
    concurrency,
    async (pullRequest) => {
      const path = '/repos/' + parts[0] + '/' + parts[1] +
        '/pulls/' + Number(pullRequest.number) + '/files';
      const files = await fetchPagedJson(path, { token, fetchImpl, pageSize });
      return { ...pullRequest, number: Number(pullRequest.number), files: normalizeFileList(files) };
    },
  );

  const current = inspected.find((pullRequest) => pullRequest.number === currentNumber);
  if (!current) throw new Error('Current pull request file list could not be loaded.');
  const comparison = comparePullRequestChanges(current, inspected.filter((pullRequest) =>
    pullRequest.number !== currentNumber));

  return {
    repository,
    currentPullRequest: {
      number: currentNumber,
      title: currentPullRequest.title || 'Untitled pull request',
    },
    changedFilesCount: comparison.changedFiles.length,
    otherOpenPullRequestsChecked: otherPullRequests.length,
    overlaps: comparison.overlaps,
    auditComplete: true,
  };
}

function escapeCell(value) {
  return String(value ?? '—')
    .replace(/\\/g, '\\\\')
    .replace(/\|/g, '\\|')
    .replace(/[\r\n]+/g, ' ')
    .replace(/[\u0000-\u001f]/g, ' ');
}

function renderMarkdown(report) {
  const currentNumber = report.currentPullRequest.number;
  const currentUrl = 'https://github.com/' + report.repository + '/pull/' + currentNumber;
  const lines = [
    '# AUREN PR Workstream Overlap Guard',
    '',
    '- Repository: **' + escapeCell(report.repository) + '**',
    '- Current PR: [#' + currentNumber + ' — ' +
      escapeCell(report.currentPullRequest.title) + '](' + currentUrl + ')',
    '- Current PR changed files: **' + report.changedFilesCount + '**',
    '- Other open PRs checked: **' + report.otherOpenPullRequestsChecked + '**',
    '- Overlapping PRs: **' + report.overlaps.length + '**',
    '',
  ];

  if (report.overlaps.length === 0) {
    lines.push('No shared changed-file paths were detected for this PR.');
  } else {
    lines.push('| Other open PR | Shared paths | Files |', '|---|---:|---|');
    for (const overlap of report.overlaps) {
      const url = 'https://github.com/' + report.repository + '/pull/' + overlap.number;
      lines.push('| [#' + overlap.number + ' — ' + escapeCell(overlap.title) +
        '](' + url + ') | ' + overlap.sharedFiles.length + ' | ' +
        escapeCell(overlap.sharedFiles.join(', ')) + ' |');
    }
  }

  lines.push(
    '',
    'This audit compares changed file paths only. It cannot detect semantic overlap across different files, and shared files may be intentional. Review findings before merge; this tool never edits, closes, approves, or merges pull requests.',
    '',
  );
  return lines.join('\n');
}

async function main({
  env = process.env,
  fetchImpl = globalThis.fetch,
  stdout = process.stdout,
  stderr = process.stderr,
  readFile = fs.readFileSync,
} = {}) {
  const repository = env.GITHUB_REPOSITORY;
  const token = env.GITHUB_TOKEN;
  const eventPath = env.GITHUB_EVENT_PATH;
  if (!repository || !token || !eventPath) {
    throw new Error('GITHUB_REPOSITORY, GITHUB_TOKEN, and GITHUB_EVENT_PATH are required.');
  }

  let payload;
  try {
    payload = JSON.parse(readFile(eventPath, 'utf8'));
  } catch {
    throw new Error('GITHUB_EVENT_PATH is missing or does not contain valid JSON.');
  }
  const currentPullRequest = parsePullRequestEvent(payload);
  const report = await auditPullRequestOverlap({
    repository, currentPullRequest, token, fetchImpl,
  });

  stdout.write(renderMarkdown(report));
  for (const overlap of report.overlaps) {
    stderr.write('::warning title=AUREN PR file overlap::Current PR #' +
      report.currentPullRequest.number + ' shares ' + overlap.sharedFiles.length +
      ' changed path(s) with open PR #' + overlap.number + '. Review the overlap report.\n');
  }
  return report;
}

if (require.main === module) {
  main().catch((error) => {
    process.stderr.write('AUREN PR overlap audit could not complete: ' +
      String(error?.message || 'unknown error') + '\n');
    process.exitCode = 2;
  });
}

module.exports = {
  auditPullRequestOverlap,
  comparePullRequestChanges,
  escapeCell,
  fetchPagedJson,
  isValidRepository,
  main,
  normalizeFileList,
  parsePullRequestEvent,
  renderMarkdown,
};
