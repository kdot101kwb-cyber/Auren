const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const rules = fs.readFileSync(require.resolve('../firestore.rules'), 'utf8');

test('education canonical rules are present and client course writes are locked', () => {
  assert.match(rules, /match\s*\/courses\/{courseId}/);
  assert.match(rules, /allow create, update, delete:\s*if false/);
  assert.match(rules, /resource\.data\.status\s*==\s*'published'/);
});

test('education enrollment rules require published canonical courses', () => {
  assert.match(rules, /match\s*\/users\/{userId}\/enrollments\/{courseId}/);
  assert.match(rules, /get\(\/databases\/\$\(database\)\/documents\/courses\/\$\(courseId\)\)\.data\.status\s*==\s*'published'/);
  assert.match(rules, /(?:request\.resource\.data|requestData\(\))\.completedLessons\s*<=\s*get\(/);
});

test('education enrollment completion is derived from completed lessons', () => {
  assert.match(rules, /(?:request\.resource\.data|requestData\(\))\.completedLessons\s*==\s*get\([\s\S]*?lessonCount/);
  assert.match(rules, /status\s*==\s*\(\s*(?:request\.resource\.data|requestData\(\))\.completedLessons\s*==\s*get\([\s\S]*?lessonCount[\s\S]*?\?\s*'completed'\s*:\s*'active'\s*\)/);
  assert.match(rules, /(?:request\.resource\.data|requestData\(\))\.status\s*==\s*'active'/);
  assert.match(rules, /(?:request\.resource\.data|requestData\(\))\.progress\s*<\s*100/);
  assert.match(rules, /(?:request\.resource\.data|requestData\(\))\.progress\s*==\s*100/);
});

test('saved courses require published canonical courses', () => {
  assert.match(rules, /match\s*\/users\/{userId}\/savedCourses\/{courseId}/);
  assert.match(rules, /allow create:\s*if isOwner\(userId\)[\s\S]*?status\s*==\s*'published'/);
});

test('legacy education rules remain explicitly separate from canonical schema', () => {
  assert.match(rules, /education_courses/);
  assert.match(rules, /education_enrollments/);
  assert.match(rules, /match\s*\/courses\/{courseId}/);
});
