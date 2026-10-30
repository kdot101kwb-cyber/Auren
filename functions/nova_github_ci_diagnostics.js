'use strict';

const REPOSITORY = 'kdot101kwb-cyber/Auren';
const MAX_LOG_BYTES = 1500000;
const MAX_EVIDENCE_LINES = 12;
const MAX_LINE_LENGTH = 420;

function redactSensitiveText(value) {
  return String(value || '')
    .replace(/(authorization\\s*[:=]\\s*bearer\\s+)[^\\s,;]+/ig, '$1[REDACTED]')
    .replace(/(gh[pousr]_[A-Za-z0-9_]{20,})/g, '[REDACTED_GITHUB_TOKEN]')
    .replace(/(github_pat_[A-Za-z0-9_]{20,})/g, '[REDACTED_GITHUB_TOKEN]')
    .replace(/((?:api[_-]?key|access[_-]?token|secret|password)\\s*[:=]\\s*)[^\\s,;]+/ig, '$1[REDACTED]')
    .slice(0, MAX_LINE_LENGTH);
}

function extractFailureEvidence(logText) {
  const lines = String(logText || '').slice(0, MAX_LOG_BYTES).split(/\\r?\\n/);
  const matches = [];
  const seen = new Set();
  const pattern = /\\b(error|fatal|exception|failed|failure|denied|timed out|timeout|cannot find|not found|exit code [1-9])\\b|^\\s*✗/i;
  for (let index = 0; index < lines.length && matches.length < MAX_EVIDENCE_LINES; index += 1) {
    if (!pattern.test(lines[index])) continue;
    const text = redactSensitiveText(lines[index].trim());
    if (!text || seen.has(text)) continue;
    seen.add(text);
    matches.push({line: index + 1, text});
  }
  return matches;
}

async function fetchGithubActionsJobDiagnostics({runId, jobId, token, fetchImpl = fetch, timeoutMs = 20000}) {
  if (!/^\\d+$/.test(String(runId || '')) || !/^\\d+$/.test(String(jobId || ''))) {
    throw new Error('A valid GitHub Actions run ID and job ID are required.');
  }
  if (!token || !String(token).trim()) {
    return {status:'not_configured', message:'اضبط سر NOVA_GITHUB_TOKEN بصلاحية Actions: read لقراءة سجلات الوظائف الخاصة.'};
  }
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const headers = {
      accept:'application/vnd.github+json',
      authorization:'Bearer ' + String(token).trim(),
      'x-github-api-version':'2022-11-28',
    };
    const jobResponse = await fetchImpl(
      'https://api.github.com/repos/' + REPOSITORY + '/actions/jobs/' + jobId,
      {headers, signal:controller.signal},
    );
    if (!jobResponse.ok) throw new Error('GitHub job lookup failed with HTTP ' + jobResponse.status + '.');
    const job = await jobResponse.json();
    if (String(job.id) !== String(jobId) || String(job.run_id) !== String(runId)) {
      throw new Error('GitHub job does not belong to the verified workflow run.');
    }
    if (job.status !== 'completed' || !job.conclusion || ['success','skipped'].includes(job.conclusion)) {
      return {status:'not_needed', jobId:Number(jobId), message:'لا توجد وظيفة فاشلة مكتملة لتحليل سجلها.'};
    }
    const logResponse = await fetchImpl(
      'https://api.github.com/repos/' + REPOSITORY + '/actions/jobs/' + jobId + '/logs',
      {headers:{...headers, accept:'application/vnd.github+json'}, signal:controller.signal, redirect:'follow'},
    );
    if (!logResponse.ok) throw new Error('GitHub job log download failed with HTTP ' + logResponse.status + '.');
    const logText = await logResponse.text();
    const evidence = extractFailureEvidence(logText);
    return {
      status:'available',
      jobId:Number(jobId),
      jobName:String(job.name || 'job').slice(0,120),
      conclusion:String(job.conclusion || ''),
      failedSteps:(Array.isArray(job.steps) ? job.steps : [])
        .filter(step => step.conclusion && !['success','skipped'].includes(step.conclusion))
        .map(step => String(step.name || 'step').slice(0,120)).slice(0,10),
      evidence,
      truncated:logText.length > MAX_LOG_BYTES,
      message:evidence.length ? 'تم استخراج مؤشرات الفشل من سجل الوظيفة دون حفظ السجل الكامل.' :
        'تم تنزيل السجل، لكن لم تُعثر على أسطر خطأ واضحة؛ راجع سجل CircleCI أو تفاصيل الوظيفة.',
    };
  } finally {
    clearTimeout(timeout);
  }
}

async function diagnoseGithubActionsRun(result, token, options = {}) {
  if (!result || result.state !== 'failed') return {status:'not_needed', failedJobs:[]};
  const failedJobs = (Array.isArray(result.jobs) ? result.jobs : [])
    .filter(job => job.conclusion && !['success','skipped'].includes(job.conclusion) && job.status === 'completed');
  if (!failedJobs.length) return {status:'unavailable', failedJobs:[], message:'انتهى التشغيل بالفشل لكن لم تُحدد وظيفة فاشلة.'};
  if (!token) return {status:'not_configured', failedJobs:[], message:'يلزم ضبط NOVA_GITHUB_TOKEN بصلاحية Actions: read لتحليل السجلات.'};
  const diagnostics = [];
  for (const job of failedJobs.slice(0,5)) {
    try {
      diagnostics.push(await fetchGithubActionsJobDiagnostics({
        runId:result.runId, jobId:job.jobId, token, fetchImpl:options.fetchImpl,
      }));
    } catch (error) {
      diagnostics.push({
        status:'unavailable',
        jobId:job.jobId,
        jobName:job.name,
        message:redactSensitiveText(error && error.message || error),
      });
    }
  }
  return {
    status:diagnostics.some(item => item.status === 'available') ? 'available' : 'unavailable',
    failedJobs:diagnostics,
    message:'تحليل سجلات القراءة فقط؛ لم تُنفذ أي تغييرات على المستودع.',
  };
}

module.exports = {redactSensitiveText, extractFailureEvidence, fetchGithubActionsJobDiagnostics, diagnoseGithubActionsRun};
