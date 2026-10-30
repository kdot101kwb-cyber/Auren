'use strict';

const MAX_PATCH_FILES = 5;
const MAX_PATCH_BYTES = 64 * 1024;
const ALLOWED_REPAIR_STATES = new Set([
  'proposed', 'awaiting_approval', 'approved', 'applying',
  'validation_pending', 'verified', 'rejected', 'failed',
]);

function normalizeRepairPath(value) {
  const path = String(value || '').trim();
  if (!path || path.length > 240 || path.startsWith('/') || path.includes('\\') ||
      path.split('/').some(part => !part || part === '.' || part === '..') ||
      /^[A-Za-z]:/.test(path)) {
    throw new Error('Repair patch contains an invalid repository path.');
  }

  const allowedNova = /^nova_ai\/(?:lib|test)\/[A-Za-z0-9_./-]+\.(?:dart|yaml)$/;
  const allowedFunctions = /^functions\/nova_[A-Za-z0-9_-]+(?:\.test)?\.js$/;
  if (!allowedNova.test(path) && !allowedFunctions.test(path)) {
    throw new Error('Repair patch path is outside the NOVA source/test allowlist.');
  }
  if (/(?:secret|credential|\.env|firebase_options|google-services|service-account|firestore\.rules|storage\.rules|package-lock|pubspec\.lock)/i.test(path)) {
    throw new Error('Repair patch cannot modify secrets, lockfiles, Firebase rules, or deployment configuration.');
  }
  return path;
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
    const text = String(item?.text || '').trim();
    if (!text || text.length > 420) throw new Error('Failure evidence must be non-empty and bounded.');
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
  if (!result || result.commitSha !== result.validatedCommitSha ||
      !/^[a-f0-9]{40}$/i.test(String(result.validatedCommitSha || ''))) {
    return {...proposal, state:'failed', validation:{status:'failed', reason:'Validation did not target the exact repair commit.'}};
  }
  const checks = Array.isArray(result.checks) ? result.checks : [];
  if (!checks.length || checks.some(check => check.conclusion !== 'success')) {
    return {...proposal, state:'failed', validation:{status:'failed', checks:checks.slice(0,20)}};
  }
  return {...proposal, state:'verified', validation:{status:'success', validatedCommitSha:result.validatedCommitSha, checks:checks.slice(0,20)}};
}

module.exports = {
  MAX_PATCH_FILES,
  MAX_PATCH_BYTES,
  ALLOWED_REPAIR_STATES,
  normalizeRepairPath,
  validatePatchSet,
  createRepairProposal,
  approveRepairProposal,
  canApplyRepairProposal,
  evaluateRepairValidation,
};
