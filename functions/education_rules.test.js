const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

const rules = fs.readFileSync(require.resolve('../firestore.rules'), 'utf8');

const compact = (value) => value.replace(/\s+/g, '');

test('education canonical rules are present and client course writes are locked', () => {
  const normalized = compact(rules);
  assert.ok(normalized.includes('match/courses/{courseId}'), 'canonical courses match must exist');
  assert.ok(
    /allowcreate,?update,?delete:iffalse;/.test(normalized),
    'client writes to canonical courses must remain denied',
  );
  assert.ok(
    /resource\.data\.status==['"]published['"]/.test(normalized),
    'course reads must require published status',
  );
});

test('education enrollment rules require published canonical courses', () => {
  const normalized = compact(rules);
  assert.ok(
    normalized.includes('match/users/{userId}/enrollments/{courseId}'),
    'canonical enrollment match must exist',
  );
  assert.ok(
    normalized.includes('get(/databases/$(database)/documents/courses/$(courseId)).data.status==\'published\''),
    'enrollment must reference the canonical published course',
  );
  assert.ok(
    /(?:request\.resource\.data|requestData\(\))\.completedLessons<=get\(/.test(normalized),
    'completed lessons must not exceed the canonical course lesson count',
  );
});

test('education enrollment completion is derived from completed lessons', () => {
  const normalized = compact(rules);
  assert.ok(
    /requestData\(\)\.status==\(requestData\(\)\.completedLessons==get\([\s\S]*?lessonCount\?'completed':'active'\)/.test(normalized),
    'status must be derived from completed lessons and canonical lesson count',
  );
  assert.ok(
    /requestData\(\)\.status=='active'/.test(normalized),
    'active enrollment state must be explicitly supported',
  );
  assert.ok(
    /requestData\(\)\.status=='completed'&&requestData\(\)\.progress==100/.test(normalized),
    'completed enrollment must require 100 percent progress',
  );
  assert.ok(
    /requestData\(\)\.status=='active'&&requestData\(\)\.progress<100/.test(normalized),
    'active enrollment must remain below 100 percent progress',
  );
  assert.ok(
    /requestData\(\)\.completedLessons>=resource\.data\.completedLessons/.test(normalized),
    'completed lesson count must not decrease on update',
  );
  assert.ok(
    /requestData\(\)\.progress>=resource\.data\.progress/.test(normalized),
    'progress must not decrease on update',
  );
});

test('saved courses require published canonical courses', () => {
  const normalized = compact(rules);
  assert.ok(
    normalized.includes('match/users/{userId}/savedCourses/{courseId}'),
    'saved course match must exist',
  );
  assert.ok(
    /allowcreate:ifisOwner\(userId\)[\s\S]*?status=='published'/.test(normalized),
    'saving a course must require the canonical course to be published',
  );
  assert.ok(
    /allowupdate:iffalse;/.test(
      normalized.slice(
        normalized.indexOf('match/users/{userId}/savedCourses/{courseId}'),
        normalized.indexOf('match/users/{userId}/learningPlans/{planId}'),
      ),
    ),
    'saved course records must not be client-updatable',
  );
});

test('legacy education rules remain explicitly separate from canonical schema', () => {
  const normalized = compact(rules);
  assert.ok(normalized.includes('education_courses'), 'legacy education courses rules must remain');
  assert.ok(normalized.includes('education_enrollments'), 'legacy enrollment rules must remain');
  assert.ok(normalized.includes('match/courses/{courseId}'), 'canonical courses rules must remain separate');
});
