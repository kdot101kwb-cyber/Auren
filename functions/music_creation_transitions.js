'use strict';

function resolveMusicSubmission({result, artifactCheck}) {
  // Provider adapters return the normalized payload directly; accept the older
  // wrapped form as well so callers cannot silently lose accepted jobs.
  const payload = result?.result && typeof result.result === 'object' ? result.result : result;
  const output = payload?.output;
  const externalId = String(payload?.externalJobId || '').trim();
  const candidate = Boolean(output && (output.url || output.storagePath));
  const validArtifact = Boolean(candidate && artifactCheck?.ok);
  const validationReason = artifactCheck?.reason || 'artifact_validation_unavailable';
  const status = !result?.ok
    ? 'queued'
    : validArtifact
      ? 'output'
      : externalId
        ? 'processing'
        : candidate
          ? 'queued'
          : 'failed';

  return {
    status,
    output: validArtifact ? output : null,
    externalJobId: validArtifact ? '' : externalId,
    providerState: !result?.ok
      ? 'submission_unavailable'
      : validArtifact
        ? (payload?.state || 'succeeded')
        : candidate
          ? 'artifact_validation_failed'
          : (payload?.state || 'starting'),
    ...(candidate ? {artifactValidation: artifactCheck || {ok: false, reason: validationReason}} : {}),
    lastError: !result?.ok
      ? String(result.message || 'Provider unavailable').slice(0, 700)
      : validArtifact
        ? ''
        : candidate
          ? 'Music output failed artifact validation: ' + artifactCheck.reason
          : externalId
            ? ''
            : 'Provider returned no artifact.',
  };
}

function resolveMusicPoll({pollResult, attempts, maxAttempts, artifactCheck}) {
  const p = pollResult || {};
  if (p.ok && (p.state === 'succeeded' || p.state === 'completed')) {
    const output = p.output;
    const candidate = Boolean(output && (output.url || output.storagePath));
    const check = candidate
      ? artifactCheck
      : {ok: false, reason: 'artifact_not_materialized'};
    if (check?.ok) {
      return {
        status: 'output',
        output,
        artifactValidation: check,
        externalJobId: '',
        lockUntilMs: 0,
        providerState: p.state,
        lastError: '',
      };
    }
    return {
      status: 'waiting_provider',
      output: null,
      externalJobId: '',
      lockUntilMs: 0,
      providerState: 'artifact_validation_failed',
      lastError: 'Music output failed artifact validation: ' + check.reason,
      artifactValidation: check,
    };
  }

  if (p.state === 'failed' || p.state === 'canceled') {
    return {
      status: Number(attempts || 0) < maxAttempts ? 'queued' : 'failed',
      externalJobId: '',
      lockUntilMs: 0,
      lastError: String(p.error || 'Music provider failed').slice(0, 700),
    };
  }

  return {
    status: 'processing',
    lockUntilMs: 0,
    providerState: p.state || 'processing',
  };
}

module.exports = {resolveMusicSubmission, resolveMusicPoll};
