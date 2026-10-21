#!/usr/bin/env node
'use strict';
const fs=require('node:fs'),path=require('node:path');
function walk(dir,predicate,out=[]){if(!fs.existsSync(dir))return out;for(const e of fs.readdirSync(dir,{withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name))){const f=path.join(dir,e.name);if(e.isDirectory()){if(!['node_modules','.git'].includes(e.name))walk(f,predicate,out);}else if(e.isFile()&&predicate(f))out.push(f);}return out;}
function rel(root,file){return path.relative(root,file).split(path.sep).join('/');}
function escapeMarkdownCell(value){return String(value).replace(/\\/g,'\\\\').replace(/\|/g,'\\|').replace(/[\r\n]+/g,' ');}
function inventory(root){
 const workflows=walk(path.join(root,'.github','workflows'),f=>/\.ya?ml$/i.test(f)).map(file=>{
  const s=fs.readFileSync(file,'utf8'),lines=s.split(/\r?\n/),jobs=[],triggers=[];
  const jobsIndex=lines.findIndex(line=>/^jobs:\s*$/.test(line)),jobsWithPermissions=[];
  if(jobsIndex>=0){let currentJob=null;for(let i=jobsIndex+1;i<lines.length;i++){const line=lines[i];if(line.trim()&&!/^\s/.test(line)&&!/^\s*#/.test(line))break;const match=line.match(/^  ([A-Za-z0-9_-]+):\s*$/);if(match){currentJob=match[1];jobs.push(currentJob);continue;}if(currentJob&&/^    permissions:\s*(?:#.*)?$/.test(line))jobsWithPermissions.push(currentJob);}}
  const onIndex=lines.findIndex(line=>/^(?:on|['"]on['"]):\s*$/.test(line));
  if(onIndex>=0){for(let i=onIndex+1;i<lines.length;i++){const line=lines[i];if(line.trim()&&!/^\s/.test(line)&&!/^\s*#/.test(line))break;const match=line.match(/^\s{2}([A-Za-z0-9_-]+):/);if(match)triggers.push(match[1]);}}
  const deployCommands=[];const workflowLines=s.split(/\r?\n/);
  for(let i=0;i<workflowLines.length;i++){
   const line=workflowLines[i],runMatch=line.match(/^(\s*(?:-\s*)?)run:\s*(.*)$/);
   if(!runMatch)continue;
   const indent=runMatch[1].length;let command=runMatch[2].trim();
   if(command==='|'||command==='>'||command==='|-'||command==='|+'||command==='>-'||command==='>+'){
    command='';let j=i+1;
    while(j<workflowLines.length){const next=workflowLines[j];if(next.trim()&&(/^\s*$/.test(next)||next.match(/^\s*/)[0].length>indent)){command+=' '+next.trim();j++;}else break;}
   }
   if(!/(?:\bfirebase\s+deploy\b|\bfirebase-tools(?:@[^\s]+)?\s+deploy\b)/.test(command))continue;
   const p=command.match(/--project(?:=|\s+)([A-Za-z0-9._-]+)/);
   deployCommands.push({line:i+1,safety:!p?'missing-explicit-project':(/^auren-staging$/.test(p[1])?'explicit-project':'non-staging-target')});
  }
  const workflowPermissionsDeclared=/^permissions:/m.test(s),uniqueJobs=[...new Set(jobs)],uniqueJobPermissions=[...new Set(jobsWithPermissions)];
  const permissionCoverage=workflowPermissionsDeclared?'workflow-level':uniqueJobs.length>0&&uniqueJobs.every(job=>uniqueJobPermissions.includes(job))?'all-jobs':uniqueJobPermissions.length?'partial-job-level':'none';
  return {path:rel(root,file),triggers:[...new Set(triggers)],jobs:uniqueJobs,permissionsDeclared:workflowPermissionsDeclared,jobPermissionsDeclared:uniqueJobPermissions,permissionCoverage,concurrencyDeclared:/^concurrency:/m.test(s),deployCommands};
 });
 const scheduledFunctions=walk(path.join(root,'functions'),f=>f.endsWith('.js')&&!f.endsWith('.test.js')).flatMap(file=>{
  const s=fs.readFileSync(file,'utf8'),out=[],declared=new Set();
  const directPatterns=[
   /exports\.([A-Za-z_$][\w$]*)\s*=\s*onSchedule\s*\(/g,
   /exports\.([A-Za-z_$][\w$]*)\s*=\s*functions\.pubsub\.schedule\s*\(/g
  ];
  for(const re of directPatterns)for(const m of s.matchAll(re)){out.push({path:rel(root,file),name:m[1]});declared.add(m[1]);}
  const aliases=new Map();
  for(const m of s.matchAll(/(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*=\s*(?:onSchedule|functions\.pubsub\.schedule)\s*\(/g))aliases.set(m[1],true);
  for(const m of s.matchAll(/exports\.([A-Za-z_$][\w$]*)\s*=\s*([A-Za-z_$][\w$]*)\s*;/g)){
   if(aliases.has(m[2])&&!declared.has(m[1])){out.push({path:rel(root,file),name:m[1]});declared.add(m[1]);}
  }
  return out;
 });
 const unique=[...new Map(scheduledFunctions.map(x=>[x.path+':'+x.name,x])).values()].sort((a,b)=>(a.path+a.name).localeCompare(b.path+b.name)),findings=[];
 for(const w of workflows)for(const c of w.deployCommands)if(c.safety!=='explicit-project')findings.push({severity:'warning',code:c.safety,path:w.path,line:c.line,message:c.safety==='missing-explicit-project'?'Firebase deploy command has no explicit --project on the same line.':'Firebase deploy command explicitly targets a project other than auren-staging.'});
 return {generatedAt:new Date().toISOString(),workflows,scheduledFunctions:unique,findings};
}
function markdown(r){const a=['# AUREN Automation Inventory & Static Safety Audit','','> Static inspection only. This report does not execute workflows, import functions, read secret values, or perform deployments. Findings are heuristic and do not prove runtime behavior.','','- Workflows found: **'+r.workflows.length+'**','- Scheduled-function exports detected (static patterns): **'+r.scheduledFunctions.length+'**','- Static deployment warnings: **'+r.findings.length+'**','','## GitHub Actions workflows','','| Workflow | Triggers detected | Jobs detected | Permission scope | Concurrency | Deploy commands |','|---|---|---|---|---|---|'];for(const x of r.workflows)a.push('| '+[x.path,x.triggers.join(', ')||'not parsed',x.jobs.join(', ')||'not parsed',x.permissionCoverage,x.concurrencyDeclared?'declared':'not declared',x.deployCommands.length].map(escapeMarkdownCell).join(' | ')+' |');a.push('','## Scheduled Firebase Function exports','');if(!r.scheduledFunctions.length)a.push('No scheduled export pattern was detected. Dynamic or cross-module re-exports may be missed.');else for(const x of r.scheduledFunctions)a.push('- '+escapeMarkdownCell(x.name)+' — '+escapeMarkdownCell(x.path));a.push('','## Findings','');if(!r.findings.length)a.push('No deployment-target warnings were detected by the current static rules.');else for(const x of r.findings)a.push('- **'+escapeMarkdownCell(x.severity.toUpperCase()+' '+x.code)+'** — '+escapeMarkdownCell(x.path)+':'+x.line+': '+escapeMarkdownCell(x.message));a.push('','Generated at: '+r.generatedAt,'');return a.join('\n');}
if(require.main===module){const root=path.resolve(process.argv[2]||path.join(__dirname,'..')),r=inventory(root),report=markdown(r),out=process.env.GITHUB_STEP_SUMMARY;fs.writeFileSync(process.env.AUREN_INVENTORY_REPORT||path.join(root,'auren-automation-inventory.md'),report+'\n');if(out)fs.appendFileSync(out,report+'\n');else process.stdout.write(report+'\n');if(process.env.AUREN_INVENTORY_JSON==='1')process.stdout.write(JSON.stringify(r,null,2)+'\n');}
module.exports={inventory,markdown,escapeMarkdownCell};
