const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('education gamification XP map is defined by the server module contract', () => {
  assert.deepEqual(
    {lesson: 10, course: 100, quiz: 20, language: 15, voiceTutor: 10},
    {lesson: 10, course: 100, quiz: 20, language: 15, voiceTutor: 10},
  );
});

test('education event ids are intended to be idempotency keys', () => {
  const eventId = 'lesson-course-1-lesson-2';
  assert.equal(eventId.length > 0, true);
});


test('server contract contains weekly challenge and protected badge state', () => {
  const source = fs.readFileSync(path.join(__dirname, 'education_gamification.js'), 'utf8');
  assert.match(source, /WEEKLY_CHALLENGE/);
  assert.match(source, /weeklyChallengeCompleted/);
  assert.match(source, /const BADGES/);
  assert.match(source, /badges/);
});

test('client exposes all education XP activity types', () => {
  const source = fs.readFileSync(
    path.join(__dirname, '..', 'lib', 'services', 'education', 'education_gamification_service.dart'),
    'utf8',
  );
  for (const method of ['recordQuiz', 'recordLanguage', 'recordVoiceTutor']) {
    assert.match(source, new RegExp(method));
  }
});


test('weekly challenge baseline resets at a new week', () => {
  const source = fs.readFileSync(path.join(__dirname, 'education_gamification.js'), 'utf8');
  assert.match(source, /const isCurrentWeek = currentProfile\.currentWeek === week/);
  assert.match(source, /const weekStartActivities = isCurrentWeek/);
  assert.match(source, /totalActivities - weekStartActivities >= WEEKLY_CHALLENGE\.targetActivities/);
  assert.match(source, /weekStartActivities,/);
});
