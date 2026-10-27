'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {normalizeLesson, buildLearningContext, buildImprovementLoop} = require('./nova_grok_learning');

test('accepts concise user-confirmed correction lessons', () => {
  assert.deepEqual(normalizeLesson({type: 'correction', lesson: 'Check the Flutter test output before saying passed.'}), {
    type: 'correction',
    lesson: 'Check the Flutter test output before saying passed.',
    confirmedByUser: true,
  });
});

test('rejects unsupported lesson types and secret-like content', () => {
  assert.throws(() => normalizeLesson({type: 'random', lesson: 'Use concise answers'}));
  assert.throws(() => normalizeLesson({type: 'preference', lesson: 'My API key is abc123'}), /لا تحفظ/);
});

test('only includes confirmed lessons and caps the context size', () => {
  const records = Array.from({length: 12}, (_, i) => ({type: 'preference', lesson: 'Lesson ' + i, confirmedByUser: true}));
  records.push({type: 'correction', lesson: 'Unconfirmed', confirmedByUser: false});
  const context = buildLearningContext(records);
  assert.equal(context.length, 8);
  assert.equal(context.some((item) => item.lesson === 'Unconfirmed'), false);
});

test('describes a measurable improvement loop without claiming model training', () => {
  const loop = buildImprovementLoop({draft: 'draft', feedback: 'too long', previousOutcome: 'test failed'});
  assert.equal(loop.draftProvided, true);
  assert.equal(loop.feedbackProvided, true);
  assert.equal(loop.outcomeEvidenceProvided, true);
  assert.equal(loop.autoTrainingClaim, false);
});
