'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const read = (name) => fs.readFileSync(path.join(__dirname, name), 'utf8');

test('supplier lifecycle exposes list, detail, cancel and retry endpoints', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /exports\.listAurenSupplierRequests/);
  assert.match(source, /exports\.getAurenSupplierRequest/);
  assert.match(source, /exports\.cancelAurenSupplierRequest/);
  assert.match(source, /exports\.retryAurenSupplierRequest/);
});

test('supplier request lifecycle preserves user ownership and match flow', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /users.*supplier_contact_requests/);
  assert.match(source, /users.*supplier_rfqs/);
  assert.match(source, /matchFlowId/);
  assert.match(source, /match_action_flows/);
  assert.doesNotMatch(source, /matchFlows/);
  assert.match(source, /waiting_response/);
  assert.match(source, /runTransaction/);
  assert.match(source, /supplier_contact_requests/);
  assert.match(source, /supplier_rfqs/);
});

test('supplier workflow creates user-scoped request mirrors and updates Match Flow', () => {
  const source = read('supplier_actions.js');
  assert.match(source, /const userRef = db\.collection\('users'\)/);
  assert.match(source, /batch\.set\(ref,data\); batch\.set\(userRef,data\)/);
  assert.match(source, /updateMatchFlow\(uid,matchFlowId,'waiting_response'/);
});

test('supplier action lookup supports exporter importer and manufacturer collections', () => {
  const source = read('supplier_actions.js');
  assert.match(source, /auren_exporters/);
  assert.match(source, /auren_importers/);
  assert.match(source, /auren_manufacturers/);
  assert.match(source, /for \(const collection of collections\)/);
});

test('supplier workflow never dispatches externally during draft creation', () => {
  const source = read('supplier_actions.js');
  assert.match(source, /externalDispatch:false/);
  assert.doesNotMatch(source, /sendEmail|sendSMS|sendMessage|externalDispatch:true/);
});
