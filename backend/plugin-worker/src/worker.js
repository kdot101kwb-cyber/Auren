import http from 'node:http';
import {execFile} from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const PORT=Number(process.env.PORT||8090);
const TIMEOUT_MS=Math.min(Number(process.env.PLUGIN_TIMEOUT_MS||5000),10000);
const MAX_BODY=32768;
const MAX_ARTIFACT_BYTES=5*1024*1024;
const MAX_REQUEST_BODY=7*1024*1024;
const MAX_PAYLOAD_BYTES=32768;
const MAX_OUTPUT_BYTES=32768;
const MAX_PLUGIN_ID=120;
const MAX_ACTION=120;
const SHARED_SECRET=process.env.WORKER_SHARED_SECRET||'';
const MAX_CONCURRENT_EXECUTIONS=4;
let activeExecutions=0;

function json(res,status,body){res.writeHead(status,{'content-type':'application/json'});res.end(JSON.stringify(body));}
function packageSha256(bytes){return crypto.createHash('sha256').update(bytes).digest('hex');}
function safeEqual(a,b){if(typeof a!=='string'||typeof b!=='string'||a.length!==b.length)return false;return crypto.timingSafeEqual(Buffer.from(a),Buffer.from(b));}
function runIsolated(manifest,payload,expectedSha256,artifactBase64){
  const pluginId=typeof manifest?.pluginId==='string'?manifest.pluginId.trim():'';
  const action=typeof manifest?.action==='string'?manifest.action.trim():'';
  if(!/^[a-z0-9][a-z0-9._-]{2,119}$/.test(pluginId)||pluginId.length>MAX_PLUGIN_ID) return Promise.reject(Object.assign(new Error('Plugin id is invalid.'),{code:400}));
  if(!action||action.length>MAX_ACTION||!/^[a-zA-Z0-9._:-]+$/.test(action)) return Promise.reject(Object.assign(new Error('Plugin action is invalid.'),{code:400}));
  return new Promise((resolve,reject)=>{
    const source=typeof manifest?.entrypoint==='string'?manifest.entrypoint:'';
    if(!source.startsWith('file:'))return reject(Object.assign(new Error('Worker accepts only trusted file entrypoints.'),{code:400}));
    const entry=source.slice(5);
    if(!/^([a-z0-9._-]{3,64})\/([^/]+\\.js)$/.test(entry))return reject(Object.assign(new Error('Entrypoint is invalid.'),{code:403}));
    if(!/^[a-f0-9]{64}$/.test(expectedSha256||''))return reject(Object.assign(new Error('Trusted artifact hash is required.'),{code:400}));
    if(typeof artifactBase64!=='string'||artifactBase64.length>7*1024*1024)return reject(Object.assign(new Error('Plugin artifact payload is invalid.'),{code:413}));
    let bytes;
    if(!/^[A-Za-z0-9+/]*={0,2}$/.test(artifactBase64)||artifactBase64.length%4!==0)return reject(Object.assign(new Error('Plugin artifact encoding is invalid.'),{code:400}));
    try{bytes=Buffer.from(artifactBase64,'base64');}catch{return reject(Object.assign(new Error('Plugin artifact encoding is invalid.'),{code:400}));}
    if(!bytes.length||bytes.length>MAX_ARTIFACT_BYTES)return reject(Object.assign(new Error('Plugin artifact exceeds the 5 MB limit.'),{code:413}));
    const actualSha256=packageSha256(bytes);
    if(actualSha256!==expectedSha256)return reject(Object.assign(new Error('Plugin artifact hash verification failed.'),{code:409}));
    const tempDir=fs.mkdtempSync('/tmp/auren-plugin-');
    const file=path.join(tempDir,entry.split('/')[1]);
    try{fs.writeFileSync(file,bytes,{mode:0o500});}catch{return reject(Object.assign(new Error('Plugin artifact could not be provisioned.'),{code:500}));}
    const cleanup=()=>{try{fs.rmSync(tempDir,{recursive:true,force:true});}catch{}};
    const child=execFile(process.execPath,[file],{
      cwd:'/tmp',
      env:{NODE_ENV:'production',AUREN_PLUGIN_ID:pluginId,AUREN_PLUGIN_ACTION:action,AUREN_PLUGIN_PAYLOAD:JSON.stringify(payload)},
      timeout:TIMEOUT_MS,
      maxBuffer:MAX_BODY,
      windowsHide:true
    },(error,stdout,stderr)=>{
      cleanup();
      if(error)return reject(Object.assign(new Error((stderr||error.message).slice(0,2000)),{code:error.killed?408:500}));
      if(Buffer.byteLength(stdout,'utf8')>MAX_OUTPUT_BYTES)return reject(Object.assign(new Error('Plugin output exceeds the worker limit.'),{code:413}));
      resolve(stdout);
    });
  });
}
const server=http.createServer(async(req,res)=>{
  if(req.method==='GET'&&req.url==='/health')return json(res,200,{ok:true,service:'auren-plugin-worker'});
  if(req.method!=='POST'||req.url!=='/execute')return json(res,404,{error:'Not found.'});
  let raw='';
  req.on('data',chunk=>{
    raw+=chunk;
    if(Buffer.byteLength(raw)>MAX_REQUEST_BODY){res.destroy();req.destroy();}
  });
  req.on('error',()=>{});
  req.on('end',async()=>{
    try{
      if(!SHARED_SECRET)return json(res,503,{error:'Worker secret is not configured.'});
      const body=JSON.parse(raw||'{}');
      if(!safeEqual(body.authorization,SHARED_SECRET))return json(res,403,{error:'Unauthorized worker request.'});
      if(activeExecutions>=MAX_CONCURRENT_EXECUTIONS)return json(res,429,{error:'Plugin worker concurrency limit reached.'});
      activeExecutions++;
      const payloadBytes=Buffer.byteLength(JSON.stringify(body.payload||{}),'utf8');
      if(payloadBytes>MAX_PAYLOAD_BYTES)return json(res,413,{error:'Plugin payload exceeds the worker limit.'});
      const manifest={...(body.manifest||{}),action:body.action};
      const result=await runIsolated(manifest,body.payload||{},body.expectedSha256,body.artifactBase64);
      return json(res,200,{status:'completed',result});
    }catch(e){return json(res,Number.isInteger(e?.code)?e.code:500,{error:e.message||'Plugin execution failed.'});}
    finally{activeExecutions=Math.max(0,activeExecutions-1);}
  });
});
server.listen(PORT,()=>console.log('AUREN plugin worker listening on '+PORT));