'use strict';

// One-time backfill for legacy profile modes.
// Dry-run by default. Pass --apply only after reviewing the reported counts.
const { initializeApp, getApp, getApps, applicationDefault } = require('firebase-admin/app');
const { getFirestore, FieldPath, FieldValue } = require('firebase-admin/firestore');

const APPLY = process.argv.includes('--apply');
const projectFlag = process.argv.indexOf('--project');
const PROJECT_ID = projectFlag >= 0 ? process.argv[projectFlag + 1] : null;
const PAGE_SIZE = 200;
const VALID_MODES = new Set(['personal', 'creator', 'professional', 'business']);

function boundedText(value, max) {
  if (typeof value !== 'string') return '';
  return value.trim().slice(0, max);
}

function boundedList(value, maxItems, maxLength) {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item) => typeof item === 'string')
    .map((item) => boundedText(item, maxLength))
    .filter(Boolean)
    .slice(0, maxItems);
}

function publicProjection(data, modeId) {
  return {
    mode: modeId,
    headline: boundedText(data.headline, 120),
    bio: boundedText(data.bio, 800),
    skills: boundedList(data.skills, 20, 60),
    interests: boundedList(data.interests, 20, 60),
    goals: boundedList(data.goals, 10, 120),
    languages: boundedList(data.languages, 10, 40),
    services: boundedList(data.services, 15, 80),
    achievements: boundedList(data.achievements, 10, 160),
    discoverable: true,
    showContact: data.showContact === true,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

async function main() {
  if (!PROJECT_ID || PROJECT_ID.startsWith('--')) {
    throw new Error('Pass an explicit Firebase project with --project <project-id>; no project will be inferred.');
  }
  if (!/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(PROJECT_ID)) {
    throw new Error('Invalid Firebase project ID format.');
  }
  const hasDefaultApp = getApps().some((app) => app.name === '[DEFAULT]');
  if (!hasDefaultApp) {
    initializeApp({ credential: applicationDefault(), projectId: PROJECT_ID });
  }
  // Validate the exact default app used by getFirestore(), not an arbitrary
  // named app that may have been initialized earlier in a shared process.
  const app = getApp();
  const actualProjectId = app.options.projectId;
  if (actualProjectId !== PROJECT_ID) {
    throw new Error(`Firebase project mismatch: requested ${PROJECT_ID}, initialized ${actualProjectId || 'unknown'}.`);
  }
  const db = getFirestore(app);
  const counts = { scanned: 0, wouldPublish: 0, wouldRemove: 0, skippedInvalidPath: 0, changed: 0 };
  let cursor = null;

  for (;;) {
    let query = db.collectionGroup('profile_modes')
      .orderBy(FieldPath.documentId())
      .limit(PAGE_SIZE);
    if (cursor) query = query.startAfter(cursor);
    const page = await query.get();
    if (page.empty) break;
    cursor = page.docs[page.docs.length - 1];
    counts.scanned += page.size;

    let batch = db.batch();
    let writes = 0;
    for (const doc of page.docs) {
      const parts = doc.ref.path.split('/');
      if (parts.length !== 4 || parts[0] !== 'users' || parts[2] !== 'profile_modes') {
        counts.skippedInvalidPath += 1;
        continue;
      }
      const uid = parts[1];
      const modeId = parts[3];
      if (!VALID_MODES.has(modeId)) {
        counts.skippedInvalidPath += 1;
        continue;
      }

      const publicRef = db.collection('users').doc(uid)
        .collection('public_profile_modes').doc(modeId);
      const data = doc.data() || {};
      const visible = data.discoverable === true;
      const settingsRef = db.collection('users').doc(uid)
        .collection('profile_settings').doc('current');
      const settings = await settingsRef.get();
      const isActive = settings.data()?.activeMode === modeId;

      if (visible) {
        counts.wouldPublish += 1;
        if (APPLY) {
          batch.set(publicRef, publicProjection(data, modeId));
          writes += 1;
        }
      } else {
        counts.wouldRemove += 1;
        if (APPLY) {
          batch.delete(publicRef);
          writes += 1;
        }
      }

      if (APPLY && isActive) {
        batch.set(db.collection('users').doc(uid)
          .collection('public_profile_settings').doc('current'), {
          activeMode: modeId,
          discoverable: visible,
          updatedAt: FieldValue.serverTimestamp(),
        });
        writes += 1;
      }

      // Keep every commit below Firestore's 500-write batch limit.
      if (writes >= 400) {
        await batch.commit();
        counts.changed += writes;
        writes = 0;
        batch = db.batch();
      }
    }
    if (APPLY && writes > 0) {
      await batch.commit();
      counts.changed += writes;
    }
    if (page.size < PAGE_SIZE) break;
  }

  process.stdout.write(JSON.stringify({
    projectId: PROJECT_ID,
    mode: APPLY ? 'apply' : 'dry-run',
    note: APPLY ? 'Public projections updated; review counts and application logs.' :
      'No writes performed. Re-run with --apply to perform the backfill.',
    ...counts,
  }, null, 2) + '\n');
}

main().catch((error) => {
  process.stderr.write('Profile projection backfill failed: ' + error.message + '\n');
  process.exitCode = 1;
});
