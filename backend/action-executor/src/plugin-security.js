import crypto from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';
const MAX_PACKAGE_BYTES=5*1024*1024;
const MAX_DAILY_INVOCATIONS=10000;
const SAFE_ID=/^[a-z0-9._-]{3,64}$/;
export function validateArtifactId(value){
  if(typeof value!=='string'||!SAFE_ID.test(value))throw Object.assign(new Error('Invalid plugin artifact id.'),{code:400});
  return value;
}
export function artifactObjectPath(agentId,artifactId){
  if(typeof agentId!=='string'||!agentId||!SAFE_ID.test(artifactId))throw Object.assign(new Error('Invalid plugin artifact reference.'),{code:400});
  return `plugin-artifacts/${agentId}/${artifactId}/entrypoint.js`;
}
export function createArtifactId(){return 'art_'+crypto.randomUUID();}
export function packageSha256(bytes){return crypto.createHash('sha256').update(bytes).digest('hex');}
export function validatePackageMetadata(meta){
  if(!meta||typeof meta!=='object')throw Object.assign(new Error('Invalid plugin package metadata.'),{code:400});
  if(typeof meta.pluginId!=='string'||typeof meta.version!=='string'||typeof meta.sha256!=='string'||!/^[a-f0-9]{64}$/.test(meta.sha256))throw Object.assign(new Error('Plugin package hash is required.'),{code:400});
  const size=Number(meta.sizeBytes||0);
  if(!Number.isInteger(size)||size<1||size>MAX_PACKAGE_BYTES)throw Object.assign(new Error('Plugin package size exceeds the AUREN limit.'),{code:400});
  return {pluginId:meta.pluginId,version:meta.version,sha256:meta.sha256,sizeBytes:size};
}
export function signPackage(meta,secret){
  const canonical=meta.pluginId+'|'+meta.version+'|'+meta.sha256+'|'+meta.sizeBytes;
  return crypto.createHmac('sha256',secret).update(canonical).digest('hex');
}
export function verifyPackageSignature(meta,signature,secret){
  if(typeof signature!=='string'||signature.length!==64)return false;
  const expected=signPackage(meta,secret);
  return crypto.timingSafeEqual(Buffer.from(expected),Buffer.from(signature));
}
export async function consumeQuota(db,agentId,pluginId){
  const day=new Date().toISOString().slice(0,10);
  const ref=db.collection('plugin_quotas').doc(agentId+'_'+pluginId+'_'+day);
  let used=0;
  await db.runTransaction(async tx=>{
    const s=await tx.get(ref); used=Number(s.data()?.invocations||0)+1;
    if(used>MAX_DAILY_INVOCATIONS)throw Object.assign(new Error('Plugin daily invocation quota exceeded.'),{code:429});
    tx.set(ref,{agentId,pluginId,day,invocations:used,updatedAt:FieldValue.serverTimestamp()},{merge:true});
  });
  return {day,invocations:used,limit:MAX_DAILY_INVOCATIONS};
}
export const pluginSecurityLimits=Object.freeze({maxPackageBytes:MAX_PACKAGE_BYTES,dailyInvocations:MAX_DAILY_INVOCATIONS});
