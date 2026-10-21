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

function boundedString(value, fallback, field, maxLength) {
  if (value === undefined || value === null) value = fallback;
  if (typeof value !== 'string') {
    return {ok: false, message: `Music ${field} must be a string.`};
  }
  return {ok: true, value: value.trim().slice(0, maxLength)};
}

function normalizeAurenMusicProductionRequest(data) {
  const source = data && typeof data === 'object' && !Array.isArray(data) ? data : {};
  const promptResult = boundedString(source.prompt, '', 'prompt', LIMITS.prompt);
  if (!promptResult.ok) return promptResult;
  const prompt = promptResult.value;
  if (!prompt) {
    return {ok: false, message: 'Music prompt is required.'};
  }

  const titleResult = boundedString(source.title, 'AUREN Original Track', 'title', LIMITS.title);
  const genreResult = boundedString(source.genre, '', 'genre', LIMITS.genre);
  const moodResult = boundedString(source.mood, '', 'mood', LIMITS.mood);
  const languageResult = boundedString(source.language, '', 'language', LIMITS.language);
  for (const result of [titleResult, genreResult, moodResult, languageResult]) {
    if (!result.ok) return result;
  }

  const rawDuration = source.durationSeconds;
  let duration = LIMITS.defaultDurationSeconds;
  if (rawDuration !== undefined && rawDuration !== null) {
    if (typeof rawDuration !== 'number' || !Number.isFinite(rawDuration)) {
      return {ok: false, message: 'Music duration must be a finite number of seconds.'};
    }
    duration = rawDuration;
  }

  duration = Math.max(
    LIMITS.minDurationSeconds,
    Math.min(LIMITS.maxDurationSeconds, Math.trunc(duration)),
  );

  return {
    ok: true,
    value: {
      title: titleResult.value || 'AUREN Original Track',
      prompt,
      genre: genreResult.value,
      mood: moodResult.value,
      language: languageResult.value,
      durationSeconds: duration,
    },
  };
}

module.exports = {LIMITS, normalizeAurenMusicProductionRequest};
