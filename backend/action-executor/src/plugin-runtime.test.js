import test from 'node:test';
import assert from 'node:assert/strict';
import { executePluginThroughWorker } from './plugin-runtime.js';

const prepared=()=>({
  manifest:{pluginId:'auren.demo.plugin',version:'1.0.0',entrypoint:'file:auren.demo.plugin/entrypoint.js'},
  package:{sha256:'a'.repeat(64)},artifactBase64:'SGVsbG8=',payload:{text:'ok'},
});
const response=(data,status=200)=>({ok:status>=200&&status<300,status,json:async()=>data});

test('runtime accepts a completed worker result',async()=>{
  const result=await executePluginThroughWorker({prepared:prepared(),workerUrl:'http://worker/execute',workerSecret:'secret',action:'preview.request',fetchImpl:async()=>response({status:'completed',result:{ok:true}})});
  assert.deepEqual(result,{status:'completed',result:{ok:true}});
});
test('runtime rejects non-completed worker status',async()=>{
  await assert.rejects(()=>executePluginThroughWorker({prepared:prepared(),workerUrl:'http://worker/execute',workerSecret:'secret',action:'preview.request',fetchImpl:async()=>response({status:'processing'})}),/invalid execution result/);
});
test('runtime rejects missing worker result',async()=>{
  await assert.rejects(()=>executePluginThroughWorker({prepared:prepared(),workerUrl:'http://worker/execute',workerSecret:'secret',action:'preview.request',fetchImpl:async()=>response({status:'completed'})}),/result is missing/);
});
test('runtime rejects oversized worker result',async()=>{
  await assert.rejects(()=>executePluginThroughWorker({prepared:prepared(),workerUrl:'http://worker/execute',workerSecret:'secret',action:'preview.request',fetchImpl:async()=>response({status:'completed',result:'x'.repeat(32769)})}),/exceeds the runtime limit/);
});
