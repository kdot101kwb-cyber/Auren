import { validatePackageMetadata, verifyPackageSignature, consumeQuota } from './plugin-security.js';
import { validatePluginManifest, sandboxPolicy } from './agent-sandbox.js';
import { FieldValue } from 'firebase-admin/firestore';
export async function preparePluginInvocation(db,{agent,manifest,packageMetadata,signature,secret,payload={}}){
  const normalized=validatePluginManifest(manifest);
  const meta=validatePackageMetadata(packageMetadata);
  if(normalized.pluginId!==meta.pluginId||normalized.version!==meta.version)throw Object.assign(new Error('Manifest and package version mismatch.'),{code:409});
  const listingRef=db.collection('agent_listings').doc(agent.agentId);
  const listingSnap=await listingRef.get();
  if(!listingSnap.exists||listingSnap.data()?.state!=='published')throw Object.assign(new Error('Plugin must be published before runtime execution.'),{code:403});
  const listing=listingSnap.data();
  if(listing.pluginId!==normalized.pluginId||listing.version!==normalized.version||listing.entrypoint!==normalized.entrypoint)throw Object.assign(new Error('Plugin does not match the published agent listing.'),{code:409});
  const versionRef=listingRef.collection('versions').doc(normalized.version);
  const versionSnap=await versionRef.get();
  if(!versionSnap.exists)throw Object.assign(new Error('Published plugin version artifact is not registered.'),{code:409});
  const version=versionSnap.data();
  if(version.artifactState==='revoked')throw Object.assign(new Error('Plugin artifact version has been revoked.'),{code:403});
  if(version.artifactState!=='approved')throw Object.assign(new Error('Plugin artifact is not approved for execution.'),{code:403});
  if(version.pluginId!==normalized.pluginId||version.version!==normalized.version||version.entrypoint!==normalized.entrypoint)throw Object.assign(new Error('Registered plugin artifact provenance does not match the requested version.'),{code:409});
  if(version.sha256!==meta.sha256||version.sizeBytes!==meta.sizeBytes)throw Object.assign(new Error('Plugin artifact metadata does not match the registered provenance.'),{code:409});
  if(!verifyPackageSignature(meta,signature,secret))throw Object.assign(new Error('Invalid plugin package signature.'),{code:403});
  const bytes=Buffer.byteLength(JSON.stringify(payload),'utf8');
  if(bytes>sandboxPolicy().maxPayloadBytes)throw Object.assign(new Error('Plugin payload exceeds sandbox limit.'),{code:413});
  const quota=await consumeQuota(db,agent.agentId,normalized.pluginId);
  return {status:'validated',manifest:normalized,package:meta,sandbox:sandboxPolicy(),quota,payload};
}

export async function executePluginThroughWorker({prepared,workerUrl,workerSecret,fetchImpl=fetch}){
  if(!workerUrl)throw Object.assign(new Error('Plugin worker is not configured.'),{code:503});
  if(!workerSecret)throw Object.assign(new Error('Plugin worker secret is not configured.'),{code:503});
  const controller=new AbortController();
  const timer=setTimeout(()=>controller.abort(),7000);
  try{
    const response=await fetchImpl(workerUrl,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({authorization:workerSecret,manifest:prepared.manifest,expectedSha256:prepared.package.sha256,payload:prepared.payload||{}}),signal:controller.signal});
    const data=await response.json().catch(()=>({}));
    if(!response.ok)throw Object.assign(new Error(data.error||'Plugin worker failed.'),{code:response.status});
    return data;
  }catch(e){
    if(e?.name==='AbortError')throw Object.assign(new Error('Plugin worker timed out.'),{code:408});
    throw e;
  }finally{clearTimeout(timer);}
}
