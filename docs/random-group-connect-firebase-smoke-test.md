# Random Group Connect — Firebase/App Check Smoke Test

Use this checklist only against a dedicated **staging** Firebase project. Do not run it against production users or real conversations.

## Preconditions

- [ ] Staging Firebase project ID and deployed build are confirmed.
- [ ] The current Random Group Connect branch is deployed to staging.
- [ ] Firestore rules and `firestore.indexes.json` are deployed; the composite index for `status + groupSize + language` is ready.
- [ ] Callable functions are deployed in `us-central1`: `listAurenRandomGroupCandidates`, `formAurenRandomGroup`, and `createAurenRandomGroupConversation`.
- [ ] App Check is enforced for all three callables and the staging Android app is registered with the intended App Check provider.
- [ ] Three or more dedicated test accounts are available. Record their UIDs privately in the test record; do not put tokens or credentials in logs, comments, or this file.

## Smoke test

1. **App Check and authentication**
   - Signed-out user attempts each callable: request must be rejected.
   - Staging app with valid auth and valid App Check token can create a waiting request and poll candidates.
   - App Check failure is surfaced as a retryable, localized UI error; polling must not permanently stop.

2. **Candidate discovery**
   - Create waiting requests for three test users with the same group size and language.
   - The owner sees eligible candidates, but never their own request.
   - A request in another language is not returned.
   - Duplicate waiting requests for one UID appear as one person, not multiple members.
   - A user blocked by either side is excluded.

3. **Atomic group formation**
   - Select exactly the required unique people; confirm one active group is created and every selected request changes from `waiting` to `grouped` with the same group ID.
   - Try mixed-language request IDs, duplicate request IDs, a stale/cancelled request, and an incorrect group size. Each must be rejected and must not partially claim requests.
   - Attempt to include two requests belonging to the same UID. The operation must be rejected.

4. **Messenger conversation**
   - A member creates/opens the group conversation; repeated calls return the existing conversation ID instead of creating duplicates.
   - A non-member cannot create or read the group conversation.
   - A blocked pair prevents conversation creation.
   - Confirm group messages are only available to members and sender identity cannot be forged.

5. **Rules and data hygiene**
   - Another account cannot read a user's private request or cancel/update it.
   - A client cannot create or edit a `random_groups` document directly.
   - Cancel a remaining waiting request through the UI.
   - After capturing results, remove test data through an authorized staging-only administrative process; clients are intentionally not allowed to delete request documents.

## Result record

Record date/time, staging project ID, app build/commit, Android device, App Check provider, pass/fail for each section, and sanitized error codes. Never include access tokens, debug tokens, service-account keys, personal data, or full authentication headers.

**Release gate:** all checks above must pass in staging before production rollout. CI/emulator success alone does not prove live Firebase/App Check behavior.
