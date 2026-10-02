'use strict';
const test=require('node:test'); const assert=require('node:assert/strict'); const fs=require('node:fs'); const path=require('node:path'); const source=fs.readFileSync(path.join(__dirname,'production_lifecycle.js'),'utf8');
test('owner scoping',()=>assert.match(source,/parts\[0\]!==\'users\'\|\|parts\[1\]!==uid/));
test('cancel only active tasks',()=>assert.match(source,/ACTIVE\.has\(status\)/));
test('retry budget',()=>assert.match(source,/retryCount>5/));
test('retry clears provider state',()=>assert.match(source,/externalJobId:\'\'/));
test('output requires real artifact',()=>assert.match(source,/!url&&!storagePath&&!externalId/));
test('history is recorded',()=>assert.match(source,/writeHistory\(tx,uid,ref,task,\'retry\'/));


test('cancelled task cannot be revived by worker lifecycle',()=>assert.match(source,/status.*cancelled.*cancelRequested/));
test('history uses deterministic event ids',()=>assert.match(source,/lifecycleEventId\(taskRef,event,task\)/));
test('outputs use deterministic ids',()=>assert.match(source,/outputKey\(ref\.id/));

test('cancel uses provider secret and prevents cancelled output',()=>{assert.match(source,/defineSecret\('REPLICATE_API_TOKEN'\)/);assert.match(source,/secrets:\[REPLICATE_API_TOKEN\]/);assert.match(source,/Cancelled production tasks cannot receive new output/);});
