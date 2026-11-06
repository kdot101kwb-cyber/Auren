import crypto from 'node:crypto';

const DEFAULT_NAME = 'AUREN Agent';
const DEFAULT_VERSION = '1.0';
const MAX_NAME_LENGTH = 120;
const MAX_VERSION_LENGTH = 30;

function requireOwnerUid(uid) {
  if (typeof uid !== 'string' || !uid.trim() || uid.length > 128 || uid.includes('/')) {
    throw Object.assign(new Error('A valid owner uid is required.'), { code: 400 });
  }
  return uid.trim();
}

function boundedText(value, fallback, maxLength) {
  if (typeof value !== 'string') return fallback;
  const normalized = value.trim();
  if (!normalized || /[\u0000-\u001f\u007f]/.test(normalized)) return fallback;
  return normalized.slice(0, maxLength);
}

export function createAgentId(uid) {
  const ownerUid = requireOwnerUid(uid);
  return crypto.createHash('sha256').update(`auren:primary:${ownerUid}`).digest('hex').slice(0, 32);
}

export async function loadAgentIdentity(db, uid) {
  const ownerUid = requireOwnerUid(uid);
  const agentId = createAgentId(ownerUid);
  const ref = db.collection('users').doc(ownerUid).collection('agents').doc('primary');
  const snap = await ref.get();
  if (!snap.exists) {
    return { agentId, name: DEFAULT_NAME, version: DEFAULT_VERSION, ownerUid, status: 'active' };
  }
  const data = snap.data() || {};
  const allowedStatuses = new Set(['active', 'paused', 'suspended', 'revoked']);
  const status = typeof data.status === 'string' && allowedStatuses.has(data.status)
    ? data.status
    : 'active';
  return {
    agentId,
    name: boundedText(data.name, DEFAULT_NAME, MAX_NAME_LENGTH),
    version: boundedText(data.version, DEFAULT_VERSION, MAX_VERSION_LENGTH),
    ownerUid,
    status,
  };
}
