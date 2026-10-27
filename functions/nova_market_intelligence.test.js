'use strict';
const {initializeApp}=require('firebase-admin/app');
try { initializeApp({projectId:'nova-market-intelligence-test'}); } catch (_) {}
const test=require('node:test');
const assert=require('node:assert/strict');
const {scoreMarketOpportunityForTest,marketResearchToolsForTest,marketSourceRegistryForTest,normalizeTopicForTest}=require('./nova_market_intelligence');

test('lists ten distinct Semrush-like research tools with official HTTPS links',()=>{const tools=marketResearchToolsForTest;assert.equal(tools.length,10);assert.equal(new Set(tools.map(x=>x.id)).size,10);for(const x of tools){assert.ok(x.name);assert.match(x.url,/^https:\/\//);assert.ok(x.access);}});
test('lists ten distinct evidence-source categories',()=>{const sources=marketSourceRegistryForTest;assert.equal(sources.length,10);assert.equal(new Set(sources.map(x=>x.id)).size,10);});
test('ready status requires independent evidence and feasible zero-cost validation',()=>{const row={trendScore:90,painScore:90,zeroCostBuildScore:85,paymentFeasibilityScore:75,paymentVerified:true,zeroCostValidated:true,competitionScore:65,evidenceStrength:80,sourceCount:3,signalCount:120};assert.equal(scoreMarketOpportunityForTest(row).eligibleForZeroCostTest,true);assert.equal(scoreMarketOpportunityForTest({...row,sourceCount:1}).eligibleForZeroCostTest,false);assert.equal(scoreMarketOpportunityForTest({...row,paymentFeasibilityScore:20}).eligibleForZeroCostTest,false);assert.equal(scoreMarketOpportunityForTest({...row,paymentVerified:false}).eligibleForZeroCostTest,false);assert.equal(scoreMarketOpportunityForTest({...row,zeroCostValidated:false}).eligibleForZeroCostTest,false);});
test('weak or missing evidence cannot become ready just from high trend',()=>{const row={trendScore:100,painScore:100,zeroCostBuildScore:20,paymentFeasibilityScore:10,competitionScore:100,evidenceStrength:0,sourceCount:0};const result=scoreMarketOpportunityForTest(row);assert.equal(result.eligibleForZeroCostTest,false);assert.ok(result.score>=0&&result.score<=100);});

test('normalizes whitespace in market topics',()=>{assert.equal(normalizeTopicForTest('  Arabic   AI  services  '),'Arabic AI services');assert.equal(normalizeTopicForTest('x'.repeat(150)).length,120);});
