'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {parseGithubRunUrl, checkGithubActionsRun} = require('./nova_github_ci_adapter');

const run = (overrides = {}) => ({
  id: 12345,
  status: 'completed',
  conclusion: 'success',
  head_branch: 'feature',
  head_sha: 'abc123',
  repository: {full_name: 'kdot101kwb-cyber/Auren'},
  ...overrides,
});
const response = payload => new Response(JSON.stringify(payload), {status: 200});
const makeFetch = payloads => async () => response(payloads.shift());

test('accepts only HTTPS run links for the configured repository', () => {
  assert.equal(parseGithubRunUrl('https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345').runId, '12345');
  for (const url of [
    'http://github.com/kdot101kwb-cyber/Auren/actions/runs/12345',
    'https://github.com/other/repo/actions/runs/12345',
    'https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345?x=1',
    'https://evil.example/x',
  ]) assert.throws(() => parseGithubRunUrl(url));
});

test('verifies a completed successful run only when every job succeeds', async () => {
  const result = await checkGithubActionsRun(
    'https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345',
    {fetchImpl: makeFetch([
      run(),
      {total_count: 1, jobs: [{name: 'build', status: 'completed', conclusion: 'success', steps: []}]},
    ])},
  );
  assert.equal(result.verifiedSuccess, true);
  assert.equal(result.state, 'succeeded');
  assert.equal(result.paginationComplete, true);
});

test('checks every page before reporting success', async () => {
  const first = Array.from({length: 100}, (_, i) => ({
    name: 'job-' + i, status: 'completed', conclusion: 'success', steps: [],
  }));
  const result = await checkGithubActionsRun(
    'https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345',
    {fetchImpl: makeFetch([
      run(),
      {total_count: 101, jobs: first},
      {total_count: 101, jobs: [{name: 'job-100', status: 'completed', conclusion: 'success', steps: []}]},
    ])},
  );
  assert.equal(result.jobs.length, 101);
  assert.equal(result.verifiedSuccess, true);
});

test('does not report green when a later job page is missing', async () => {
  const first = Array.from({length: 100}, (_, i) => ({
    name: 'job-' + i, status: 'completed', conclusion: 'success', steps: [],
  }));
  const result = await checkGithubActionsRun(
    'https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345',
    {maxJobPages: 1, fetchImpl: makeFetch([
      run(),
      {total_count: 101, jobs: first},
    ])},
  );
  assert.equal(result.verifiedSuccess, false);
  assert.equal(result.state, 'unknown');
  assert.equal(result.paginationComplete, false);
});

test('never reports green for active runs or failed jobs', async () => {
  const active = await checkGithubActionsRun(
    'https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345',
    {fetchImpl: makeFetch([
      run({status: 'in_progress', conclusion: null}),
      {total_count: 0, jobs: []},
    ])},
  );
  assert.equal(active.state, 'running');
  assert.equal(active.verifiedSuccess, false);

  const failedJob = await checkGithubActionsRun(
    'https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345',
    {fetchImpl: makeFetch([
      run(),
      {total_count: 1, jobs: [{name: 'test', status: 'completed', conclusion: 'failure', steps: []}]},
    ])},
  );
  assert.equal(failedJob.verifiedSuccess, false);
});

test('accepts a pull-request run whose source branch is a fork but whose run belongs to AUREN', async () => {
  const result = await checkGithubActionsRun(
    'https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345',
    {fetchImpl: makeFetch([
      run({head_repository: {full_name: 'contributor/fork'}}),
      {total_count: 1, jobs: [{name: 'build', status: 'completed', conclusion: 'success', steps: []}]},
    ])},
  );
  assert.equal(result.verifiedSuccess, true);
});

test('fails closed for runs from another repository and GitHub API errors', async () => {
  await assert.rejects(() => checkGithubActionsRun(
    'https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345',
    {fetchImpl: makeFetch([run({repository: {full_name: 'other/repo'}})])},
  ), /outside the configured NOVA repository/);
  await assert.rejects(() => checkGithubActionsRun(
    'https://github.com/kdot101kwb-cyber/Auren/actions/runs/12345',
    {fetchImpl: async () => new Response('{}', {status: 404})},
  ), /HTTP 404/);
});
