import http from 'node:http';
import {execFile} from 'node:child_process';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const PORT=Number(process.env.PORT||8090);
const TIMEOUT_MS=Math.min(Number(process.env.PLUGIN_TIMEOUT_MS||5000),10000);
const MAX_BODY=32768;
const SHARED_SECRET=process.env.WORKER_SHARED_SECRET||'';

function json(res,status,body){res.writeHead(status,{'content-type':'application/json'});res.end(JSON.stringify(body));}
function packageSha256(bytes){return crypto.createHash('sha256').update(bytes).digest('hex');}
function safeEqual(a,b){if(typeof a!=='string'||typeof b!=='string'||a.length!==b.length)return false;return crypto.timingSafeEqual(Buffer.from(a),Buffer.from(b));}
function runIsolated(manifest,payload,expectedSha256,artifactBase64){
  return new Promise((resolve,reject)=>{
    const source=typeof manifest?.entrypoint==='string'?manifest.entrypoint:'';
    if(!source.startsWith('file:'))return reject(Object.assign(new Error('Worker accepts only trusted file entrypoints.'),{code:400}));
    const entry=source.slice(5);
    if(!/^([a-z0-9._-]{3,64})\/([^/]+\\.js)$/.test(entry))return reject(Object.assign(new Error('Entrypoint is invalid.'),{code:403}));
    if(!/^[a-f0-9]{64}$/.test(expectedSha256||''))return reject(Object.assign(new Error('Trusted artifact hash is required.'),{code:400}));
    if(typeof artifactBase64!=='string'||artifactBase64.length>7*1024*1024)return reject(Object.assign(new Error('Plugin artifact payload is invalid.'),{code:413}));
    let bytes;
    try{bytes=Buffer.from(artifactBase64,'base64');}catch{return reject(Object.assign(new Error('Plugin artifact encoding is invalid.'),{code:400}));}
    if(!bytes.length||bytes.length>5*1024*1024)return reject(Object.assign(new Error('Plugin artifact exceeds the 5 MB limit.'),{code:413}));
    const actualSha256=packageSha256(bytes);
    if(actualSha256!==expectedSha256)return reject(Object.assign(new Error('Plugin artifact hash verification failed.'),{code:409}));
    const tempDir=fs.mkdtempSync('/tmp/auren-plugin-');
    const file=path.join(tempDir,entry.split('/')[1]);
    try{fs.writeFileSync(file,bytes,{mode:0o500});}catch{return reject(Object.assign(new Error('Plugin artifact could not be provisioned.'),{code:500}));}
    const cleanup=()=>{try{fs.rmSync(tempDir,{recursive:true,force:true});}catch{}};
    const child=execFile(process.execPath,[file],{
      cwd:'/tmp',
      env:{NODE_ENV:'production',AUREN_PLUGIN_PAYLOAD:JSON.stringify(payload)},
      timeout:TIMEOUT_MS,
      maxBuffer:MAX_BODY,
      windowsHide:true
    },(error,stdout,stderr)=>{
      cleanup();
      if(error)return reject(Object.assign(new Error((stderr||error.message).slice(0,2000)),{code:error.killed?408:500}));
      resolve(stdout.slice(0,MAX_BODY));
    });
  });
}
const server=http.createServer(async(req,res)=>{
  if(req.method==='GET'&&req.url==='/health')return json(res,200,{ok:true,service:'auren-plugin-worker'});
  if(req.method!=='POST'||req.url!=='/execute')return json(res,404,{error:'Not found.'});
  let raw='';
  req.on('data',chunk=>{
    raw+=chunk;
    if(Buffer.byteLength(raw)>MAX_BODY){res.destroy();req.destroy();}
  });
  req.on('error',()=>{});
  req.on('end',async()=>{
    try{
      if(!SHARED_SECRET)return json(res,503,{error:'Worker secret is not configured.'});
      const body=JSON.parse(raw||'{}');
      if(!safeEqual(body.authorization,SHARED_SECRET))return json(res,403,{error:'Unauthorized worker request.'});
      const result=await runIsolated(body.manifest,body.payload||{},body.expectedSha256,body.artifactBase64);
      return json(res,200,{status:'completed',result});
    }catch(e){return json(res,Number.isInteger(e?.code)?e.code:500,{error:e.message||'Plugin execution failed.'});}
  });
});
server.listen(PORT,()=>console.log('AUREN plugin worker listening on '+PORT));