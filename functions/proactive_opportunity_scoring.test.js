'use strict';
const test=require('node:test');
const assert=require('node:assert/strict');
const {scoreOpportunitySignal,alertDocumentId}=require('./proactive_opportunity_scoring');
const now=Date.parse('2026-10-25T12:00:00Z');
function signal(overrides={}){return {demand:95,trend:90,monetization:90,evidenceStrength:90,competition:15,executionCost:20,sourceTrust:90,observedAt:'2026-10-25T06:00:00Z',...overrides};}
test('strong fresh evidence qualifies for proactive alert',()=>{const r=scoreOpportunitySignal(signal(),now);assert.equal(r.eligible,true);assert.ok(r.score>=80);assert.equal(r.freshness,100);});
test('stale signal is not eligible even when old scores are high',()=>{const r=scoreOpportunitySignal(signal({observedAt:'2026-10-01T00:00:00Z'}),now);assert.equal(r.eligible,false);assert.equal(r.freshness,0);});
test('weak evidence or untrusted source cannot trigger an alert',()=>{assert.equal(scoreOpportunitySignal(signal({evidenceStrength:20}),now).eligible,false);assert.equal(scoreOpportunitySignal(signal({sourceTrust:10}),now).eligible,false);});
test('invalid scores and timestamps are rejected, not guessed',()=>{assert.throws(()=>scoreOpportunitySignal(signal({demand:101}),now),/demand/);assert.throws(()=>scoreOpportunitySignal(signal({observedAt:'not-a-date'}),now),/observedAt/);});
test('alert IDs are stable and scoped to user plus signal',()=>{assert.equal(alertDocumentId('u1','s1'),alertDocumentId('u1','s1'));assert.notEqual(alertDocumentId('u1','s1'),alertDocumentId('u2','s1'));assert.notEqual(alertDocumentId('u1','s1'),alertDocumentId('u1','s2'));});
