import crypto from 'node:crypto';
export function issueCapabilityToken({agentId,capability,expiresAt}){const nonce=crypto.randomBytes(16).toString('hex');return{tokenId:crypto.randomUUID(),agentId,capability,nonce,expiresAt};}
export function validateCapabilityToken(token,agentId,capability){return !!token&&token.agentId===agentId&&token.capability===capability&&Date.now()<Number(token.expiresAt);}
