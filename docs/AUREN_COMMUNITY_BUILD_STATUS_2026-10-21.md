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
- Latest checked CircleCI status for commit `50fe949721f8fc0170acd744010eb543b95e7188`: Functions tests, Action Executor tests, Plugin Worker tests, and Plugin Worker image checks reported success; Flutter CI was still pending at the time of this check.
- This status check does not include emulator logs, so the success of the dedicated Firestore gate is not independently confirmed here. Do not claim all tests passed until the run and its logs are inspected.
