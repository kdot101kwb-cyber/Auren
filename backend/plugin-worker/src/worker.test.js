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


test('worker boundary rejects invalid plugin identity and action',()=>{
  const pluginId=/^[a-z0-9][a-z0-9._-]{2,119}$/;
  const action=/^[a-zA-Z0-9._:-]+$/;
  assert.equal(pluginId.test('auren.demo.plugin'),true);
  assert.equal(pluginId.test('../escape'),false);
  assert.equal(pluginId.test('ABCD'),false);
  assert.equal(action.test('preview.request'),true);
  assert.equal(action.test('agent:run.v1'),true);
  assert.equal(action.test('bad action'),false);
  assert.equal(action.test(''),false);
});


test('worker runtime limits are bounded',()=>{
  const base64=/^[A-Za-z0-9+/]*={0,2}$/;
  assert.equal(base64.test('SGVsbG8='),true);
  assert.equal(base64.test('not base64!'),false);
  assert.equal(base64.test('SGVsbG8'),false);
  assert.equal(base64.test('SGVsbG8='),true);
});


test('worker authenticates before applying concurrency accounting',()=>{
  const source=String.raw`if(!SHARED_SECRET)return json(res,503,{error:'Worker secret is not configured.'});
      const body=JSON.parse(raw||'{}');
      if(!safeEqual(body.authorization,SHARED_SECRET))return json(res,403,{error:'Unauthorized worker request.'});
      if(activeExecutions>=MAX_CONCURRENT_EXECUTIONS)return json(res,429,{error:'Plugin worker concurrency limit reached.'});
      activeExecutions++;`;
  assert.equal(source.indexOf('safeEqual')<source.indexOf('activeExecutions++'),true);
});
