'use strict';

const MAX_EVIDENCE_LINES = 10;
const MAX_LINE_LENGTH = 500;
const ALLOWED_PREFIXES = ['nova_ai/', 'functions/nova_'];
const BLOCKED_PATH = /(^|\/)(\.github|\.circleci|firebase|firestore|storage|secrets?)(\/|$)|(^|\/)(\.env[^/]*|firebase\.json|\.firebaserc|package-lock\.json)$/i;

function safeText(value, limit = MAX_LINE_LENGTH) {
  return String(value || '')
    .replace(/(?:Bearer\s+)[A-Za-z0-9._~+\/-]+=*/ig, 'Bearer [REDACTED]')
    .replace(/(gh[pousr]_[A-Za-z0-9_]{12,}|github_pat_[A-Za-z0-9_]{12,})/g, '[REDACTED]')
    .replace(/(token|secret|password|api[_-]?key)\s*[:=]\s*[^\s,;]+/ig, '$1=[REDACTED]')
    .replace(/[\r\n\t]+/g, ' ')
    .slice(0, limit);
}

function normalizeCandidatePath(value) {
  const path = String(value || '').trim().replace(/^\.\//, '');
  if (!path || path.includes('..') || path.startsWith('/') || BLOCKED_PATH.test(path)) return null;
  return ALLOWED_PREFIXES.some(prefix => path.startsWith(prefix)) ? path : null;
}

function classifyEvidence(lines) {
  const joined = lines.join('\n').toLowerCase();
  if (/flutter analyze|dart analyze|analysis_options|\.dart:\d+:\d+/.test(joined)) {
    return {
      category: 'flutter_static_analysis',
      likelyAreas: ['nova_ai/lib/'],
      checks: ['Reproduce the exact Flutter analyze command', 'Inspect the referenced Dart diagnostics and nearby code', 'Add or update a focused regression test'],
    };
  }
  if (/node --test|npm test|assertionerror|test failed|functions\/.*\.js/.test(joined)) {
    return {
      category: 'node_functions_test',
      likelyAreas: ['functions/nova_'],
      checks: ['Run the smallest failing Node test first', 'Trace the failing assertion to its owning NOVA module', 'Add a regression test before proposing a code change'],
    };
  }
  if (/gradle|assembledebug|android build|manifest merger/.test(joined)) {
    return {
      category: 'android_build',
      likelyAreas: ['nova_ai/'],
      checks: ['Reproduce the same Android debug build in CI', 'Inspect the first Gradle or manifest error, not only the final summary', 'Keep signing files and build secrets out of the patch'],
    };
  }
  return {
    category: 'unclassified',
    likelyAreas: [],
    checks: ['Collect the first failing step and a bounded error excerpt', 'Identify the owning module before proposing a patch'],
  };
}

function buildSelfRepairProposal(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new TypeError('Repair input must be an object.');
  }
  const provider = String(input.provider || '');
  if (!['github_actions', 'circleci'].includes(provider)) {
    throw new TypeError('Unsupported CI provider.');
  }
  const runUrl = String(input.runUrl || '');
  let parsed;
  try { parsed = new URL(runUrl); } catch { throw new TypeError('A valid CI run URL is required.'); }
  const validHost = provider === 'github_actions'
    ? parsed.hostname === 'github.com' && parsed.pathname.startsWith('/kdot101kwb-cyber/Auren/actions/runs/')
    : parsed.hostname === 'circleci.com' && /^\/gh\/kdot101kwb-cyber\/Auren\/\d+$/.test(parsed.pathname);
  if (parsed.protocol !== 'https:' || !validHost || parsed.username || parsed.password) {
    throw new TypeError('CI run URL is outside the configured AUREN project.');
  }
  const commit = String(input.commit || '');
  if (commit && !/^[a-f0-9]{7,40}$/i.test(commit)) {
    throw new TypeError('Commit must be a hexadecimal Git SHA.');
  }
  const rawLines = Array.isArray(input.evidence) ? input.evidence : [];
  const evidence = rawLines.slice(0, MAX_EVIDENCE_LINES)
    .map(line => safeText(line))
    .filter(Boolean);
  const classified = classifyEvidence(evidence);
  const candidatePaths = Array.isArray(input.candidatePaths)
    ? [...new Set(input.candidatePaths.map(normalizeCandidatePath).filter(Boolean))].slice(0, 8)
    : [];
  const likelyAreas = [...new Set([...classified.likelyAreas, ...candidatePaths.map(path => path.slice(0, path.lastIndexOf('/') + 1))])];
  const hasEvidence = evidence.length > 0;
  const summary = hasEvidence
    ? 'تم إعداد خطة إصلاح مبدئية من أدلة CI؛ لم يتم تعديل أي ملف.'
    : 'الأدلة غير كافية لإعداد خطة إصلاح محددة؛ لم يتم تعديل أي ملف.';
  return {
    status: hasEvidence ? 'proposal_only' : 'insufficient_evidence',
    provider,
    runUrl: parsed.toString(),
    commit: commit || null,
    category: classified.category,
    summary,
    evidence,
    likelyAreas,
    candidatePaths,
    checks: classified.checks,
    safety: {
      filesChanged: 0,
      patchGenerated: false,
      branchCreated: false,
      pullRequestCreated: false,
      merged: false,
      deployed: false,
      humanApprovalRequired: true,
      blockedPaths: ['.github/', '.circleci/', 'firebase.json', '.firebaserc', 'Firestore/Storage rules', 'secrets', '.env*'],
    },
  };
}

module.exports = {buildSelfRepairProposal, normalizeCandidatePath, classifyEvidence};
