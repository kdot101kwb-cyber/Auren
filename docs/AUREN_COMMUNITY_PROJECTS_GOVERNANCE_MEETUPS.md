# AUREN Community & Collaboration — Projects, Governance, Meetups

## Scope and reuse
- Reuses the existing `communities`, `community_clubs`, `collaboration_spaces`, community post/poll, report, casework, and appeal foundations. This does not replace Messenger, Timeline, Challenges, or the Events & Experiences discovery flow.
- Extends Collaboration Spaces with a local metadata sidecar for topic and community guidelines; the existing Firestore membership list and owner-invitation flow remain the source of membership.
- Adds Group Projects with locally persisted tasks, assignees, milestones, and progress.
- Adds Community Governance proposal drafts and local voting/decision workflow.
- Adds Events & Meetups draft creation and locally recorded interest/attendance status.

## Offline and safety behavior
- Project data, governance proposal drafts/votes, meetup drafts/attendance, and space topic/rules metadata are persisted using SharedPreferences and survive app restarts on the same device.
- Signed-in accounts use account-scoped local keys; anonymous drafts use a separate anonymous scope. Old unscoped records are not automatically imported into an account scope, avoiding accidental disclosure on shared devices.
- These local records are **not synced across users/devices** in this MVP. Local vote counts are not official community-wide results; they must not be represented as authoritative governance.
- Meetup records stay in `draft` status. No public event is published, no seat is reserved, no invitation is sent, and no payment or booking is triggered.
- Capacity is informational only; the store does not treat attendance as a confirmed reservation.
- Stored records are bounded to 100 projects/proposals/meetups and 100 space-guideline entries; each project is bounded to 100 tasks and 50 milestones. Local proposal votes and meetup attendance records are each capped at 1,000 entries per record. Reaching a limit rejects the new record instead of silently evicting older user data; an existing space guideline can still be updated at the limit.
- Users can explicitly delete local project, proposal, and meetup drafts from the UI; deletion affects only the current device and is confirmed before execution.
- Malformed JSON and structurally invalid local records are ignored rather than allowed to crash the UI; the next successful save rewrites the affected cache using validated records.
- Cache validation also enforces per-field character limits, bounded vote/attendance identity keys, and parseable project/proposal/meetup timestamps; malformed records are ignored before reaching widgets.

## Verification
- Focused test file: `test/services/social/community_workbench_store_test.dart`.
- Tests cover local persistence, space guideline metadata, task/milestone progress, input bounds, one local vote per voter (including concurrent duplicate attempts), proposal closure, draft-only meetup attendance, concurrent attendance updates, account-scoped isolation, bounded attendance, cache recovery, and deletion of local drafts.
- Run `dart format lib test`, `flutter analyze`, `flutter test test/services/social/community_workbench_store_test.dart`, full `flutter test`, Android debug build, and the existing Firestore emulator suites before release.
- Do not call cross-device governance or published events complete until an authenticated sync contract, Firestore rules/tests, and conflict handling are implemented.
