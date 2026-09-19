const ALLOWED_CAPABILITIES = new Set(['actions.execute','actions.discover','messages.send','commerce.request']);

export function validatePluginManifest(manifest){
  if(!manifest||typeof manifest!=='object') throw Object.assign(new Error('Invalid plugin manifest.'),{code:400});
  if(typeof manifest.pluginId!=='string'||!/^[a-z0-9._-]{3,64}$/.test(manifest.pluginId)) throw Object.assign(new Error('Invalid pluginId.'),{code:400});
  if(typeof manifest.name!=='string'||manifest.name.trim().length<2) throw Object.assign(new Error('Plugin name is required.'),{code:400});
  if(typeof manifest.version!=='string'||!/^[0-9]+\\.[0-9]+\\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?$/.test(manifest.version)) throw Object.assign(new Error('Invalid plugin version.'),{code:400});
  if(typeof manifest.entrypoint!=='string'||manifest.entrypoint.length>200) throw Object.assign(new Error('Invalid plugin entrypoint.'),{code:400});
  const raw=Array.isArray(manifest.capabilities)?manifest.capabilities:[];
  if(raw.length>10||raw.some(v=>typeof v!=='string'||!ALLOWED_CAPABILITIES.has(v))||new Set(raw).size!==raw.length) throw Object.assign(new Error('Unsupported or duplicate capability.'),{code:400});
  return {pluginId:manifest.pluginId,name:manifest.name.trim().slice(0,120),version:manifest.version,capabilities:[...raw],entrypoint:manifest.entrypoint,sandbox:'auren-isolated-v1'};
}
export function sandboxPolicy(){return Object.freeze({network:'deny-by-default',secrets:'deny',filesystem:'ephemeral',executionTimeoutMs:5000,maxPayloadBytes:32768});}
