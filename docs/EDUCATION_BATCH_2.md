# Education Batch 2 — Canonical data + Firestore security

## Implemented

AUREN Education's active UI/repository uses the canonical collections:
- `courses`
- `users/{uid}/enrollments`
- `users/{uid}/savedCourses`

The Firestore rules now explicitly protect these paths.

### Canonical courses
- Authenticated users can read only documents whose `status == published`.
- Clients cannot create, update, or delete course definitions.

### Enrollments
- Users can read only their own enrollments.
- Enrollment creation requires the referenced course to be published.
- Initial enrollment is constrained to zero progress and zero completed lessons.
- Updates are owner-only and constrain progress/status/immutable fields.
- Users can delete only their own enrollment.

### Saved courses
- Users can read/manage only their own saved-course documents.
- A saved course must reference a published canonical course.
- Client updates are disabled; delete is owner-only.

## Legacy compatibility

The existing `education_courses` and `education_enrollments` rules were intentionally retained. No destructive migration was performed because repository-wide usage of the legacy service could not be proven from the available code-search index.

## Remaining Education work

1. Migrate/remove the legacy `AurenEducationService` path only after repository-wide usage is verified.
2. Add emulator-backed Firestore tests for enrollment, progress, and saved-course rules.
3. Add widget tests for Education search/filter/save/progress states.
4. Add lesson/assessment content and AI Tutor execution coverage.
5. Validate offline/low-data behavior before describing it as production-ready.

## Verification note

This commit changes rules only. Flutter analyze/tests and Firebase Emulator rule tests have not been run from this environment, so this is not an Education closure claim.
