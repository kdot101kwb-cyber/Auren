'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  LIMITS,
  normalizeAurenMusicProductionRequest,
} = require('./music_production_validation');

test('normalizes valid music production input and trims bounded strings', () => {
  const result = normalizeAurenMusicProductionRequest({
    title: '  First Track  ',
    prompt: '  original afrobeat idea  ',
    genre: ' Afrobeat ',
    mood: 'Joyful',
    language: 'Arabic',
    durationSeconds: 45,
  });
  assert.equal(result.ok, true);
  assert.deepEqual(result.value, {
    title: 'First Track',
    prompt: 'original afrobeat idea',
    genre: 'Afrobeat',
    mood: 'Joyful',
    language: 'Arabic',
    durationSeconds: 45,
  });
});

test('uses defaults when optional values are omitted', () => {
  const result = normalizeAurenMusicProductionRequest({prompt: 'A new song'});
  assert.equal(result.ok, true);
  assert.equal(result.value.title, 'AUREN Original Track');
  assert.equal(result.value.durationSeconds, LIMITS.defaultDurationSeconds);
});

test('rejects an empty or whitespace-only prompt', () => {
  for (const prompt of ['', '   ', null, undefined]) {
    const result = normalizeAurenMusicProductionRequest({prompt});
    assert.equal(result.ok, false);
    assert.match(result.message, /prompt is required/i);
  }
});

test('rejects non-finite durations instead of persisting NaN', () => {
  for (const durationSeconds of ['not-a-number', NaN, Infinity, -Infinity]) {
    const result = normalizeAurenMusicProductionRequest({
      prompt: 'A new song',
      durationSeconds,
    });
    assert.equal(result.ok, false);
    assert.match(result.message, /finite number/i);
  }
});

test('clamps finite durations to supported bounds and truncates fractions', () => {
  const cases = [
    {input: -5, expected: LIMITS.minDurationSeconds},
    {input: 0, expected: LIMITS.minDurationSeconds},
    {input: 10.9, expected: 10},
    {input: 299.9, expected: 299},
    {input: 900, expected: LIMITS.maxDurationSeconds},
  ];
  for (const item of cases) {
    const result = normalizeAurenMusicProductionRequest({
      prompt: 'A new song',
      durationSeconds: item.input,
    });
    assert.equal(result.ok, true);
    assert.equal(result.value.durationSeconds, item.expected);
  }
});

test('bounds every user-controlled text field', () => {
  const result = normalizeAurenMusicProductionRequest({
    title: 't'.repeat(200),
    prompt: 'p'.repeat(3500),
    genre: 'g'.repeat(100),
    mood: 'm'.repeat(100),
    language: 'l'.repeat(100),
  });
  assert.equal(result.ok, true);
  assert.equal(result.value.title.length, LIMITS.title);
  assert.equal(result.value.prompt.length, LIMITS.prompt);
  assert.equal(result.value.genre.length, LIMITS.genre);
  assert.equal(result.value.mood.length, LIMITS.mood);
  assert.equal(result.value.language.length, LIMITS.language);
});
