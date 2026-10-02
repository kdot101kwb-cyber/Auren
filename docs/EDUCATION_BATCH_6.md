# Education Batch 6 — Rule-level Progress Integrity

## Implemented
- Firestore now enforces that enrollment progress is mathematically derived from completedLessons and the canonical course lessonCount.
- Firestore now derives the allowed enrollment status: active until all lessons are completed, then completed.
- This closes the client-side bypass where a direct Firestore write could previously claim 100% without completing the course.
- Repository progress calculation remains centralized in EducationRepository.progressFor.

## Verification
Source/rule changes were committed and inspected through GitHub.
Flutter and Firebase Emulator execution is still pending in the local/CI environment; no runtime pass is claimed.
