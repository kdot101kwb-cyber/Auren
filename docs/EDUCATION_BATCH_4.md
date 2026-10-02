# Education Batch 4 — Security + Canonical Progress Integrity

## Implemented
- Locked canonical `courses` publishing/writes from clients.
- Canonical enrollments now require a published course and a fixed enrollment schema.
- Enrollment updates verify course identity, published status, integer bounds, immutable creation time, and lesson-count upper bound.
- Saved courses now require the referenced canonical course to be published.
- `EducationRepository.completeLesson` now re-reads the canonical course instead of trusting UI-supplied lesson count/skills.
- Completion progress and professional skills are derived from canonical course data.

## Verification status
- GitHub source changes committed.
- Flutter/Firebase Emulator tests were not executed in this environment.
- The next gate is local/CI analyzer plus Firestore Emulator rules tests, then lesson/content and assessment implementation.
