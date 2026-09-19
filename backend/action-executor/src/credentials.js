import crypto from 'node:crypto';

export function createCredentialFingerprint(agentId) {
  return crypto.createHash('sha256').update(`auren:credential:${agentId}`).digest('hex');
}

export function publicCredential(agentId) {
  return {
    credentialId: `cred_${createCredentialFingerprint(agentId).slice(0, 24)}`,
    scheme: 'agent-bound',
    status: 'active',
  };
}
