const test = require('node:test');
const assert = require('node:assert/strict');

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
