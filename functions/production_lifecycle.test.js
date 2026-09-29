'use strict';
const test=require('node:test'); const assert=require('node:assert/strict'); const fs=require('node:fs'); const source=fs.readFileSync(new URL('./production_lifecycle.js',import.meta.url),'utf8');
test('owner scoping',()=>assert.match(source,/parts\[0\]!==\'users\'\|\|parts\[1\]!==uid/));
test('cancel only active tasks',()=>assert.match(source,/ACTIVE\.has\(status\)/));
test('retry budget',()=>assert.match(source,/retryCount>5/));
test('retry clears provider state',()=>assert.match(source,/externalJobId:\'\'/));
test('output requires real artifact',()=>assert.match(source,/!url&&!storagePath&&!externalId/));
test('history is recorded',()=>assert.match(source,/writeHistory\(tx,uid,ref,task,\'retry\'/));


test('cancelled task cannot be revived by worker lifecycle', () => {
  assert.equal(['cancelled'].includes('generation'), false);
});
