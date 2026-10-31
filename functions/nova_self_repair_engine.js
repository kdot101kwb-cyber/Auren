'use strict';

const MAX_PATCH_FILES = 5;
const MAX_PATCH_BYTES = 64 * 1024;
const ALLOWED_REPAIR_STATES = new Set([
  'proposed', 'awaiting_approval', 'approved', 'applying',
  'validation_pending', 'verified', 'recovery_required', 'rejected', 'failed',
]);

function normalizeRepairPath(value) {
  const path = String(value || '').trim();
  if (!path || path.length > 240 || path.startsWith('/') || path.includes('\\') ||
      path.split('/').some(part => !part || part === '.' || part === '..') ||
      /^[A-Za-z]:/.test(path)) {
    throw new Error('Repair patch contains an invalid repository path.');
  }

  const allowedNova = /^nova_ai\/(?:lib|test)\/[A-Za-z0-9_./-]+\.(?:dart|yaml)$/;
  const allowedFunctions = /^functions\/nova_[A-Za-z0-9_-]+\.js$/;
  if (!allowedNova.test(path) && !allowedFunctions.test(path)) {
    throw new Error('Repair patch path is outside the NOVA source/test allowlist.');
  }
  if (/(?:secret|credential|\.env|firebase_options|google-services|service-account|firestore\.rules|storage\.rules|package-lock|pubspec\.lock)/i.test(path)) {
    throw new Error('Repair patch cannot modify secrets, lockfiles, Firebase rules, or deployment configuration.');
  }
  return path;
}

function redactRepairEvidence(value) {
  return String(value || '')
    .replace(/(authorization\s*[:=]\s*bearer\s+)[^\s,;]+/ig, '$1[REDACTED]')
    .replace(/(circle-token\s*[:=]\s*)[^\s,;]+/ig, '$1[REDACTED]')
    .replace(/\b(?:sk-or-v1-[A-Za-z0-9_-]{16,}|sk-[A-Za-z0-9_-]{20,})\b/g, '[REDACTED_AI_TOKEN]')
    .replace(/(gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})/g, '[REDACTED_TOKEN]')
    .replace(/\bAKIA[0-9A-Z]{16}\b/g, '[REDACTED_AWS_KEY]')
    .replace(/\bAIza[0-9A-Za-z_-]{30,}\b/g, '[REDACTED_GOOGLE_KEY]')
    .replace(/((?:api[_-]?key|access[_-]?token|token|secret|password)\s*[:=]\s*)[^\s,;]+/ig, '$1[REDACTED]')
    .replace(/-----BEGIN [A-Z ]*PRIVATE KEY-----/g, '[REDACTED_PRIVATE_KEY]')
    .slice(0, 420);
}

function containsCredentialMaterial(value) {
  const text = String(value || '');
  return /(?:sk-or-v1-[A-Za-z0-9_-]{16,}|sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|authorization\\s*:\\s*bearer\\s+\\S{20,}|circle-token\\s*[:=]\\s*\\S{12,}|(?:api[_-]?key|access[_-]?token|refresh[_-]?token|auth[_-]?token|token|secret|password)\\s*[:=]\\s*['\"][^'\"]{12,}['\"])/i.test(text) ||
    /(?:api[_-]?key|access[_-]?token|refresh[_-]?token|auth[_-]?token|token|secret|password)\s*[:=]\s*['"]?(?!process\.env\b|env\.)[A-Za-z0-9_./+=-]{12,}/i.test(text);
}

function validatePatchSet(files) {
  if (!Array.isArray(files) || files.length < 1 || files.length > MAX_PATCH_FILES) {
    throw new Error('A repair patch must contain between 1 and ' + MAX_PATCH_FILES + ' files.');
  }
  const seen = new Set();
  let totalBytes = 0;
  const normalized = files.map((file) => {
    if (!file || typeof file !== 'object' || Array.isArray(file)) {
      throw new Error('Each repair patch file must be an object.');
    }
    const path = normalizeRepairPath(file.path);
    if (seen.has(path)) throw new Error('Repair patch contains a duplicate path.');
    seen.add(path);
    const content = file.content;
    if (typeof content !== 'string') throw new Error('Repair patch content must be UTF-8 text.');
    if (containsCredentialMaterial(content)) {
      throw new Error('Repair patch appears to contain credential material.');
    }
    const bytes = Buffer.byteLength(content, 'utf8');
    totalBytes += bytes;
    if (bytes > MAX_PATCH_BYTES || totalBytes > MAX_PATCH_BYTES) {
      throw new Error('Repair patch exceeds the 64 KiB content limit.');
    }
    const expectedSha = String(file.expectedSha || '');
    if (!/^[a-f0-9]{40}$/i.test(expectedSha)) {
      throw new Error('Every repair file must include its current blob SHA.');
    }
    const reason = String(file.reason || '').trim().slice(0, 300);
    if (!reason) throw new Error('Every repair file must include a concise reason.');
    return {path, content, expectedSha, reason};
  });
  return {files:normalized, totalBytes};
}

function createRepairProposal(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new Error('Repair proposal input must be an object.');
  }
  const provider = String(input.provider || '');
  if (!['github_actions', 'circleci'].includes(provider)) {
    throw new Error('Repair proposal requires a supported CI provider.');
  }
  if (input.failureVerified !== true) {
    throw new Error('A verified CI failure is required before proposing a repair.');
  }
  const commitSha = String(input.commitSha || '');
  if (!/^[a-f0-9]{40}$/i.test(commitSha)) throw new Error('A verified 40-character source commit SHA is required.');
  const evidence = Array.isArray(input.evidence) ? input.evidence : [];
  if (!evidence.length || evidence.length > 12) {
    throw new Error('Repair proposal requires 1–12 bounded failure evidence items.');
  }
  const safeEvidence = evidence.map((item) => {
    const text = redactRepairEvidence(item?.text).trim();
    if (!text) throw new Error('Failure evidence must be non-empty and bounded.');
    return {source:String(item.source || provider).slice(0, 40), line:Number.isInteger(item.line) ? item.line : null, text};
  });
  const patchSet = validatePatchSet(input.files);
  const summary = String(input.summary || '').trim().slice(0, 1200);
  if (!summary) throw new Error('Repair proposal summary is required.');
  return {
    state:'awaiting_approval',
    provider,
    sourceCommitSha:commitSha,
    summary,
    evidence:safeEvidence,
    files:patchSet.files,
    patchBytes:patchSet.totalBytes,
    requiresOwnerApproval:true,
    createdBy:'nova_self_repair_engine',
    createdAt:input.createdAt || null,
  };
}

function approveRepairProposal(proposal, ownerUid, approvedBy) {
  if (!proposal || proposal.state !== 'awaiting_approval') {
    throw new Error('Only a proposal awaiting approval can be approved.');
  }
  if (!ownerUid || approvedBy !== ownerUid || proposal.requiresOwnerApproval !== true) {
    throw new Error('Repair approval must come from the owning user.');
  }
  return {...proposal, state:'approved', approvedBy:ownerUid};
}

function canApplyRepairProposal(proposal, ownerUid, targetBranch) {
  if (!proposal || proposal.state !== 'approved' || proposal.approvedBy !== ownerUid ||
      proposal.requiresOwnerApproval !== true) return false;
  if (!/^nova\/repairs\/[a-z0-9][a-z0-9-]{2,70}$/.test(String(targetBranch || ''))) return false;
  try {
    validatePatchSet(proposal.files);
    return true;
  } catch (_) {
    return false;
  }
}

function evaluateRepairValidation(proposal, result) {
  if (!proposal || !['applying', 'validation_pending'].includes(proposal.state)) {
    throw new Error('Repair validation requires an applied proposal.');
  }
  const expectedRepairSha = String(proposal.repairCommitSha || '');
  if (!result || !/^[a-f0-9]{40}$/i.test(expectedRepairSha) ||
      result.commitSha !== expectedRepairSha || result.validatedCommitSha !== expectedRepairSha) {
    return {...proposal, state:'failed', validation:{status:'failed', reason:'Validation did not target the exact repair commit.'}};
  }
  const checks = Array.isArray(result.checks) ? result.checks : [];
  const requiredChecks = Array.isArray(result.requiredChecks) ? result.requiredChecks : [];
  const byName = new Map(checks.map(check => [String(check.name || ''), check]));
  const missingOrFailed = requiredChecks.filter(name => byName.get(String(name))?.conclusion !== 'success');
  if (!requiredChecks.length || !checks.length || missingOrFailed.length || checks.some(check => check.conclusion !== 'success')) {
    return {...proposal, state:'failed', validation:{status:'failed', checks:checks.slice(0,20), missingOrFailed:missingOrFailed.slice(0,20)}};
  }
  return {...proposal, state:'verified', validation:{status:'success', validatedCommitSha:result.validatedCommitSha, checks:checks.slice(0,20), requiredChecks:requiredChecks.slice(0,20)}};
}

module.exports = {
  MAX_PATCH_FILES,
  MAX_PATCH_BYTES,
  ALLOWED_REPAIR_STATES,
  normalizeRepairPath,
  redactRepairEvidence,
  validatePatchSet,
  createRepairProposal,
  approveRepairProposal,
  canApplyRepairProposal,
  evaluateRepairValidation,
};