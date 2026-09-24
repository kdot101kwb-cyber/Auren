import crypto from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

const MAX_PACKAGE_BYTES = 5 * 1024 * 1024;
const MAX_DAILY_INVOCATIONS = 10000;
const MAX_DEPENDENCIES = 50;
const SAFE_DEPENDENCY = /^[a-z0-9][a-z0-9@._/-]{0,119}$/;
const UNSAFE_DEPENDENCY_PATH = /(^|\/)\.\.(\/|$)|(^|\/)\.(\/|$)/;
const SAFE_ID = /^[a-z0-9][a-z0-9._-]{2,63}$/;
const SAFE_VERSION = /^[A-Za-z0-9][A-Za-z0-9._+-]{0,63}$/;

const SUSPICIOUS_PATTERNS = Object.freeze([
  { name: 'child_process', pattern: /\b(?:require\(|from\s+|import\s*\(|import\s+)\s*['"](?:node:)?child_process['"]/ },
  { name: 'process_exec', pattern: /\bprocess\.(?:binding|dlopen|abort|kill)\b/ },
  { name: 'dynamic_eval', pattern: /\b(?:eval|Function)\s*\(/ },
  { name: 'network_module', pattern: /\b(?:node:net|node:dgram|node:http|node:https|node:tls|node:http2)\b/ },
  { name: 'filesystem_module', pattern: /\b(?:node:fs|node:fs\/promises|node:module)\b/ },
  { name: 'os_module', pattern: /\b(?:node:os|node:worker_threads|node:v8)\b/ },
  { name: 'process_environment', pattern: /\bprocess\.env\b/ },
]);

export function validateArtifactId(value) {
  if (typeof value !== 'string' || !SAFE_ID.test(value)) {
    throw Object.assign(new Error('Invalid plugin artifact id.'), { code: 400 });
  }
  return value;
}

export function artifactObjectPath(agentId, artifactId) {
  if (typeof agentId !== 'string' || !agentId || !SAFE_ID.test(artifactId)) {
    throw Object.assign(new Error('Invalid plugin artifact reference.'), { code: 400 });
  }
  return `plugin-artifacts/${agentId}/${artifactId}/entrypoint.js`;
}

export function createArtifactId() {
  return 'art_' + crypto.randomUUID();
}

export function packageSha256(bytes) {
  return crypto.createHash('sha256').update(bytes).digest('hex');
}

export function scanPluginArtifact(bytes) {
  if (!Buffer.isBuffer(bytes)) {
    throw Object.assign(new Error('Plugin artifact bytes are required.'), { code: 400 });
  }
  if (bytes.includes(0)) {
    throw Object.assign(new Error('Plugin artifact contains invalid binary data.'), { code: 400 });
  }
  const source = bytes.toString('utf8');
  const findings = SUSPICIOUS_PATTERNS
    .filter((entry) => entry.pattern.test(source))
    .map((entry) => entry.name);
  return { status: findings.length ? 'rejected' : 'passed', findings };
}

export function validateDependencyList(dependencies) {
  if (dependencies === undefined || dependencies === null) return [];
  if (!Array.isArray(dependencies) || dependencies.length > MAX_DEPENDENCIES) {
    throw Object.assign(new Error('Plugin dependency list is invalid.'), { code: 400 });
  }
  const unique = [...new Set(dependencies)];
  if (
    unique.length !== dependencies.length ||
    unique.some((value) => typeof value !== 'string' || !SAFE_DEPENDENCY.test(value) || UNSAFE_DEPENDENCY_PATH.test(value))
  ) {
    throw Object.assign(new Error('Plugin dependencies contain an invalid or duplicate package.'), { code: 400 });
  }
  return unique;
}

export function validatePackageMetadata(meta) {
  if (!meta || typeof meta !== 'object') {
    throw Object.assign(new Error('Invalid plugin package metadata.'), { code: 400 });
  }
  if (
    typeof meta.pluginId !== 'string' ||
    typeof meta.version !== 'string' ||
    !SAFE_ID.test(meta.pluginId) ||
    !SAFE_VERSION.test(meta.version) ||
    typeof meta.sha256 !== 'string' ||
    !/^[a-f0-9]{64}$/.test(meta.sha256)
  ) {
    throw Object.assign(new Error('Plugin package hash is required.'), { code: 400 });
  }
  const size = Number(meta.sizeBytes || 0);
  if (!Number.isInteger(size) || size < 1 || size > MAX_PACKAGE_BYTES) {
    throw Object.assign(new Error('Plugin package size exceeds the AUREN limit.'), { code: 400 });
  }
  return {
    pluginId: meta.pluginId,
    version: meta.version,
    sha256: meta.sha256,
    sizeBytes: size,
    dependencies: validateDependencyList(meta.dependencies),
  };
}

export function canonicalPackageSigningData(meta) {
  const normalized = validatePackageMetadata(meta);
  return JSON.stringify([
    normalized.pluginId,
    normalized.version,
    normalized.sha256,
    normalized.sizeBytes,
    normalized.dependencies,
  ]);
}

export function signPackage(meta, secret) {
  return crypto.createHmac('sha256', secret)
    .update(canonicalPackageSigningData(meta))
    .digest('hex');
}

export function verifyPackageSignature(meta, signature, secret) {
  if (typeof signature !== 'string' || signature.length !== 64) return false;
  const expected = signPackage(meta, secret);
  return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
}

export async function consumeQuota(db, agentId, pluginId) {
  const day = new Date().toISOString().slice(0, 10);
  const ref = db.collection('plugin_quotas').doc(agentId + '_' + pluginId + '_' + day);
  let used = 0;
  await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    used = Number(s.data()?.invocations || 0) + 1;
    if (used > MAX_DAILY_INVOCATIONS) {
      throw Object.assign(new Error('Plugin daily invocation quota exceeded.'), { code: 429 });
    }
    tx.set(ref, {
      agentId,
      pluginId,
      day,
      invocations: used,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  return { day, invocations: used, limit: MAX_DAILY_INVOCATIONS };
}

export const pluginSecurityLimits = Object.freeze({
  maxPackageBytes: MAX_PACKAGE_BYTES,
  dailyInvocations: MAX_DAILY_INVOCATIONS,
  maxDependencies: MAX_DEPENDENCIES,
});