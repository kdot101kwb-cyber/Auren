import crypto from 'node:crypto';
export const PROTOCOL_VERSION = '1.0';
export const AGENT_CAPABILITIES = Object.freeze(['actions.execute','actions.discover','messages.send','commerce.request']);
export function createAgentEndpointId(agentId){return crypto.createHash('sha256').update(`auren:agent-endpoint:${agentId}`).digest('hex').slice(0,32);}
export function validateEnvelope(e){return !!e&&typeof e==='object'&&e.protocol==='AUREN-A2A'&&e.version===PROTOCOL_VERSION&&typeof e.messageId==='string'&&e.messageId.length>=8&&typeof e.senderAgentId==='string'&&!!e.senderAgentId&&typeof e.recipientAgentId==='string'&&!!e.recipientAgentId&&typeof e.type==='string'&&!!e.type;}
