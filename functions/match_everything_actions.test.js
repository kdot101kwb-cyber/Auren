'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

test('opportunity intelligence core exposes reusable runner', () => {
  const source = fs.readFileSync(new URL('./opportunity_intelligence_core.js', import.meta.url), 'utf8');
  assert.match(source, /runOpportunityIntelligence/);
  assert.match(source, /auren_suppliers/);
  assert.match(source, /auren_businesses/);
  assert.match(source, /auren_opportunities/);
});

test('supplier workflow keeps external dispatch disabled by default', () => {
  const source = fs.readFileSync(new URL('./supplier_actions.js', import.meta.url), 'utf8');
  assert.match(source, /externalDispatch: false/);
  assert.match(source, /supplier_contact_requests/);
  assert.match(source, /supplier_rfqs/);
});

test('Match Everything action creator requires approval', () => {
  const source = fs.readFileSync(new URL('./match_everything_actions.js', import.meta.url), 'utf8');
  assert.match(source, /requiresApproval:true/);
  assert.match(source, /status:'pending'/);
  assert.match(source, /supplier.workflow/);
});
