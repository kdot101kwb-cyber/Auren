'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
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
      rules: path.resolve(__dirname, '../firestore.rules'),
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
  });
});

test.after(async () => {
  await testEnv.cleanup();
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

  await assertSucceeds(setDoc(enrollment, {
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

  await assertFails(updateDoc(enrollment, {
    completedLessons: 3,
    progress: 99,
    status: 'completed',
    updatedAt: firebase.firestore.Timestamp.now(),
  }));

  await assertSucceeds(updateDoc(enrollment, {
    completedLessons: 3,
    progress: 100,
    status: 'completed',
    updatedAt: firebase.firestore.Timestamp.now(),
  }));
});
