'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeGrokInput, buildGrokInput, extractResponseText, normalizeGrokReply} = require('./nova_grok_bot_core');

test('normalizes supported modes and bounds user input', () => {
  assert.equal(normalizeGrokInput({prompt:'مرحبا', mode:'research'}).mode, 'research');
  assert.equal(normalizeGrokInput({prompt:'مرحبا', mode:'unknown'}).mode, 'chat');
  assert.throws(() => normalizeGrokInput({prompt:'  '}), /اكتب ما تريد/);
  assert.throws(() => normalizeGrokInput({prompt:'x'.repeat(6001)}), /6000/);
  assert.equal(normalizeGrokInput({prompt:'hello', context:'c'.repeat(11000)}).context.length, 10000);
});

test('builds unified assistant instructions with approval guardrails', () => {
  const message = buildGrokInput({mode:'coding'});
  assert.match(message.content, /You do not have execution tools/);
  assert.match(message.content, /explicit user approval/);
  assert.match(message.content, /coding/);
});

test('extracts text from Responses API output_text or output content', () => {
  assert.equal(extractResponseText({output_text:'{"answer":"ok"}'}), '{"answer":"ok"}');
  assert.equal(extractResponseText({output:[{content:[{type:'output_text',text:'hello'}]}]}), 'hello');
  assert.equal(extractResponseText({output:[]}), '');
});

test('normalizes structured response and never lets the model waive approval', () => {
  const result = normalizeGrokReply(JSON.stringify({
    answer:'Plan prepared', summary:'Plan',
    nextSteps:Array.from({length:10}, (_, i) => 'step ' + i),
    proposedAction:'Publish a video', requiresApproval:false,
  }));
  assert.equal(result.answer, 'Plan prepared');
  assert.equal(result.nextSteps.length, 6);
  assert.equal(result.requiresApproval, true);
  assert.equal(result.proposedAction, 'Publish a video');
});

test('falls back to plain text while refusing an empty response', () => {
  assert.equal(normalizeGrokReply('plain answer').answer, 'plain answer');
  assert.throws(() => normalizeGrokReply(''), /إجابة قابلة للعرض/);
});
