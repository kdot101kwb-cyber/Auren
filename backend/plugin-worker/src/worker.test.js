import test from 'node:test';
import assert from 'node:assert/strict';

test('worker entrypoint policy only permits relative mounted plugin files',()=>{
  const allowed=/^([a-z0-9._-]{3,64})\/([^/]+\.js)$/;
  assert.equal(allowed.test('demo/plugin.js'),true);
  assert.equal(allowed.test('plugin-1/main.js'),true);
  assert.equal(allowed.test('/app/plugins/demo/plugin.js'),false);
  assert.equal(allowed.test('../escape.js'),false);
  assert.equal(allowed.test('demo/../../escape.js'),false);
  assert.equal(allowed.test('Demo/plugin.js'),false);
  assert.equal(allowed.test('demo/plugin.txt'),false);
});
