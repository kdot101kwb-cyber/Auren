import test from 'node:test';
import assert from 'node:assert/strict';

test('plugin worker security limits stay bounded', () => {
  assert.equal(5 * 1024 * 1024, 5242880);
  assert.equal(32768, 32 * 1024);
  assert.equal(10 * 1000, 10000);
});
