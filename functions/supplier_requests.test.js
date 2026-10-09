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

test('supplier lifecycle restricts status transitions and keeps terminal states terminal', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /draft: new Set\(\['waiting_response', 'failed', 'cancelled'\]\)/);
  assert.match(source, /waiting_response: new Set\(\['replied', 'completed', 'failed', 'cancelled'\]\)/);
  assert.match(source, /replied: new Set\(\['completed', 'cancelled'\]\)/);
  assert.match(source, /cancelled: new Set\(\)/);
  assert.match(source, /Invalid supplier request status transition/);
});

test('supplier cancellation rechecks terminal state inside transaction', () => {
  const source = read('supplier_requests.js');
  const cancelSource = source.slice(
    source.indexOf('exports.cancelAurenSupplierRequest'),
    source.indexOf('exports.updateAurenSupplierRequestStatus'),
  );
  assert.match(cancelSource, /await db\.runTransaction\(async tx =>/);
  assert.match(cancelSource, /const fresh = await tx\.get\(ref\)/);
  assert.match(cancelSource, /\['completed','cancelled'\]\.includes\(currentStatus\)/);
  assert.match(cancelSource, /tx\.set\(globalRef, update, \{merge:true\}\)/);
  assert.match(cancelSource, /updateMatchFlow\(uid,cancelled\.matchFlowId,'cancelled'/);
});

test('supplier status updates recheck state inside transaction to prevent stale writes', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /const fresh = await tx\.get\(ref\)/);
  assert.match(source, /freshStatus !== currentStatus/);
  assert.match(source, /Supplier request changed; refresh and try again/);
});

test('cancel and retry keep Match Flow status consistent without dispatching messages', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /updateMatchFlow\(uid,cancelled\.matchFlowId,'cancelled'/);
  assert.match(source, /updateMatchFlow\(uid,retry\.matchFlowId,'active'/);
  assert.match(source, /status:'draft', retryCount, externalDispatch:false/);
  assert.match(source, /Only failed or cancelled requests can be retried/);
  assert.match(source, /Retry limit reached/);
});

test('supplier retry rechecks eligibility and retry count inside its transaction', () => {
  const source = read('supplier_requests.js');
  const retrySource = source.slice(source.indexOf('exports.retryAurenSupplierRequest'));
  assert.match(retrySource, /const fresh = await tx\.get\(ref\)/);
  assert.match(retrySource, /const currentStatus = String\(data\.status \|\| ''\)\.toLowerCase\(\)/);
  assert.match(retrySource, /Only failed or cancelled requests can be retried/);
  assert.match(retrySource, /const retryCount = Number\(data\.retryCount \|\| 0\) \+ 1/);
  assert.match(retrySource, /Retry limit reached/);
  assert.match(retrySource, /tx\.set\(ref, update, \{merge:true\}\)/);
  assert.match(retrySource, /tx\.set\(globalRef, update, \{merge:true\}\)/);
});
