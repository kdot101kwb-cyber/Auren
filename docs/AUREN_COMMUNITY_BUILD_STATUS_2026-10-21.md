# AUREN Community Build — Status 2026-10-21

## Blueprint and deduplication
- The repository contains `docs/AUREN_47_SYSTEMS_10_BATCHES.md`; no file explicitly named Master Blueprint was found on the reviewed branch. The Library audit also says the canonical Blueprint/version remains unresolved.
- Reuse the existing Communities service/screens rather than rebuilding the parent system. Events/Groups are already represented in the broader registry, so no duplicate events engine is added.
- The missing child capability selected in place of a duplicate Communities build is **Community Memory & Outcomes**: milestones, decisions, and outcomes attached to an existing community.

## Changes on this branch
- `community_memory_feed_service.dart` reuses `PostRepository.createCommunityPost` and the existing `posts` rules, which require membership to create a community-scoped post.
- `community_memory_screen.dart` provides the entry form and feed view; the Communities list links members to it and to the existing community detail screen.
- Casework and appeal service/model prototypes were added, but they are **not end-to-end**: the required Firestore rule changes could not be applied in this run. Do not ship or rely on report review, appeal decisions, or case-event writes until rules and emulator tests are completed.
- `community_memory_service.dart` is an earlier subcollection prototype and is not wired to the screen; current rules do not authorize that new subcollection. Use the feed-backed service instead.

## Existing foundations retained
- Clubs & Circles: public club creation, join/leave, owner membership invariant, existing unit and emulator test coverage.
- Collaboration Spaces: owner-managed member invitations, existing unit and emulator test coverage.
- Volunteer & Causes: cause creation and volunteer opt-in, existing unit and emulator test coverage.
- Broad Communities: existing membership, posts, and polls reused.

## Verification and blockers
- No production data was changed, no deployment was run, and no PR was created or merged.
- A write to `firestore.rules` was blocked by the GitHub connector's safety checks, so report-review and appeal rules, their security tests, and the end-to-end governance UI remain outstanding.
- The current `community_memory_rules.integration.test.js` checks that valid report creation is allowed and malformed/forged reports are denied; it also asserts report reads/updates and case-event writes remain denied under the current rules. This is a security regression gate, **not** proof that moderation workflows are operational.

## Follow-up verification — 2026-10-21
- `functions/package.json`: removed execution of the emulator-dependent community memory integration test from ordinary `npm test`; retained its syntax check. The emulator suite still runs it via `test:emulator`.
- `.circleci/config.yml`: added `functions/community_memory_rules.integration.test.js` to the Firestore emulator gate alongside Action and Community Collaboration integration tests.
- Follow-up status refresh: all five CircleCI contexts reported `success` for the report commit `c702a6c8843d27e46b9a5b4dfeec134c0e8f70ed`: Functions tests, Action Executor tests, Plugin Worker tests, Plugin Worker image, and Flutter CI. The preceding configuration commit `50fe949721f8fc0170acd744010eb543b95e7188` also reports success for all five contexts.
- The successful `functions_tests` job includes the configured Firestore emulator gate. Raw emulator logs and individual test counts were not retrieved, so this confirms job-level CI success, not the exact number of integration tests. The outstanding Firestore authorization and end-to-end governance blockers above remain unchanged; passing CI does not mean casework/appeals are operational.


## Accelerated follow-up — three focused batches

### Batch 1 — appeal security regression coverage
- Extended `functions/community_memory_rules.integration.test.js` with checks that appeal creation, appellant reads, moderator queue reads, appeal decisions, and appeal-event writes remain denied until explicit Firestore authorization rules are implemented.
- Commit: `95c99bdfff8d65d6ae1d618a5916dedc0913b55e`.
- This adds regression coverage for the safe-deny state; it does not make appeals operational.

### Batch 2 — governance security contract
- Added `docs/COMMUNITY_GOVERNANCE_FIRESTORE_CONTRACT.md` specifying trusted moderator identity, immutable reporter/appellant fields, permitted state transitions, append-only audit events, required emulator cases, and release gates.
- Commit: `93a6e6c185ed15a23f450865b129fbeb855f128c`.
- This is a design contract only; Firestore rules were not changed.

### Batch 3 — CI/status verification and release boundary
- The preceding report commit `78c7f8ebab4540f0b557f9758e883a9bbb734645` showed Functions, Action Executor, Plugin Worker tests, and Plugin Worker image as successful; Flutter CI was pending at the time of refresh.
- The new test and contract commits have not yet been verified green by CI. Check their CircleCI status before claiming the accelerated batch is fully validated.
- No production rules/deployment, PR creation, or merge was performed. Governance remains blocked on implementing and emulator-verifying the strict rules described in the contract.

## Verification refresh — 2026-10-23

This section supersedes earlier statements about the then-blocked rules validation where they conflict with current CI evidence; it does not claim that all moderation or appeal product flows are fully integrated.

- Current code branch: `feat/community-projects-governance-meetups-v1`; current documentation-only follow-up is on top of the code snapshot validated at `bb1164fc886f1a8b413130d1e963401668852de3`.
- Firestore Rules Validation succeeded after changing the validation dependency install to use `npm install --no-audit --no-fund --legacy-peer-deps`. The isolated Firestore emulator ran the configured Action, Supplier, Education, Community Collaboration, and Community Memory rules suites successfully.
- AUREN Backend CI passed on the same code snapshot. Flutter format, analyze, and tests passed; the Android debug APK build was still in progress at the last status check.
- The staging deploy job was skipped for the pull-request event. No production deployment was run, and this update does not authorize deployment.
- The local Community Workbench cache now rejects malformed project/proposal/meetup records with oversized fields, invalid timestamps, or unbounded voter/attendee IDs. Account-scoped local storage and concurrent mutation tests remain part of the focused Flutter suite.
- Community Projects, Governance, and Meetups remain local-first drafts. Emulator success validates the configured existing rules suites; it does not imply that the new local drafts are synchronized across devices or that local votes are official community-wide results.
- PR #272 remains open as a draft and has not been merged.
