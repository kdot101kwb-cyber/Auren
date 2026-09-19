import test from 'node:test';
import assert from 'node:assert/strict';

test('worker entrypoint policy only permits mounted plugin files',()=>{
  const allowed=/^\/app\/plugins\/[a-z0-9._-]{3,64}\/[^/]+\.js$/;
  assert.equal(allowed.test('/app/plugins/demo/plugin.js'),true);
  assert.equal(allowed.test('/etc/passwd'),false);
  assert.equal(allowed.test('/app/plugins/../../escape.js'),false);
});
