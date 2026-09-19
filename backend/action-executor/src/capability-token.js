import crypto from 'node:crypto';

export function issueCapabilityToken({agentId,capability,expiresAt,secret=process.env.AUREN_CAPABILITY_SECRET}) {
  if(!secret) throw new Error('AUREN_CAPABILITY_SECRET is not configured.');
  const payload={tokenId:crypto.randomUUID(),agentId,capability,nonce:crypto.randomBytes(16).toString('hex'),expiresAt:Number(expiresAt)};
  const body=Buffer.from(JSON.stringify(payload)).toString('base64url');
  const signature=crypto.createHmac('sha256',secret).update(body).digest('base64url');
  return {...payload,token:body+'.'+signature};
}
export function decodeAndValidateCapabilityToken(token,agentId,capability,secret=process.env.AUREN_CAPABILITY_SECRET) {
  if(!secret||!token?.token) return null;
  const [body,sig]=String(token.token).split('.');
  if(!body||!sig) return null;
  const expected=crypto.createHmac('sha256',secret).update(body).digest('base64url');
  const a=Buffer.from(sig), b=Buffer.from(expected);
  if(a.length!==b.length||!crypto.timingSafeEqual(a,b)) return null;
  try {
    const p=JSON.parse(Buffer.from(body,'base64url').toString());
    if(p.agentId!==agentId||p.capability!==capability||Date.now()>=Number(p.expiresAt)) return null;
    return p;
  } catch { return null; }
}
export function validateCapabilityToken(token,agentId,capability,secret=process.env.AUREN_CAPABILITY_SECRET) {
  return decodeAndValidateCapabilityToken(token,agentId,capability,secret)!==null;
}
