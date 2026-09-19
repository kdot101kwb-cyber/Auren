import { validatePackageMetadata, verifyPackageSignature, consumeQuota } from './plugin-security.js';
import { validatePluginManifest, sandboxPolicy } from './agent-sandbox.js';
export async function preparePluginInvocation(db,{agent,manifest,packageMetadata,signature,secret,payload={}}){
  const normalized=validatePluginManifest(manifest);
  const meta=validatePackageMetadata(packageMetadata);
  if(normalized.pluginId!==meta.pluginId||normalized.version!==meta.version)throw Object.assign(new Error('Manifest and package version mismatch.'),{code:409});
  if(!verifyPackageSignature(meta,signature,secret))throw Object.assign(new Error('Invalid plugin package signature.'),{code:403});
  const bytes=Buffer.byteLength(JSON.stringify(payload),'utf8');
  if(bytes>sandboxPolicy().maxPayloadBytes)throw Object.assign(new Error('Plugin payload exceeds sandbox limit.'),{code:413});
  const quota=await consumeQuota(db,agent.agentId,normalized.pluginId);
  return {status:'validated',manifest:normalized,package:meta,sandbox:sandboxPolicy(),quota};
}

export async function executePluginThroughWorker({prepared,workerUrl,workerSecret,fetchImpl=fetch}){
  if(!workerUrl)throw Object.assign(new Error('Plugin worker is not configured.'),{code:503});
  if(!workerSecret)throw Object.assign(new Error('Plugin worker secret is not configured.'),{code:503});
  const controller=new AbortController();
  const timer=setTimeout(()=>controller.abort(),7000);
  try{
    const response=await fetchImpl(workerUrl,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({authorization:workerSecret,manifest:prepared.manifest,payload:prepared.payload||{}}),signal:controller.signal});
    const data=await response.json().catch(()=>({}));
    if(!response.ok)throw Object.assign(new Error(data.error||'Plugin worker failed.'),{code:response.status});
    return data;
  }catch(e){
    if(e?.name==='AbortError')throw Object.assign(new Error('Plugin worker timed out.'),{code:408});
    throw e;
  }finally{clearTimeout(timer);}
}
