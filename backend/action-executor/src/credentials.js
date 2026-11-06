import crypto from 'node:crypto';

function requireAgentId(agentId) {
  if (typeof agentId !== 'string' || !/^[a-zA-Z0-9._:-]{1,128}$/.test(agentId)) {
    throw Object.assign(new Error('A valid agent id is required.'), { code: 400 });
  }
  return agentId;
}

export function createCredentialFingerprint(agentId) {
  const validAgentId = requireAgentId(agentId);
  return crypto.createHash('sha256').update(`auren:credential:${validAgentId}`).digest('hex');
}

export function publicCredential(agentId) {
  const fingerprint = createCredentialFingerprint(agentId);
  return {
    credentialId: `cred_${fingerprint.slice(0, 24)}`,
    scheme: 'agent-bound',
    status: 'active',
  };
}
