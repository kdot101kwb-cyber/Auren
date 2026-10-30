'use strict';

const PROJECT_SLUG = 'gh/kdot101kwb-cyber/Auren';
const VCS_SLUG = 'github/kdot101kwb-cyber/Auren';
const ALLOWED_OUTPUT_HOSTS = new Set(['output.circle-artifacts.com']);

function parseCircleCiJobUrl(value) {
  let url;
  try { url = new URL(String(value || '').trim()); } catch (_) {
    throw new Error('أرسل رابط وظيفة CircleCI صحيحاً.');
  }
  const parts = url.pathname.split('/').filter(Boolean);
  if (url.protocol !== 'https:' || url.hostname !== 'circleci.com' ||
      parts.length !== 4 || parts[0] !== 'gh' ||
      parts[1] !== 'kdot101kwb-cyber' || parts[2] !== 'Auren' ||
      !/^\d+$/.test(parts[3]) || url.search || url.hash) {
    throw new Error('يُقبل فقط رابط وظيفة CircleCI في مستودع AUREN المحدد.');
  }
  return {
    jobNumber:Number(parts[3]),
    jobUrl:'https://circleci.com/gh/kdot101kwb-cyber/Auren/' + parts[3],
  };
}

function safeOutputUrl(value) {
  let url;
  try { url = new URL(String(value || '')); } catch (_) { return null; }
  if (url.protocol !== 'https:' || !ALLOWED_OUTPUT_HOSTS.has(url.hostname) ||
      url.username || url.password) return null;
  return url.toString();
}

function extractCircleCiMessages(payload) {
  let messages = [];
  try {
    const parsed = JSON.parse(String(payload || ''));
    if (Array.isArray(parsed)) messages = parsed.map(item => item?.message).filter(value => typeof value === 'string');
    else if (typeof parsed?.message === 'string') messages = [parsed.message];
  } catch (_) {
    messages = String(payload || '').split(/\r?\n/);
  }
  return messages;
}

function redactCircleCiLine(value) {
  return String(value || '')
    .replace(/(authorization\s*[:=]\s*bearer\s+)[^\s,;]+/ig, '$1[REDACTED]')
    .replace(/(circle-token\s*[:=]\s*)[^\s,;]+/ig, '$1[REDACTED]')
    .replace(/(gh[pousr]_[A-Za-z0-9_]{20,})/g, '[REDACTED_GITHUB_TOKEN]')
    .replace(/(github_pat_[A-Za-z0-9_]{20,})/g, '[REDACTED_GITHUB_TOKEN]')
    .replace(/((?:api[_-]?key|access[_-]?token|secret|password)\s*[:=]\s*)[^\s,;]+/ig, '$1[REDACTED]')
    .slice(0, 420);
}

function extractCircleCiFailureEvidence(messages, maxLines = 12) {
  const pattern = /\b(error|fatal|exception|failed|failure|denied|timed out|timeout|cannot find|not found|exit code [1-9])\b|^\s*✗/i;
  const found = [];
  const seen = new Set();
  for (let index = 0; index < messages.length && found.length < maxLines; index += 1) {
    const message = String(messages[index] || '');
    if (!pattern.test(message)) continue;
    const text = redactCircleCiLine(message.trim());
    if (!text || seen.has(text)) continue;
    seen.add(text);
    found.push({line:index + 1, text});
  }
  return found;
}

async function checkCircleCiJob(value, options = {}) {
  const {jobNumber, jobUrl} = parseCircleCiJobUrl(value);
  const token = String(options.token || '').trim();
  if (!token) {
    return {state:'unknown', jobNumber, jobUrl, diagnostics:{status:'not_configured', failedSteps:[], evidence:[]},
      text:'يلزم إعداد سر CIRCLECI_TOKEN للاتصال بواجهة CircleCI الخاصة.'};
  }
  const fetchImpl = options.fetchImpl || fetch;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), options.timeoutMs || 25000);
  try {
    const detailsUrl = 'https://circleci.com/api/v1.1/project/' + VCS_SLUG + '/' + jobNumber;
    const response = await fetchImpl(detailsUrl, {
      headers:{'Circle-Token':token, accept:'application/json'},
      signal:controller.signal,
    });
    if (!response.ok) throw new Error('CircleCI job lookup failed with HTTP ' + response.status + '.');
    const job = await response.json();
    if (Number(job.build_num) !== jobNumber ||
        (job.vcs_url && job.vcs_url !== 'https://github.com/kdot101kwb-cyber/Auren' &&
          job.vcs_url !== 'https://github.com/kdot101kwb-cyber/Auren.git')) {
      throw new Error('CircleCI returned a job outside the configured AUREN project.');
    }
    const status = String(job.status || 'unknown').toLowerCase();
    const state = status === 'success' ? 'succeeded' :
      ['failed','infrastructure_fail','timedout','terminated'].includes(status) ? 'failed' :
      ['running','queued','not_running'].includes(status) ? 'running' : 'unknown';
    const failedActions = [];
    for (const step of (Array.isArray(job.steps) ? job.steps : [])) {
      for (const action of (Array.isArray(step.actions) ? step.actions : [])) {
        const failed = action.status && !['success','skipped'].includes(String(action.status).toLowerCase());
        if (failed || action.exit_code && Number(action.exit_code) !== 0) {
          failedActions.push({step:String(step.name || action.name || 'step'), action, stepIndex:step.step});
        }
      }
    }
    const diagnostics = {status:state === 'failed' ? 'available' : 'not_needed', failedSteps:[], evidence:[]};
    if (state === 'failed') {
      for (const item of failedActions.slice(0,8)) {
        const outputUrl = item.action.has_output ? safeOutputUrl(item.action.output_url) : null;
        let evidence = [];
        let outputStatus = outputUrl ? 'available' : 'no_output';
        if (outputUrl) {
          try {
            const outputResponse = await fetchImpl(outputUrl, {signal:controller.signal, redirect:'follow'});
            if (!outputResponse.ok) throw new Error('CircleCI step output HTTP ' + outputResponse.status + '.');
            const payload = await outputResponse.text();
            let messages = [];
            try {
              const parsed = JSON.parse(payload);
              messages = Array.isArray(parsed) ? parsed.map(row => row?.message).filter(row => typeof row === 'string') : [];
            } catch (_) { messages = payload.split(/\r?\n/); }
            evidence = extractCircleCiFailureEvidence(messages, 12);
          } catch (error) {
            outputStatus = 'unavailable';
          }
        }
        diagnostics.failedSteps.push({
          name:item.step,
          status:String(item.action.status || 'failed'),
          exitCode:item.action.exit_code ?? null,
          outputStatus,
          evidence,
        });
      }
      diagnostics.status = diagnostics.failedSteps.some(step => step.evidence.length) ? 'available' : 'unavailable';
      diagnostics.message = 'تحليل سجلات CircleCI للقراءة فقط؛ لم تُنفذ أي تغييرات.';
    }
    return {
      state, jobNumber, jobUrl, status,
      name:String(job.workflows?.job_name || job.build_parameters?.CIRCLE_JOB || job.project?.name || 'CircleCI job'),
      branch:String(job.branch || ''),
      commit:String(job.vcs_revision || ''),
      diagnostics,
      text:'حالة وظيفة CircleCI: ' + (state === 'succeeded' ? 'نجاح مثبت' : state === 'failed' ? 'فشل' :
        state === 'running' ? 'قيد التنفيذ' : 'تعذر التحقق بالكامل') + '.',
    };
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = {
  parseCircleCiJobUrl,
  safeOutputUrl,
  extractCircleCiMessages,
  extractCircleCiFailureEvidence,
  checkCircleCiJob,
};
