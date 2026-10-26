'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { getFirestore, doc, getDoc, setDoc, updateDoc, deleteDoc, runTransaction, Timestamp } = require('firebase/firestore');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-emulator';
let testEnv;

/** Use the modular Firestore SDK with the app supplied by a rules test context. */
function firestoreFor(context) {
  const db = getFirestore(context.getApp());
  const wrapRef = (path) => {
    const ref = doc(db, path);
    return {
      _ref: ref,
      get: () => getDoc(ref),
      set: (data) => setDoc(ref, data),
      update: (data) => updateDoc(ref, data),
      delete: () => deleteDoc(ref),
    };
  };
  return {
    doc: wrapRef,
    runTransaction: (updateFunction) => runTransaction(db, (transaction) =>
      updateFunction({
        get: (ref) => transaction.get(ref._ref),
        update: (ref, data) => transaction.update(ref._ref, data),
      }),
    ),
  };
}


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
    const db = firestoreFor(context);
    await db.doc('courses/course-3').set({
      title: 'Test Course',
      description: 'Education rules integration fixture',
      category: 'general',
      teacherId: 'teacher-1',
      skills: ['testing'],
      lessonCount: 3,
      status: 'published',
      createdAt: Timestamp.now(),
    });
  });
});

test.after(async () => {
  if (testEnv) await testEnv.cleanup();
});

test('canonical enrollment accepts rounded 1/3 progress', async () => {
  const db = firestoreFor(testEnv.authenticatedContext('education-user'));
  const enrollment = db.doc('users/education-user/enrollments/course-3');
  const now = Timestamp.now();

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
    updatedAt: Timestamp.now(),
  }));
});

test('canonical enrollment rejects false completion and false 100%', async () => {
  const db = firestoreFor(testEnv.authenticatedContext('education-user-2'));
  const enrollment = db.doc('users/education-user-2/enrollments/course-3');
  const now = Timestamp.now();

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
    updatedAt: Timestamp.now(),
  }));

  await assertFails(enrollment.update({
    completedLessons: 3,
    progress: 99,
    status: 'completed',
    updatedAt: Timestamp.now(),
  }));

  await assertSucceeds(enrollment.update({
    completedLessons: 3,
    progress: 100,
    status: 'completed',
    updatedAt: Timestamp.now(),
  }));
});
