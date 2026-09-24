import { validatePackageMetadata, verifyPackageSignature, consumeQuota, packageSha256 } from './plugin-security.js';
import { validatePluginManifest, sandboxPolicy } from './agent-sandbox.js';
import { getStorage } from 'firebase-admin/storage';
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
  if(version.agentId!==agent.agentId||version.pluginId!==normalized.pluginId||version.version!==normalized.version||version.entrypoint!==normalized.entrypoint)throw Object.assign(new Error('Registered plugin artifact provenance does not match the requested version.'),{code:409});
  if(!version.artifactId||!version.objectPath)throw Object.assign(new Error('Plugin artifact storage reference is missing.'),{code:409});
  if(version.sha256!==meta.sha256||version.sizeBytes!==meta.sizeBytes||JSON.stringify(version.dependencies||[])!==JSON.stringify(meta.dependencies||[]))throw Object.assign(new Error('Plugin artifact metadata does not match the registered provenance.'),{code:409});
  if(!verifyPackageSignature(meta,signature,secret))throw Object.assign(new Error('Invalid plugin package signature.'),{code:403});
  const artifactSnap=await db.collection('plugin_artifacts').doc(version.artifactId).get();
  if(!artifactSnap.exists)throw Object.assign(new Error('Plugin artifact registry record is missing.'),{code:409});
  const artifact=artifactSnap.data();
  if(artifact.state!=='approved'||artifact.agentId!==agent.agentId||artifact.objectPath!==version.objectPath||artifact.sha256!==version.sha256||artifact.sizeBytes!==version.sizeBytes)throw Object.assign(new Error('Plugin artifact provenance is not trusted.'),{code:403});
  const bucket=getStorage().bucket();
  let artifactBytes;
  try{[artifactBytes]=await bucket.file(version.objectPath).download();}catch{throw Object.assign(new Error('Plugin artifact could not be loaded from trusted storage.'),{code:404});}
  if(artifactBytes.length!==version.sizeBytes||packageSha256(artifactBytes)!==version.sha256)throw Object.assign(new Error('Stored plugin artifact integrity check failed.'),{code:409});
  const bytes=Buffer.byteLength(JSON.stringify(payload),'utf8');
  if(bytes>sandboxPolicy().maxPayloadBytes)throw Object.assign(new Error('Plugin payload exceeds sandbox limit.'),{code:413});
  const quota=await consumeQuota(db,agent.agentId,normalized.pluginId);
  return {status:'validated',manifest:normalized,package:meta,artifactBase64:artifactBytes.toString('base64'),sandbox:sandboxPolicy(),quota,payload};
}

export async function executePluginThroughWorker({prepared,workerUrl,workerSecret,action,fetchImpl=fetch}){
  if(!workerUrl)throw Object.assign(new Error('Plugin worker is not configured.'),{code:503});
  if(!workerSecret)throw Object.assign(new Error('Plugin worker secret is not configured.'),{code:503});
  const controller=new AbortController();
  const timer=setTimeout(()=>controller.abort(),7000);
  try{
    const normalizedAction=typeof action==='string'?action.trim():'';
    if(!normalizedAction||normalizedAction.length>120||!/^[a-zA-Z0-9._:-]+$/.test(normalizedAction))throw Object.assign(new Error('Plugin action is invalid.'),{code:400});
    const requestBody=JSON.stringify({authorization:workerSecret,manifest:{...prepared.manifest,action:normalizedAction},action:normalizedAction,expectedSha256:prepared.package.sha256,artifactBase64:prepared.artifactBase64,payload:prepared.payload||{}});
    if(Buffer.byteLength(requestBody,'utf8')>7*1024*1024)throw Object.assign(new Error('Plugin worker request exceeds the bounded runtime payload.'),{code:413});
    const response=await fetchImpl(workerUrl,{method:'POST',headers:{'content-type':'application/json','x-auren-runtime-version':'1'},body:requestBody,signal:controller.signal});
    const data=await response.json().catch(()=>null);
    if(!response.ok)throw Object.assign(new Error(data?.error||'Plugin worker failed.'),{code:response.status});
    if(!data||typeof data!=='object'||data.status!=='completed') {
      throw Object.assign(new Error('Plugin worker returned an invalid execution result.'),{code:502});
    }
    if(!Object.prototype.hasOwnProperty.call(data,'result')) {
      throw Object.assign(new Error('Plugin worker result is missing.'),{code:502});
    }
    const resultBytes=Buffer.byteLength(JSON.stringify(data.result),'utf8');
    if(resultBytes>32768) {
      throw Object.assign(new Error('Plugin worker result exceeds the runtime limit.'),{code:413});
    }
    return data;
  }catch(e){
    if(e?.name==='AbortError')throw Object.assign(new Error('Plugin worker timed out.'),{code:408});
    throw e;
  }finally{clearTimeout(timer);}
}
