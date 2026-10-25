'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {validateEndpoint, normalizeStatus, submitVideoGeneration, getVideoGenerationStatus} = require('./nova_higgsfield_adapter');

test('only accepts model endpoints hosted on the official Higgsfield API', () => {
  assert.equal(validateEndpoint('https://api.higgsfield.ai/higgsfield/example/model/v1'), 'https://api.higgsfield.ai/higgsfield/example/model/v1');
  assert.throws(() => validateEndpoint('https://evil.example/higgsfield/model'), /official/);
  assert.throws(() => validateEndpoint('http://api.higgsfield.ai/higgsfield/model'), /HTTPS/);
  assert.throws(() => validateEndpoint('https://api.higgsfield.ai/higgsfield/../admin'), /allowed/);
});

test('normalizes queued, completed, and failed provider states', () => {
  assert.equal(normalizeStatus({status:'queued'}).status, 'processing');
  assert.deepEqual(normalizeStatus({status:'completed', video_url:'https://cdn.example/video.mp4'}), {
    status:'succeeded', outputUrl:'https://cdn.example/video.mp4', rawStatus:'completed',
  });
  assert.equal(normalizeStatus({status:'failed', error:'model error'}).error, 'model error');
});

test('submits a prompt with server credentials and returns async request metadata', async () => {
  let seen;
  const result = await submitVideoGeneration({
    endpoint:'https://api.higgsfield.ai/higgsfield/example/video/v1',
    prompt:'Create a vertical technology short',
    keyId:'test-id',
    keySecret:'test-secret',
    fetchImpl:async (url, init) => {
      seen = {url, init};
      return {ok:true, status:200, text:async () => JSON.stringify({status:'queued', request_id:'request_12345678'})};
    },
  });
  assert.match(seen.init.headers.authorization, /^Key test-id:test-secret$/);
  assert.deepEqual(JSON.parse(seen.init.body), {prompt:'Create a vertical technology short'});
  assert.equal(result.requestId, 'request_12345678');
  assert.equal(result.statusUrl, 'https://api.higgsfield.ai/requests/request_12345678/status');
});

test('status polling uses the official request status endpoint', async () => {
  let seenUrl;
  const status = await getVideoGenerationStatus({
    requestId:'request_12345678', keyId:'id', keySecret:'secret',
    fetchImpl:async (url) => {
      seenUrl = url;
      return {ok:true, status:200, text:async () => JSON.stringify({status:'completed', output_url:'https://cdn.example/out.mp4'})};
    },
  });
  assert.equal(seenUrl, 'https://api.higgsfield.ai/requests/request_12345678/status');
  assert.equal(status.status, 'succeeded');
  assert.equal(status.outputUrl, 'https://cdn.example/out.mp4');
});

test('rejects missing credentials, invalid prompts, and malformed request ids', async () => {
  await assert.rejects(() => submitVideoGeneration({endpoint:'https://api.higgsfield.ai/higgsfield/example/v1', prompt:'x'}), /credentials/);
  await assert.rejects(() => submitVideoGeneration({endpoint:'https://api.higgsfield.ai/higgsfield/example/v1', prompt:' '}), /prompt/);
  await assert.rejects(() => getVideoGenerationStatus({requestId:'bad', keyId:'id', keySecret:'secret'}), /request ID/);
});
