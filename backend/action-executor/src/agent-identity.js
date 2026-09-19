import crypto from 'node:crypto';

export function createAgentId(uid) {
  return crypto.createHash('sha256').update(`auren:primary:${uid}`).digest('hex').slice(0, 32);
}

export async function loadAgentIdentity(db, uid) {
  const agentId = createAgentId(uid);
  const ref = db.collection('users').doc(uid).collection('agents').doc('primary');
  const snap = await ref.get();
  if (!snap.exists) {
    return { agentId, name: 'AUREN Agent', version: '1.0', ownerUid: uid, status: 'active' };
  }
  const data = snap.data();
  return {
    agentId,
    name: typeof data.name === 'string' ? data.name : 'AUREN Agent',
    version: typeof data.version === 'string' ? data.version : '1.0',
    ownerUid: uid,
    status: typeof data.status === 'string' ? data.status : 'active',
  };
}
