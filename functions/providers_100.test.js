'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const {PROVIDERS_100,listAuren100Providers,getAuren100Provider,getAuren100FreeFirst}=require('./providers_100');
test('AUREN catalog contains exactly 100 providers',()=>assert.equal(PROVIDERS_100.length,100));
test('provider ids are unique',()=>assert.equal(new Set(PROVIDERS_100.map(p=>p.id)).size,100));
test('video catalog has multiple providers',()=>assert.ok(listAuren100Providers('video').length>=10));
test('free-first ordering is deterministic',()=>{const a=getAuren100FreeFirst('text');for(let i=1;i<a.length;i++){if(a[i-1].freeTier===a[i].freeTier)assert.ok(a[i-1].rank<=a[i].rank);}});
test('unknown provider is not executable',()=>assert.equal(getAuren100Provider('missing_provider'),null));
