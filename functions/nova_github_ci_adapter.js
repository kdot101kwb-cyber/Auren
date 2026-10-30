'use strict';
const REPOSITORY = 'kdot101kwb-cyber/Auren';
function parseGithubRunUrl(value) {
  let url;
  try { url = new URL(String(value || '').trim()); } catch (_) { throw new Error('أرسل رابط GitHub Actions صحيحاً.'); }
  const parts = url.pathname.split('/').filter(Boolean);
  if (url.protocol !== 'https:' || url.hostname !== 'github.com' ||
      parts.length !== 5 || parts[0] !== 'kdot101kwb-cyber' ||
      parts[1] !== 'Auren' || parts[2] !== 'actions' ||
      parts[3] !== 'runs' || !/^\d+$/.test(parts[4]) || url.search || url.hash) {
    throw new Error('يُقبل فقط رابط تشغيل GitHub Actions في مستودع NOVA المحدد.');
  }
  return {runId:parts[4], runUrl:'https://github.com/' + REPOSITORY + '/actions/runs/' + parts[4]};
}
async function checkGithubActionsRun(value, options = {}) {
  const {runId, runUrl} = parseGithubRunUrl(value);
  const fetchImpl = options.fetchImpl || fetch;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const headers = {accept:'application/vnd.github+json', 'x-github-api-version':'2022-11-28'};
    if (options.token) headers.authorization = 'Bearer ' + options.token;
    const base = 'https://api.github.com/repos/' + REPOSITORY + '/actions/runs/' + runId;
    const runResponse = await fetchImpl(base, {headers, signal:controller.signal});
    if (!runResponse.ok) throw new Error('GitHub run lookup failed with HTTP ' + runResponse.status + '.');
    const run = await runResponse.json();
    if (String(run.id) !== runId || (run.head_repository?.full_name && run.head_repository.full_name !== REPOSITORY)) {
      throw new Error('GitHub returned a run outside the configured NOVA repository.');
    }
    const jobsResponse = await fetchImpl(base + '/jobs?per_page=100', {headers, signal:controller.signal});
    if (!jobsResponse.ok) throw new Error('GitHub job lookup failed with HTTP ' + jobsResponse.status + '.');
    const jobsPayload = await jobsResponse.json();
    const jobs = Array.isArray(jobsPayload.jobs) ? jobsPayload.jobs : [];
    const verifiedSuccess = run.status === 'completed' && run.conclusion === 'success' &&
      jobs.length > 0 && jobs.every(job => job.status === 'completed' && job.conclusion === 'success');
    const failed = run.status === 'completed' && run.conclusion !== 'success';
    const state = verifiedSuccess ? 'succeeded' : failed ? 'failed' : run.status === 'completed' ? 'unknown' : 'running';
    const jobLines = jobs.map(job => ({
      name:String(job.name || 'job'),
      status:String(job.status || 'unknown'),
      conclusion:String(job.conclusion || ''),
      failedSteps:(Array.isArray(job.steps) ? job.steps : [])
        .filter(step => step.conclusion && !['success','skipped'].includes(step.conclusion))
        .map(step => String(step.name || 'step')),
    }));
    return {
      runId:Number(runId), runUrl, state, verifiedSuccess,
      status:String(run.status || 'unknown'), conclusion:String(run.conclusion || ''),
      branch:String(run.head_branch || ''), commit:String(run.head_sha || ''),
      jobs:jobLines,
      text:'حالة تشغيل GitHub Actions: ' + (verifiedSuccess ? 'نجاح مثبت' : failed ? 'فشل' : state === 'running' ? 'قيد التنفيذ' : 'حالة غير مكتملة أو غير معروفة') + '. عدد الوظائف: ' + jobs.length + '.',
    };
  } finally { clearTimeout(timeout); }
}
module.exports = {parseGithubRunUrl, checkGithubActionsRun};
