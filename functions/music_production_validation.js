'use strict';

const LIMITS = Object.freeze({
  title: 160,
  prompt: 3000,
  genre: 80,
  mood: 80,
  language: 40,
  minDurationSeconds: 10,
  maxDurationSeconds: 300,
  defaultDurationSeconds: 30,
});

function boundedString(value, fallback, maxLength) {
  return String(value ?? fallback).trim().slice(0, maxLength);
}

function normalizeAurenMusicProductionRequest(data) {
  const source = data && typeof data === 'object' && !Array.isArray(data) ? data : {};
  const prompt = boundedString(source.prompt, '', LIMITS.prompt);
  if (!prompt) {
    return {ok: false, message: 'Music prompt is required.'};
  }

  const rawDuration = source.durationSeconds;
  let duration = LIMITS.defaultDurationSeconds;
  if (rawDuration !== undefined && rawDuration !== null && rawDuration !== '') {
    duration = Number(rawDuration);
    if (!Number.isFinite(duration)) {
      return {ok: false, message: 'Music duration must be a finite number of seconds.'};
    }
  }

  duration = Math.max(
    LIMITS.minDurationSeconds,
    Math.min(LIMITS.maxDurationSeconds, Math.trunc(duration)),
  );

  return {
    ok: true,
    value: {
      title: boundedString(source.title, 'AUREN Original Track', LIMITS.title) || 'AUREN Original Track',
      prompt,
      genre: boundedString(source.genre, '', LIMITS.genre),
      mood: boundedString(source.mood, '', LIMITS.mood),
      language: boundedString(source.language, '', LIMITS.language),
      durationSeconds: duration,
    },
  };
}

module.exports = {LIMITS, normalizeAurenMusicProductionRequest};
