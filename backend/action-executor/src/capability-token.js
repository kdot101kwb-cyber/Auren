import crypto from 'node:crypto';
export function issueCapabilityToken({agentId,capability,expiresAt,secret=process.env.AUREN_CAPABILITY_SECRET}) {
 if(!secret) throw new Error('AUREN_CAPABILITY_SECRET is not configured.');
 const payload={tokenId:crypto.randomUUID(),agentId,capability,nonce:crypto.randomBytes(16).toString('hex'),expiresAt:Number(expiresAt)};
 const body=Buffer.from(JSON.stringify(payload)).toString('base64url');
 const signature=crypto.createHmac('sha256',secret).update(body).digest('base64url');
 return { ...payload, token:body+'.'+signature };
}
export function validateCapabilityToken(token,agentId,capability,secret=process.env.AUREN_CAPABILITY_SECRET) {
 if(!secret||!token?.token) return false;
 const [body,sig]=String(token.token).split('.');
 if(!body||!sig) return false;
 const expected=crypto.createHmac('sha256',secret).update(body).digest('base64url');
 if(!crypto.timingSafeEqual(Buffer.from(sig),Buffer.from(expected))) return false;
 try { const p=JSON.parse(Buffer.from(body,'base64url').toString()); return p.agentId===agentId&&p.capability===capability&&Date.now()<Number(p.expiresAt); } catch { return false; }
}
