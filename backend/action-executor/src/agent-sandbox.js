const ALLOWED_CAPABILITIES = new Set(['actions.execute','actions.discover','messages.send','commerce.request']);
export function validatePluginManifest(manifest){
 if(!manifest||typeof manifest!=='object')throw Object.assign(new Error('Invalid plugin manifest.'),{code:400});
 if(typeof manifest.pluginId!=='string'||!/^[a-z0-9._-]{3,64}$/.test(manifest.pluginId))throw Object.assign(new Error('Invalid pluginId.'),{code:400});
 const capabilities=Array.isArray(manifest.capabilities)?manifest.capabilities.filter(v=>ALLOWED_CAPABILITIES.has(v)).slice(0,10):[];
 if(capabilities.length!==new Set(manifest.capabilities||[]).size)throw Object.assign(new Error('Unsupported or duplicate capability.'),{code:400});
 return {pluginId:manifest.pluginId,name:String(manifest.name||'').slice(0,120),version:String(manifest.version||'1.0.0').slice(0,30),capabilities,entrypoint:String(manifest.entrypoint||'').slice(0,200),sandbox:'auren-isolated-v1'};
}
export function sandboxPolicy(){return Object.freeze({network:'deny-by-default',secrets:'deny',filesystem:'ephemeral',executionTimeoutMs:5000,maxPayloadBytes:32768});}
