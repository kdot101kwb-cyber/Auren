#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');

function filesUnder(dir, pattern) {
  if (!fs.existsSync(dir)) return [];
  const out = [];
  for (const e of fs.readdirSync(dir, {withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name))) {
    const p = path.join(dir,e.name);
    if (e.isDirectory() && !['.git','node_modules','.dart_tool','build','coverage'].includes(e.name)) out.push(...filesUnder(p,pattern));
    else if (e.isFile() && pattern.test(e.name)) out.push(p);
  }
  return out;
}
function scalar(v) {
  const s=String(v||'').trim();
  return s.length>1 && ((s[0]==='"'&&s.at(-1)==='"')||(s[0]==="'"&&s.at(-1)==="'")) ? s.slice(1,-1) : s;
}
function stripYamlComment(line) {
  let quote = null;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (quote === '"') {
      if (ch === '\\\\') { i++; continue; }
      if (ch === '"') quote = null;
      continue;
    }
    if (quote === "'") {
      if (ch === "'" && line[i + 1] === "'") { i++; continue; }
      if (ch === "'") quote = null;
      continue;
    }
    if (ch === '"' || ch === "'") { quote = ch; continue; }
    if (ch === '#' && (i === 0 || /\\s/.test(line[i - 1]))) return line.slice(0, i).trimEnd();
  }
  return line;
}
function parseWorkflow(file, source) {
  const lines=source.split(/\r?\n/), name=scalar(source.match(/^name:\s*(.*?)\s*$/m)?.[1]||path.basename(file));
  const triggers=new Set(), oi=lines.findIndex(l=>/^(?:on|"on"|'on')\s*:\s*/.test(l));
  if(oi>=0){
    const inline=lines[oi].replace(/^(?:on|"on"|'on')\s*:\s*/,'').trim(), list=inline.match(/^\[([^\]]*)\]$/);
    if(list) list[1].split(',').map(scalar).filter(Boolean).forEach(t=>triggers.add(t));
    else if(inline&&!inline.startsWith('#')) triggers.add(scalar(inline));
    else for(let i=oi+1;i<lines.length;i++){
      const l=lines[i]; if(!l.trim()||l.trim().startsWith('#'))continue;
      const indent=l.match(/^ */)[0].length; if(indent===0)break;
      if(indent===2){const m=l.match(/^\s{2}([A-Za-z_][\w-]*)\s*:/);if(m)triggers.add(m[1]);}
    }
  }
  const activeSource=lines.map(stripYamlComment).join('\n');
  const cron=[...activeSource.matchAll(/\bcron\s*:\s*(['"])(.*?)\1/g)].map(m=>m[2].trim()).filter(Boolean);
  const explicitPermissions=/^permissions\s*:/m.test(source), concurrency=/^concurrency\s*:/m.test(source);
  const staging=/staging/i.test(`${file} ${name}`), deploys=[], findings=[];
  lines.forEach((line,i)=>{
    if(line.trim().startsWith('#')||!/\bfirebase(?:-tools(?:@[^\s]+)?)?\b/i.test(line)||!/\bdeploy\b/i.test(line))return;
    const p=line.match(/--project(?:=|\s+)([^\s\\]+)/i), target=p?scalar(p[1]).replace(/["']$/,''):null;
    deploys.push({targetProject:target||null,lineNumber:i+1});
    if(!target||target.startsWith('$')) findings.push({severity:'error',code:'firebase_deploy_missing_explicit_project',message:`${file}:${i+1} Firebase deploy must specify --project.`});
    else if(staging&&target!=='auren-staging') findings.push({severity:'error',code:'staging_deploy_wrong_project',message:`${file}:${i+1} staging workflow must target auren-staging, not ${target}.`});
  });
  if(!explicitPermissions)findings.push({severity:'warning',code:'implicit_workflow_permissions',message:`${file} has no explicit top-level permissions block.`});
  if(cron.length&&!concurrency)findings.push({severity:'warning',code:'scheduled_workflow_without_concurrency',message:`${file} is scheduled but has no top-level concurrency block.`});
  return {path:file.replace(/\\/g,'/'),name,triggers:[...triggers].sort(),cronSchedules:[...new Set(cron)],explicitPermissions,concurrencyConfigured:concurrency,firebaseDeployCommands:deploys,findings};
}
function parseScheduledFunctions(file, source) {
  const out=[], re=/exports\.([A-Za-z_$][\w$]*)\s*=\s*onSchedule\s*\(/g;
  for(const m of source.matchAll(re)){
    const s=source.slice(m.index,m.index+1600), a=s.match(/\bschedule\s*:\s*(['"`])([^'"`]+)\1/), b=s.match(/onSchedule\s*\(\s*(['"`])([^'"`]+)\1/);
    out.push({name:m[1],path:file.replace(/\\/g,'/'),schedule:(a?.[2]||b?.[2]||'').trim()||null});
  }
  return out;
}
function buildInventory(root=process.cwd()){
  const workflows=filesUnder(path.join(root,'.github','workflows'),/\.ya?ml$/i).map(f=>parseWorkflow(path.relative(root,f),fs.readFileSync(f,'utf8')));
  const functionsRoot=path.join(root,'functions');
  const scheduledFunctions=filesUnder(functionsRoot,/\.js$/i).filter(f=>!/(?:^|[\\/])test(?:[\\/]|$)|\.(?:test|spec)\.js$/i.test(path.relative(functionsRoot,f))).flatMap(f=>parseScheduledFunctions(path.relative(root,f),fs.readFileSync(f,'utf8'))).sort((a,b)=>a.path.localeCompare(b.path)||a.name.localeCompare(b.name));
  const findings=workflows.flatMap(w=>w.findings);
  for(const f of scheduledFunctions)if(!f.schedule)findings.push({severity:'warning',code:'scheduled_function_missing_static_schedule',message:`${f.path}:${f.name} schedule could not be read statically.`});
  return {workflows,scheduledFunctions,firebaseDeployCommandCount:workflows.reduce((n,w)=>n+w.firebaseDeployCommands.length,0),findings,violations:findings.filter(f=>f.severity==='error'),warnings:findings.filter(f=>f.severity==='warning')};
}
function cell(v){return String(v??'—').replace(/\\/g,'\\\\').replace(/\|/g,'\\|').replace(/\r?\n/g,' ');}
function renderMarkdown(x){
  const l=['# AUREN Automation Inventory','',`- GitHub Actions workflows: **${x.workflows.length}**`,`- Scheduled Cloud Functions: **${x.scheduledFunctions.length}**`,`- Firebase deploy commands: **${x.firebaseDeployCommandCount}**`,`- Safety violations: **${x.violations.length}**`,`- Review warnings: **${x.warnings.length}**`,'','## GitHub Actions workflows','','| Workflow | Triggers | Cron | Explicit permissions | Concurrency | Firebase targets |','|---|---|---|---|---|---|'];
  for(const w of x.workflows){const targets=w.firebaseDeployCommands.map(c=>c.targetProject||'MISSING').join(', ')||'—';l.push(`| ${cell(w.name)} (${cell(w.path)}) | ${cell(w.triggers.join(', ')||'unparsed')} | ${cell(w.cronSchedules.join('; ')||'—')} | ${w.explicitPermissions?'yes':'no'} | ${w.concurrencyConfigured?'yes':'no'} | ${cell(targets)} |`);}
  l.push('','## Scheduled Cloud Functions','','| Function | Source | Schedule |','|---|---|---|');
  if(!x.scheduledFunctions.length)l.push('| None detected | — | — |');
  else for(const f of x.scheduledFunctions)l.push(`| ${cell(f.name)} | ${cell(f.path)} | ${cell(f.schedule||'unparsed')} |`);
  l.push('','## Findings','');
  if(!x.findings.length)l.push('No findings.');else for(const f of x.findings)l.push(`- **${f.severity.toUpperCase()} · ${f.code}** — ${f.message}`);
  l.push('','Static inventory only: this tool does not execute jobs, contact providers, inspect secret values, or prove runtime availability.','');
  return l.join('\n');
}
function main(argv=process.argv.slice(2),root=process.cwd()){
  const i=argv.indexOf('--format'), format=i>=0?argv[i+1]:'markdown', x=buildInventory(root);
  console.log(format==='json'?JSON.stringify(x,null,2):renderMarkdown(x));
  if(x.violations.length)process.exitCode=1;
  return x;
}
module.exports={buildInventory,parseWorkflow,parseScheduledFunctions,renderMarkdown,main};
if(require.main===module)main();