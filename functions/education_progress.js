const admin = require('firebase-admin');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {applyEducationActivitiesInTransaction, cleanString} = require('./education_gamification_core');

const db = admin.firestore();

exports.completeAurenEducationLesson = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');

    const courseId = cleanString(request.data?.courseId, 128);
    const requestedCompleted = Number(request.data?.completed);
    if (!courseId || !Number.isInteger(requestedCompleted)) {
      throw new HttpsError('invalid-argument', 'courseId and an integer completed value are required.');
    }

    const courseSnap = await db.collection('courses').doc(courseId).get();
    if (!courseSnap.exists) throw new HttpsError('not-found', 'Course not found.');
    const course = courseSnap.data() || {};
    const lessonCount = Number(course.lessonCount || 0);
    if (!Number.isInteger(lessonCount) || lessonCount < 0) {
      throw new HttpsError('failed-precondition', 'Course lessonCount is invalid.');
    }
    if (requestedCompleted < 0 || requestedCompleted > lessonCount) {
      throw new HttpsError('invalid-argument', 'Completed lessons are out of range.');
    }

    const ref = db.collection('users').doc(uid).collection('enrollments').doc(courseId);
    return db.runTransaction(async (tx) => {
      const enrollmentSnap = await tx.get(ref);
      if (!enrollmentSnap.exists) {
        throw new HttpsError('failed-precondition', 'Enroll in the course first.');
      }

      const current = enrollmentSnap.data() || {};
      const previous = Number(current.completedLessons || 0);
      if (!Number.isInteger(previous) || previous < 0 || previous > lessonCount) {
        throw new HttpsError('failed-precondition', 'Enrollment progress is invalid.');
      }
      if (requestedCompleted < previous) {
        throw new HttpsError('invalid-argument', 'Lesson progress cannot move backwards.');
      }

      const progress = lessonCount === 0 ? 100 : Math.round((requestedCompleted / lessonCount) * 100);
      const status = progress >= 100 ? 'completed' : 'active';
      const activities = [];

      for (let lesson = previous + 1; lesson <= requestedCompleted; lesson++) {
        activities.push({
          type: 'lesson',
          eventId: `lesson:${courseId}:${lesson}`,
          sourceId: courseId,
        });
      }
      if (previous < lessonCount && progress >= 100) {
        activities.push({
          type: 'course',
          eventId: `course:${courseId}:completed`,
          sourceId: courseId,
        });
      }

      const gamification = await applyEducationActivitiesInTransaction(tx, uid, activities);

      tx.set(ref, {
        courseId,
        completedLessons: requestedCompleted,
        progress,
        status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      return {
        courseId,
        previous,
        completedLessons: requestedCompleted,
        progress,
        status,
        gamification,
      };
    });
  },
);
