# Education Batch 7 — Enrollment Integrity

## Implemented
- Enrollment is now idempotent and cannot reset an existing learner's progress.
- Enrollment creation verifies the canonical course exists and is published inside the same Firestore transaction.
- Existing enrollment documents are left untouched on repeated enrollment calls.
- This closes the previous merge-write path that could overwrite completedLessons/progress/status back to zero/active.

## Verification
The repository change was committed through GitHub. Flutter/Firebase Emulator execution remains pending; no runtime pass is claimed.
