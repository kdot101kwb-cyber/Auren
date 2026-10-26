'use strict';

// Shared policy for a future isolated NOVA build runner.
// This module does not execute prompts, shell commands, or build jobs.
const APPROVAL_ACTIONS = new Set([
  'deploy',
  'publish',
  'merge',
  'production_secret_change',
  'github_write',
  'external_publish',
]);
const SAFE_STATUSES = new Set(['queued', 'running', 'succeeded', 'failed', 'cancelled']);

function isClaimable(queueItem) {
  if (!queueItem || typeof queueItem !== 'object') return false;
  const attempts = Number.isInteger(queueItem.attempts) ? queueItem.attempts : 0;
  const maxAttempts = Number.isInteger(queueItem.maxAttempts) ? queueItem.maxAttempts : 3;
  return queueItem.status === 'queued' && attempts >= 0 && maxAttempts > 0 && attempts < maxAttempts;
}

function requiresApproval(action) {
  return typeof action === 'string' && APPROVAL_ACTIONS.has(action);
}

function validateJobForRunner(job) {
  if (!job || typeof job !== 'object') return { ok: false, reason: 'invalid_job' };
  if (!/^[a-f0-9]{32}$/.test(String(job.jobId || ''))) return { ok: false, reason: 'invalid_job_id' };
  if (typeof job.ownerUid !== 'string' || job.ownerUid.length < 1 || job.ownerUid.length > 128) {
    return { ok: false, reason: 'invalid_owner' };
  }
  if (!['flutter_app', 'web_app', 'landing_page', 'debug_existing', 'redesign_existing'].includes(job.type)) {
    return { ok: false, reason: 'unsupported_task_type' };
  }
  if (!['flutter', 'web', 'static_web', 'auto'].includes(job.stack)) {
    return { ok: false, reason: 'unsupported_stack' };
  }
  if (typeof job.prompt !== 'string' || job.prompt.trim().length < 12 || job.prompt.length > 12000) {
    return { ok: false, reason: 'invalid_prompt' };
  }
  // Explicitly reject fields that could smuggle arbitrary execution instructions.
  for (const key of ['command', 'shell', 'script', 'exec', 'run', 'workflow', 'token', 'accessToken', 'githubToken']) {
    if (Object.prototype.hasOwnProperty.call(job, key)) return { ok: false, reason: 'forbidden_execution_field' };
  }
  return { ok: true, job: { jobId: job.jobId, ownerUid: job.ownerUid, type: job.type, stack: job.stack, prompt: job.prompt.trim() } };
}

function validateArtifactManifest(artifacts) {
  if (!Array.isArray(artifacts) || artifacts.length > 50) {
    return { ok: false, reason: 'invalid_artifact_manifest' };
  }
  const normalized = [];
  for (const item of artifacts) {
    if (!item || typeof item !== 'object' || typeof item.path !== 'string') {
      return { ok: false, reason: 'invalid_artifact' };
    }
    const path = item.path.replace(/\\/g, '/');
    if (!path || path.startsWith('/') || /^[a-zA-Z]:/.test(path) ||
        path.split('/').some(part => part === '..' || part === '.' || part.length === 0) ||
        path.length > 240) {
      return { ok: false, reason: 'unsafe_artifact_path' };
    }
    if (!Number.isInteger(item.sizeBytes) || item.sizeBytes < 0 || item.sizeBytes > 250 * 1024 * 1024) {
      return { ok: false, reason: 'invalid_artifact_size' };
    }
    normalized.push({ path, sizeBytes: item.sizeBytes });
  }
  return { ok: true, artifacts: normalized };
}

function evaluateRunnerResult(result) {
  if (!result || typeof result !== 'object' || !Array.isArray(result.checks)) {
    return { status: 'failed', reason: 'missing_checks' };
  }
  if (result.checks.length === 0 || result.checks.length > 100) {
    return { status: 'failed', reason: 'invalid_checks' };
  }
  const allPassed = result.checks.every(check =>
    check && typeof check === 'object' &&
    typeof check.name === 'string' && check.name.trim().length > 0 &&
    check.conclusion === 'success'
  );
  if (!allPassed) return { status: 'failed', reason: 'checks_not_all_successful' };
  const manifest = validateArtifactManifest(result.artifacts || []);
  if (!manifest.ok) return { status: 'failed', reason: manifest.reason };
  return { status: 'succeeded', checks: result.checks, artifacts: manifest.artifacts };
}

function assertKnownStatus(status) {
  return SAFE_STATUSES.has(status);
}

module.exports = {
  APPROVAL_ACTIONS,
  isClaimable,
  requiresApproval,
  validateJobForRunner,
  validateArtifactManifest,
  evaluateRunnerResult,
  assertKnownStatus,
};
