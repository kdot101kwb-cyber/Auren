import http from 'node:http';
import {execFile} from 'node:child_process';
import crypto from 'node:crypto';

const PORT=Number(process.env.PORT||8090);
const TIMEOUT_MS=Math.min(Number(process.env.PLUGIN_TIMEOUT_MS||5000),10000);
const MAX_BODY=32768;
const SHARED_SECRET=process.env.WORKER_SHARED_SECRET||'';

function json(res,status,body){res.writeHead(status,{'content-type':'application/json'});res.end(JSON.stringify(body));}
function safeEqual(a,b){if(typeof a!=='string'||typeof b!=='string'||a.length!==b.length)return false;return crypto.timingSafeEqual(Buffer.from(a),Buffer.from(b));}
function runIsolated(manifest,payload){
  return new Promise((resolve,reject)=>{
    const source=typeof manifest?.entrypoint==='string'?manifest.entrypoint:'';
    if(!source.startsWith('file:'))return reject(Object.assign(new Error('Worker accepts only trusted file entrypoints.'),{code:400}));
    const file=source.slice(5);
    if(!/^\/app\/plugins\/[a-z0-9._-]{3,64}\/[^/]+\.js$/.test(file))return reject(Object.assign(new Error('Entrypoint is outside the plugin mount.'),{code:403}));
    const child=execFile(process.execPath,[file],{
      cwd:'/tmp',
      env:{NODE_ENV:'production',AUREN_PLUGIN_PAYLOAD:JSON.stringify(payload)},
      timeout:TIMEOUT_MS,
      maxBuffer:MAX_BODY,
      windowsHide:true
    },(error,stdout,stderr)=>{
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
      const result=await runIsolated(body.manifest,body.payload||{});
      return json(res,200,{status:'completed',result});
    }catch(e){return json(res,Number.isInteger(e?.code)?e.code:500,{error:e.message||'Plugin execution failed.'});}
  });
});
server.listen(PORT,()=>console.log('AUREN plugin worker listening on '+PORT));