import test from 'node:test';
import assert from 'node:assert/strict';
import { validateCommerceRequest } from '../src/commerce.js';

test('commerce requests require a valid agent, currency, positive amount and strong idempotency key', () => {
  const base={agentId:'agent-1',currency:'USD',amountMinor:100,idempotencyKey:'1234567890123456'};
  assert.equal(validateCommerceRequest(base),true);
  assert.equal(validateCommerceRequest({...base,currency:'usd'}),false);
  assert.equal(validateCommerceRequest({...base,amountMinor:0}),false);
  assert.equal(validateCommerceRequest({...base,idempotencyKey:'short'}),false);
  assert.equal(validateCommerceRequest({...base,agentId:''}),false);
});
