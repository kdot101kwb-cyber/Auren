'use strict';

const REPOSITORY = 'kdot101kwb-cyber/Auren';
const MAX_JOB_PAGES = 10;
const PAGE_SIZE = 100;

function parseGithubRunUrl(value) {
  let url;
  try {
    url = new URL(String(value || '').trim());
  } catch (_) {
    throw new Error('أرسل رابط GitHub Actions صحيحاً.');
  }
  const parts = url.pathname.split('/').filter(Boolean);
  if (url.protocol !== 'https:' || url.hostname !== 'github.com' ||
      parts.length !== 5 || parts[0] !== 'kdot101kwb-cyber' ||
      parts[1] !== 'Auren' || parts[2] !== 'actions' ||
      parts[3] !== 'runs' || !/^\d+$/.test(parts[4]) ||
      url.search || url.hash) {
    throw new Error('يُقبل فقط رابط تشغيل GitHub Actions في مستودع NOVA المحدد.');
  }
  return {
    runId: parts[4],
    runUrl: 'https://github.com/' + REPOSITORY + '/actions/runs/' + parts[4],
  };
}

async function checkGithubActionsRun(value, options = {}) {
  const {runId, runUrl} = parseGithubRunUrl(value);
  const fetchImpl = options.fetchImpl || fetch;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), options.timeoutMs || 15000);
  try {
    const headers = {
      accept: 'application/vnd.github+json',
      'x-github-api-version': '2022-11-28',
    };
    if (options.token) headers.authorization = 'Bearer ' + options.token;
    const base = 'https://api.github.com/repos/' + REPOSITORY + '/actions/runs/' + runId;
    const runResponse = await fetchImpl(base, {headers, signal: controller.signal});
    if (!runResponse.ok) {
      throw new Error('GitHub run lookup failed with HTTP ' + runResponse.status + '.');
    }
    const run = await runResponse.json();
    if (String(run.id) !== runId || run.repository?.full_name !== REPOSITORY) {
      throw new Error('GitHub returned a run outside the configured NOVA repository.');
    }

    let jobs = [];
    let totalCount = null;
    let paginationComplete = false;
    let paginationError = null;
    const pageLimit = Math.min(
      MAX_JOB_PAGES,
      Math.max(1, Number.isInteger(options.maxJobPages) ? options.maxJobPages : MAX_JOB_PAGES),
    );
    for (let page = 1; page <= pageLimit; page += 1) {
      const response = await fetchImpl(
        base + '/jobs?per_page=' + PAGE_SIZE + '&page=' + page,
        {headers, signal: controller.signal},
      );
      if (!response.ok) {
        throw new Error('GitHub job lookup failed with HTTP ' + response.status + '.');
      }
      const payload = await response.json();
      if (!Array.isArray(payload.jobs) || !Number.isInteger(payload.total_count) || payload.total_count < 0) {
        paginationError = 'GitHub returned an invalid job list.';
        break;
      }
      if (totalCount === null) totalCount = payload.total_count;
      if (payload.total_count !== totalCount) {
        paginationError = 'GitHub job count changed while the run was being checked.';
        break;
      }
      jobs.push(...payload.jobs);
      if (jobs.length >= totalCount) {
        paginationComplete = jobs.length === totalCount;
        break;
      }
      if (payload.jobs.length === 0) {
        paginationError = 'GitHub returned fewer jobs than its reported total.';
        break;
      }
    }
    if (!paginationComplete && !paginationError) {
      paginationError = 'Job list exceeds the verification page limit or is incomplete.';
    }

    const allJobsSucceeded = paginationComplete && totalCount > 0 &&
      jobs.every(job => job.status === 'completed' && ['success', 'skipped'].includes(job.conclusion));
    const verifiedSuccess = run.status === 'completed' &&
      run.conclusion === 'success' && allJobsSucceeded;
    const failed = run.status === 'completed' && run.conclusion &&
      run.conclusion !== 'success';
    const state = verifiedSuccess ? 'succeeded' :
      failed ? 'failed' :
      run.status !== 'completed' ? 'running' : 'unknown';

    const jobLines = jobs.map(job => ({
      jobId: Number(job.id || 0),
      name: String(job.name || 'job'),
      status: String(job.status || 'unknown'),
      conclusion: String(job.conclusion || ''),
      failedSteps: (Array.isArray(job.steps) ? job.steps : [])
        .filter(step => step.conclusion && !['success', 'skipped'].includes(step.conclusion))
        .map(step => String(step.name || 'step')),
    }));

    return {
      runId: Number(runId),
      runUrl,
      state,
      verifiedSuccess,
      status: String(run.status || 'unknown'),
      conclusion: String(run.conclusion || ''),
      branch: String(run.head_branch || ''),
      commit: String(run.head_sha || ''),
      jobs: jobLines,
      totalJobs: totalCount,
      paginationComplete,
      verificationError: paginationError,
      text: 'حالة تشغيل GitHub Actions: ' +
        (verifiedSuccess ? 'نجاح مثبت' : failed ? 'فشل' :
          state === 'running' ? 'قيد التنفيذ' : 'تعذر التحقق بالكامل') +
        '. الوظائف المفحوصة: ' + jobs.length + ' من ' + (totalCount ?? 'عدد غير معروف') + '.',
    };
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = {parseGithubRunUrl, checkGithubActionsRun};
