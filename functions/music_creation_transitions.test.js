'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {resolveMusicSubmission, resolveMusicPoll} = require('./music_creation_transitions');

test('submission accepts only a validated materialized artifact as output', () => {
  const output = {url: 'https://cdn.example.test/song.mp3'};
  assert.deepEqual(
    resolveMusicSubmission({result: {ok: true, output, state: 'succeeded'}, artifactCheck: {ok: true, contentType: 'audio/mpeg'}}),
    {
      status: 'output',
      output,
      externalJobId: '',
      providerState: 'succeeded',
      artifactValidation: {ok: true, contentType: 'audio/mpeg'},
      lastError: '',
    },
  );
});

test('submission keeps accepted asynchronous jobs processing', () => {
  assert.deepEqual(
    resolveMusicSubmission({result: {ok: true, providerId: 'replicate', externalJobId: 'job-123', state: 'starting'}}),
    {
      status: 'processing',
      output: null,
      externalJobId: 'job-123',
      providerState: 'starting',
      lastError: '',
    },
  );
});

test('submission does not mark an invalid artifact ready', () => {
  const output = {url: 'https://cdn.example.test/song.mp3'};
  const artifactValidation = {ok: false, reason: 'not_audio'};
  const transition = resolveMusicSubmission({
    result: {ok: true, output, state: 'succeeded'},
    artifactCheck: artifactValidation,
  });
  assert.equal(transition.status, 'queued');
  assert.equal(transition.output, null);
  assert.equal(transition.providerState, 'artifact_validation_failed');
  assert.equal(transition.artifactValidation, artifactValidation);
  assert.match(transition.lastError, /not_audio/);
});

test('submission failure remains retryable and a response without an artifact fails safely', () => {
  assert.equal(resolveMusicSubmission({result: {ok: false, message: 'provider busy'}}).status, 'queued');
  assert.equal(resolveMusicSubmission({result: {ok: false, message: 'provider busy'}}).lastError, 'provider busy');
  const empty = resolveMusicSubmission({result: {ok: true, state: 'succeeded'}});
  assert.equal(empty.status, 'failed');
  assert.equal(empty.output, null);
  assert.equal(empty.lastError, 'Provider returned no artifact.');
});

test('poll accepts a completed provider job only when its artifact is validated', () => {
  const output = {storagePath: 'music/song.mp3'};
  const artifactValidation = {ok: true, storagePath: 'music/song.mp3', contentType: 'audio/mpeg'};
  assert.deepEqual(
    resolveMusicPoll({
      pollResult: {ok: true, state: 'completed', output},
      attempts: 1,
      maxAttempts: 5,
      artifactCheck: artifactValidation,
    }),
    {
      status: 'output',
      output,
      artifactValidation,
      externalJobId: '',
      lockUntilMs: 0,
      providerState: 'completed',
      lastError: '',
    },
  );
});

test('completed provider job without a materialized artifact enters waiting_provider', () => {
  const transition = resolveMusicPoll({
    pollResult: {ok: true, state: 'succeeded', output: {externalId: 'provider-only-id'}},
    attempts: 1,
    maxAttempts: 5,
  });
  assert.equal(transition.status, 'waiting_provider');
  assert.equal(transition.output, null);
  assert.equal(transition.externalJobId, '');
  assert.equal(transition.providerState, 'artifact_validation_failed');
  assert.deepEqual(transition.artifactValidation, {ok: false, reason: 'artifact_not_materialized'});
  assert.match(transition.lastError, /artifact_not_materialized/);
});

test('failed provider polls retry below the attempt limit and stop at the limit', () => {
  assert.deepEqual(
    resolveMusicPoll({pollResult: {state: 'failed', error: 'temporary'}, attempts: 2, maxAttempts: 5}),
    {status: 'queued', externalJobId: '', lockUntilMs: 0, lastError: 'temporary'},
  );
  assert.equal(
    resolveMusicPoll({pollResult: {state: 'canceled'}, attempts: 5, maxAttempts: 5}).status,
    'failed',
  );
});

test('non-terminal poll remains processing without discarding provider state', () => {
  assert.deepEqual(
    resolveMusicPoll({pollResult: {ok: true, state: 'running'}, attempts: 1, maxAttempts: 5}),
    {status: 'processing', lockUntilMs: 0, providerState: 'running'},
  );
});

test('matches the actual provider adapter contract with a direct result payload', () => {
  const output = {url: 'https://cdn.example.test/direct-track.mp3'};
  const completed = resolveMusicSubmission({
    result: {
      ok: true,
      providerId: 'replicate',
      state: 'succeeded',
      output,
      externalJobId: 'prediction-should-not-be-kept',
    },
    artifactCheck: {ok: true, contentType: 'audio/mpeg'},
  });
  assert.equal(completed.status, 'output');
  assert.deepEqual(completed.output, output);
  assert.equal(completed.externalJobId, '');
  assert.equal(completed.providerState, 'succeeded');

  const pending = resolveMusicSubmission({
    result: {
      ok: true,
      providerId: 'replicate',
      state: 'starting',
      output: null,
      externalJobId: 'prediction-123',
    },
  });
  assert.equal(pending.status, 'processing');
  assert.equal(pending.externalJobId, 'prediction-123');
  assert.equal(pending.providerState, 'starting');
});

test('direct provider result with no output preserves its external job id', () => {
  const transition = resolveMusicSubmission({
    result: {
      ok: true,
      providerId: 'replicate',
      state: 'processing',
      externalJobId: 'prediction-456',
      output: null,
    },
  });
  assert.equal(transition.status, 'processing');
  assert.equal(transition.externalJobId, 'prediction-456');
  assert.equal(transition.output, null);
});
