'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const firebase = require('firebase/compat/app');
require('firebase/compat/firestore');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-emulator';
let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf8'),
    },
  });

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await db.doc('courses/course-3').set({
      title: 'Test Course',
      description: 'Education rules integration fixture',
      category: 'general',
      teacherId: 'teacher-1',
      skills: ['testing'],
      lessonCount: 3,
      status: 'published',
      createdAt: firebase.firestore.Timestamp.now(),
    });
    await db.doc('courses/course-draft').set({
      title: 'Draft Course',
      description: 'Unpublished education rules fixture',
      category: 'general',
      teacherId: 'teacher-1',
      skills: ['testing'],
      lessonCount: 1,
      status: 'draft',
      createdAt: firebase.firestore.Timestamp.now(),
    });
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test('course reads require authentication and published status', async () => {
  const signedIn = testEnv.authenticatedContext('course-reader').firestore();
  const signedOut = testEnv.unauthenticatedContext().firestore();

  await assertSucceeds(signedIn.doc('courses/course-3').get());
  await assertFails(signedOut.doc('courses/course-3').get());
  await assertFails(signedIn.doc('courses/course-draft').get());
});

test('saved courses accept only existing published canonical courses', async () => {
  const db = testEnv.authenticatedContext('course-saver').firestore();
  const savedAt = firebase.firestore.Timestamp.now();

  await assertSucceeds(db.doc('users/course-saver/savedCourses/course-3').set({
    courseId: 'course-3',
    createdAt: savedAt,
  }));

  await assertFails(db.doc('users/course-saver/savedCourses/course-draft').set({
    courseId: 'course-draft',
    createdAt: firebase.firestore.Timestamp.now(),
  }));

  await assertFails(db.doc('users/course-saver/savedCourses/missing-course').set({
    courseId: 'missing-course',
    createdAt: firebase.firestore.Timestamp.now(),
  }));
});

test('canonical enrollment accepts rounded 1/3 progress', async () => {
  const db = testEnv.authenticatedContext('education-user').firestore();
  const enrollment = db.doc('users/education-user/enrollments/course-3');
  const now = firebase.firestore.Timestamp.now();

  await assertSucceeds(enrollment.set({
    courseId: 'course-3',
    completedLessons: 0,
    progress: 0,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  }));

  await assertSucceeds(enrollment.update({
    completedLessons: 1,
    progress: 33,
    status: 'active',
    updatedAt: firebase.firestore.Timestamp.now(),
  }));
});

test('canonical enrollment rejects false completion and false 100%', async () => {
  const db = testEnv.authenticatedContext('education-user-2').firestore();
  const enrollment = db.doc('users/education-user-2/enrollments/course-3');
  const now = firebase.firestore.Timestamp.now();

  await assertSucceeds(enrollment.set({
    courseId: 'course-3',
    completedLessons: 0,
    progress: 0,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  }));

  await assertFails(enrollment.update({
    completedLessons: 0,
    progress: 100,
    status: 'completed',
    updatedAt: firebase.firestore.Timestamp.now(),
  }));

  await assertFails(enrollment.update({
    completedLessons: 3,
    progress: 99,
    status: 'completed',
    updatedAt: firebase.firestore.Timestamp.now(),
  }));

  await assertSucceeds(enrollment.update({
    completedLessons: 3,
    progress: 100,
    status: 'completed',
    updatedAt: firebase.firestore.Timestamp.now(),
  }));
});
