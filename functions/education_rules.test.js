const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const rules = fs.readFileSync(require.resolve('../firestore.rules'), 'utf8');

test('education canonical rules are present and client course writes are locked', () => {
  assert.match(rules, /match \/courses\/{courseId}/);
  assert.match(rules, /allow create, update, delete: if false/);
  assert.match(rules, /request\.resource\.data\.status == 'published'/);
});

test('education enrollment rules require published canonical courses', () => {
  assert.match(rules, /match \/users\/{userId}\/enrollments\/{courseId}/);
  assert.match(rules, /get\(\/databases\/\$\(database\)\/documents\/courses\/\$\(courseId\)\)\.data\.status == 'published'/);
  assert.match(rules, /request\.resource\.data\.completedLessons <= get\(/);
});

test('education enrollment progress is derived from completed lessons', () => {
  assert.match(
    rules,
    /request\.resource\.data\.progress \* get\([\s\S]*?lessonCount[\s\S]*?== request\.resource\.data\.completedLessons \* 100/
  );
  assert.match(rules, /request\.resource\.data\.completedLessons == get\([\s\S]*?lessonCount[\s\S]*?\? 'completed'/);
});

test('saved courses require published canonical courses', () => {
  assert.match(rules, /match \/users\/{userId}\/savedCourses\/{courseId}/);
  assert.match(rules, /allow create: if isOwner\(userId\)[\s\S]*?status == 'published'/);
});

test('legacy education rules remain explicitly separate from canonical schema', () => {
  assert.match(rules, /education_courses/);
  assert.match(rules, /education_enrollments/);
  assert.match(rules, /match \/courses\/{courseId}/);
});
