import crypto from 'node:crypto';

export const PROTOCOL_VERSION = '1.0';
export const AGENT_CAPABILITIES = Object.freeze([
  'actions.execute',
  'actions.discover',
  'messages.send',
  'commerce.request',
]);
export const MAX_ENVELOPE_BYTES = 64 * 1024;
const MAX_ID_LENGTH = 128;
const MAX_TYPE_LENGTH = 80;

export function createAgentEndpointId(agentId) {
  if (typeof agentId !== 'string' || !/^[a-zA-Z0-9._:-]{1,128}$/.test(agentId)) {
    throw Object.assign(new Error('A valid agent id is required.'), { code: 400 });
  }
  return crypto.createHash('sha256').update(`auren:agent-endpoint:${agentId}`).digest('hex').slice(0, 32);
}

export function validateEnvelope(envelope) {
  if (!envelope || typeof envelope !== 'object' || Array.isArray(envelope)) return false;
  if (envelope.protocol !== 'AUREN-A2A' || envelope.version !== PROTOCOL_VERSION) return false;
  for (const field of ['messageId', 'senderAgentId', 'recipientAgentId']) {
    if (typeof envelope[field] !== 'string' || !envelope[field].trim() || envelope[field].length > MAX_ID_LENGTH) {
      return false;
    }
  }
  if (envelope.messageId.length < 8) return false;
  if (typeof envelope.type !== 'string' || !/^[a-zA-Z][a-zA-Z0-9._:-]{0,79}$/.test(envelope.type) || envelope.type.length > MAX_TYPE_LENGTH) {
    return false;
  }
  try {
    if (Buffer.byteLength(JSON.stringify(envelope), 'utf8') > MAX_ENVELOPE_BYTES) return false;
  } catch {
    return false;
  }
  return true;
}
