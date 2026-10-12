'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {validateRequestIds, validateWaitingRequests} = require('./random_group_matching_core');

test('random group requires 3 to 8 unique request IDs', () => {
  assert.deepEqual(validateRequestIds(['a','b','c']), ['a','b','c']);
  assert.throws(() => validateRequestIds(['a','b']), /3 to 8/);
  assert.throws(() => validateRequestIds(['a','b','a']), /unique/);
  assert.throws(() => validateRequestIds(['a','b',null]), /non-empty/);
});

test('random group requests must be waiting, same size, and owned by distinct users', () => {
  const rows = [
    {uid:'owner', status:'waiting', groupSize:3},
    {uid:'one', status:'waiting', groupSize:3},
    {uid:'two', status:'waiting', groupSize:3},
  ];
  assert.deepEqual(validateWaitingRequests(rows, 'owner', 3), ['owner','one','two']);
  assert.throws(() => validateWaitingRequests(rows.slice(1), 'owner', 3), /size/);
  assert.throws(() => validateWaitingRequests(rows.map((x,i)=>i===2?{...x,uid:'one'}:x), 'owner', 3), /different user/);
  assert.throws(() => validateWaitingRequests(rows.map((x,i)=>i===1?{...x,status:'grouped'}:x), 'owner', 3), /still be waiting/);
  assert.throws(() => validateWaitingRequests(rows.map((x,i)=>i===2?{...x,groupSize:4}:x), 'owner', 3), /still be waiting/);
});
