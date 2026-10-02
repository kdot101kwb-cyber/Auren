# Education Batch 3 — migration guard

The repository search index did not return reliable call-site matches for the legacy `AurenEducationService`. Because destructive migration could break hidden/unindexed consumers, the legacy service was not deleted.

Instead:
- `AurenEducationService` is explicitly marked `@Deprecated`.
- `EducationRepository` remains the canonical path used by the Education screen.
- Legacy `education_courses` / `education_enrollments` Firestore rules remain temporarily.
- Canonical `courses` / `enrollments` / `savedCourses` rules are now protected.

## Next verification gate

Run Flutter analyzer and Firebase Emulator tests against the canonical rules before removing legacy paths. The current environment did not execute those tests, so no test pass is claimed.
