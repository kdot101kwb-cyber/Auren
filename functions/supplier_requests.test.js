'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const lifecycle = require('./supplier_request_lifecycle');

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
  assert.match(source, /tx\.create\(ref,data\)/);
  assert.match(source, /tx\.create\(userRef,data\)/);
  assert.match(source, /db\.runTransaction\(async tx =>/);
  assert.match(source, /updateMatchFlow\(uid,matchFlowId,'active'/);
  assert.match(source, /supplierWorkflowStatus:'draft'/);
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

test('supplier lifecycle endpoint delegates status transitions to shared policy', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /lifecycle\.isAllowedTransition/);
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
  assert.match(cancelSource, /updateMatchFlowInTransaction\(tx, uid, data\.matchFlowId, 'cancelled'/);
});

test('supplier status updates recheck state inside transaction to prevent stale writes', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /const fresh = await tx\.get\(ref\)/);
  assert.match(source, /freshStatus !== currentStatus/);
  assert.match(source, /Supplier request changed; refresh and try again/);
});

test('cancel and retry keep Match Flow status consistent without dispatching messages', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /updateMatchFlowInTransaction\(tx, uid, data\.matchFlowId, 'cancelled'/);
  assert.match(source, /updateMatchFlowInTransaction\(tx, uid, data\.matchFlowId, 'active', \{retryCount\}\)/);
  assert.match(source, /status:'draft', retryCount, externalDispatch:false/);
  assert.match(source, /Only failed or cancelled requests can be retried/);
  assert.match(source, /Retry limit reached/);
});

test('supplier retry rechecks eligibility and retry count inside its transaction', () => {
  const source = read('supplier_requests.js');
  const retrySource = source.slice(source.indexOf('exports.retryAurenSupplierRequest'));
  assert.match(retrySource, /const fresh = await tx\.get\(ref\)/);
  assert.match(retrySource, /const currentStatus = lifecycle\.normalizeStatus\(data\.status, ''\)/);
  assert.match(retrySource, /Only failed or cancelled requests can be retried/);
  assert.match(retrySource, /lifecycle\.nextRetryCount\(data\.retryCount\)/);
  assert.match(retrySource, /const retryCount = retry\.count/);
  assert.match(retrySource, /Retry limit reached/);
  assert.match(retrySource, /tx\.set\(ref, update, \{merge:true\}\)/);
  assert.match(retrySource, /if \(globalFresh\.exists\) tx\.set\(globalRef, update, \{merge:true\}\)/);
});

test('supplier request idempotency cannot disclose or reuse another account request', () => {
  const source = read('supplier_actions.js');
  assert.match(source, /const previous = existing\.data\(\) \|\| \{\};/);
  assert.match(source, /previous\.requesterUid !== uid/);
  assert.match(source, /Idempotency key is already used by another account/);
  assert.match(source, /permission-denied/);
  // Both contact and RFQ paths independently enforce ownership before returning.
  assert.equal((source.match(/previous\.requesterUid !== uid/g) || []).length, 2);
  assert.equal((source.match(/const outcome = await db\.runTransaction\(async tx =>/g) || []).length, 2);
});

test('creating a supplier draft does not falsely mark a supplier as contacted', () => {
  const source = read('supplier_actions.js');
  assert.match(source, /Creating a local draft is not evidence that the supplier was contacted/);
  assert.match(source, /A saved RFQ draft is not sent to the supplier/);
  assert.doesNotMatch(source, /updateMatchFlow\(uid,matchFlowId,'waiting_response'/);
  assert.match(source, /externalDispatch:false/);
});

test('supplier lifecycle refuses to mutate a global mirror owned by another account', () => {
  const source = read('supplier_requests.js');
  assert.equal((source.match(/globalFresh\.data\(\)\?\.requesterUid !== uid/g) || []).length, 3);
  assert.equal((source.match(/if \(globalFresh\.exists\) tx\.set\(/g) || []).length, 3);
  assert.match(source, /Supplier request mirror belongs to another account/);
});

test('supplier request idempotency reads and creates both records atomically', () => {
  const source = read('supplier_actions.js');
  assert.equal((source.match(/const outcome = await db\.runTransaction\(async tx =>/g) || []).length, 2);
  assert.equal((source.match(/tx\.create\(ref,data\)/g) || []).length, 2);
  assert.equal((source.match(/tx\.create\(userRef,data\)/g) || []).length, 2);
  assert.equal((source.match(/const existingUser = await tx\.get\(userRef\)/g) || []).length, 2);
});

test('supplier response lifecycle requires evidence of external dispatch', () => {
  const source = read('supplier_requests.js');
  assert.equal((source.match(/lifecycle\.requiresExternalDispatch\(nextStatus, (?:data|freshData)\.externalDispatch\)/g) || []).length, 2);
  assert.match(source, /cannot be marked as awaiting or receiving a supplier response/);
});

test('supplier request API keeps document identity authoritative over stored payload fields', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /return \{\.\.\.snap\.data\(\), id:snap\.id, type\};/);
  assert.match(source, /contacts\.docs\.map\(d=>\(\{\.\.\.d\.data\(\),id:d\.id,type:'contact'\}\)\)/);
  assert.match(source, /rfqs\.docs\.map\(d=>\(\{\.\.\.d\.data\(\),id:d\.id,type:'rfq'\}\)\)/);
});

test('supplier request listing clamps limits to integer values within 1–100', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /Number\.isFinite\(requestedLimit\)/);
  assert.match(source, /Math\.floor\(requestedLimit\)/);
  assert.match(source, /Math\.min\(Math\.max\(Math\.floor\(requestedLimit\), 1\), 100\)/);
});


test('supplier lifecycle policy allows only documented status transitions', () => {
  const allowed = [
    ['draft', 'waiting_response'],
    ['draft', 'failed'],
    ['draft', 'cancelled'],
    ['waiting_response', 'replied'],
    ['waiting_response', 'completed'],
    ['waiting_response', 'failed'],
    ['waiting_response', 'cancelled'],
    ['replied', 'completed'],
    ['replied', 'cancelled'],
    ['failed', 'cancelled'],
    ['cancelled', 'cancelled'],
    ['completed', 'completed'],
  ];
  for (const [current, next] of allowed) {
    assert.equal(lifecycle.isAllowedTransition(current, next), true, current + ' -> ' + next);
  }
  const denied = [
    ['draft', 'replied'],
    ['draft', 'completed'],
    ['waiting_response', 'draft'],
    ['replied', 'waiting_response'],
    ['failed', 'draft'],
    ['cancelled', 'draft'],
    ['completed', 'cancelled'],
    ['unknown', 'draft'],
  ];
  for (const [current, next] of denied) {
    assert.equal(lifecycle.isAllowedTransition(current, next), false, current + ' -> ' + next);
  }
});

test('supplier lifecycle requires confirmed dispatch before response statuses', () => {
  for (const status of ['waiting_response', 'replied']) {
    assert.equal(lifecycle.requiresExternalDispatch(status, false), true);
    assert.equal(lifecycle.requiresExternalDispatch(status, undefined), true);
    assert.equal(lifecycle.requiresExternalDispatch(status, true), false);
  }
  for (const status of ['draft', 'failed', 'cancelled', 'completed']) {
    assert.equal(lifecycle.requiresExternalDispatch(status, false), false);
  }
});

test('supplier retry policy accepts counts zero through four and stops at five', () => {
  for (let count = 0; count < 5; count += 1) {
    assert.deepEqual(lifecycle.nextRetryCount(count), {ok: true, count: count + 1});
  }
  assert.deepEqual(lifecycle.nextRetryCount(5), {ok: false, reason: 'limit-reached'});
});

test('supplier retry policy rejects corrupt negative, fractional, unsafe, and nonnumeric counts', () => {
  for (const count of [-1, 1.5, Number.MAX_SAFE_INTEGER + 1, 'not-a-number']) {
    assert.deepEqual(lifecycle.nextRetryCount(count), {ok: false, reason: 'invalid-count'});
  }
  assert.deepEqual(lifecycle.nextRetryCount(null), {ok: true, count: 1});
});

test('supplier status normalization is case-insensitive and defaults empty values to draft', () => {
  assert.equal(lifecycle.normalizeStatus(' RePlIeD '), 'replied');
  assert.equal(lifecycle.normalizeStatus(''), 'draft');
  assert.equal(lifecycle.normalizeStatus(null), 'draft');
});

test('supplier lifecycle updates Match Flow inside the same transaction as request state', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /async function updateMatchFlowInTransaction\(tx, uid, flowId, status, extra = \{\}\)/);
  assert.equal((source.match(/updateMatchFlowInTransaction\(tx, uid, (?:data|freshData)\./g) || []).length, 3);
  assert.doesNotMatch(source, /await updateMatchFlow\(uid,\s*(?:cancelled|retry)\.matchFlowId/);
});

test('supplier lifecycle trims stored statuses before terminal and retry checks', () => {
  const source = read('supplier_requests.js');
  assert.match(source, /const currentStatus = lifecycle\.normalizeStatus\(data\.status\)/);
  assert.match(source, /const freshStatus = lifecycle\.normalizeStatus\(freshData\.status\)/);
  assert.match(source, /const currentStatus = lifecycle\.normalizeStatus\(data\.status, ''\)/);
  assert.doesNotMatch(source, /async function updateMatchFlow\(/);
});
