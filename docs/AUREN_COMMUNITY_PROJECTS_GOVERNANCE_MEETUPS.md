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
- When authentication changes while the workbench is open, transient space-guideline form fields are cleared as well as switching the storage scope, preventing unsaved text from one account remaining visible to the next account on a shared device.
- Space-guideline reads are bound to the initiating store and authenticated UID; if sign-out/account-switch happens before a read finishes, its stale result and error are discarded rather than filling the next account's form or showing cross-account feedback.
- Draft dialogs and date/time pickers also capture an account-generation token. If authentication changes while a form is open, the unfinished draft is discarded instead of being written into the next account's local store; delayed operation feedback is suppressed after the account changes.
- Destructive confirmation dialogs capture the originating account/store and discard confirmation if the account changes before the user confirms, preventing a stale delete dialog from deleting a record in the next account's local scope.
- Collaboration Space create/edit/invite dialogs also capture the account generation; stale guideline reads/saves are discarded and invite/create feedback is suppressed after an account switch. The local guideline sidecar is written only through the store instance that initiated the action.
- These local records are **not synced across users/devices** in this MVP. Local vote counts are not official community-wide results; they must not be represented as authoritative governance.
- Meetup records stay in `draft` status. No public event is published, no seat is reserved, no invitation is sent, and no payment or booking is triggered.
- Capacity is informational only; the store does not treat attendance as a confirmed reservation.
- Stored records are bounded to 100 projects/proposals/meetups and 100 space-guideline entries; each project is bounded to 100 tasks and 50 milestones. Local proposal votes and meetup attendance records are each capped at 1,000 entries per record. Reaching a limit rejects the new record instead of silently evicting older user data; an existing space guideline can still be updated at the limit.
- Users can explicitly delete local project, proposal, and meetup drafts from the UI; deletion affects only the current device and is confirmed before execution.
- Malformed JSON and structurally invalid local records are ignored rather than allowed to crash the UI; the next successful save rewrites the affected cache using validated records.
- Cache validation also enforces per-field character limits, bounded vote/attendance identity keys, and parseable project/proposal/meetup timestamps; malformed records are ignored before reaching widgets.
- List caches are capped at 100 valid records on read as well as write; duplicate record IDs in a malformed or legacy cache are ignored to prevent unbounded list rendering and ambiguous local edits.

## Verification
- Focused test file: `test/services/social/community_workbench_store_test.dart`.
- Collaboration service regressions cover title/description bounds, trimming, invalid invite identities (blank, self, and over 128 characters), idempotent invites, owner-only authorization, the 100-member cap, and report-target normalization/self-report rejection (including whitespace bypass and oversized UIDs) in `test/services/social/community_collaboration_service_test.dart`.
- Tests cover local persistence, space guideline metadata, task/milestone progress, input bounds, one local vote per voter (including concurrent duplicate attempts), proposal closure, draft-only meetup attendance, concurrent attendance updates, account-scoped isolation, bounded attendance, cache recovery, and deletion of local drafts. Additional regressions assert that closed proposals reject later votes, voter IDs are trimmed consistently, and blank/oversized voter identities cannot mutate a proposal. A concurrent vote-versus-closure regression also checks that serialized local mutations never leave an invalid lifecycle state.
- Run `dart format lib test`, `flutter analyze`, `flutter test test/services/social/community_workbench_store_test.dart`, full `flutter test`, Android debug build, and the existing Firestore emulator suites before release.
- Do not call cross-device governance or published events complete until an authenticated sync contract, Firestore rules/tests, and conflict handling are implemented.
- Firestore community poll rules require member access, an initially zeroed counter map, bounded non-empty string options (maximum 100 characters each), and exactly one vote-counter increment matching the newly added voter entry; rule integration regressions cover forged totals, invalid/oversized options, multi-counter changes, metadata tampering, duplicate voting, and non-member reads.


## Follow-up batch — task assignment workflow
- Added a local task-assignee update operation, including trimming, a strict 128-character bound, and safe failure when the project/task does not exist.
- Exposed task reassignment in the Community Workbench UI, including clearing an assignee; status remains unchanged when assignment changes.
- Added focused regressions for reassignment, clearing, invalid oversized identities, and missing tasks.
- This remains device-local project planning. It does not notify members or assign tasks in a shared server workspace until trusted sync and authorization are implemented.
- Validation gate for this follow-up: Flutter format, analysis, focused store tests, full Flutter tests, Android debug APK, backend and security CI.

## Follow-up batch — cache identity integrity
- Hardened cache validation so voter and attendee identity keys must already be trimmed and normalized. A malformed cached identity such as `" member-a "` can no longer bypass the one-local-vote rule or create a duplicate attendance identity.
- Added focused regression tests for malformed cached vote/attendance IDs and confirmed that normal API inputs are trimmed before saving.
- This is local-cache integrity only; it does not turn local votes or attendance into shared server state.
