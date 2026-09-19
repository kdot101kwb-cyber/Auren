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
