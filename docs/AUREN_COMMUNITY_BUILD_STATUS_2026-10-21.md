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
- CircleCI for the latest branch commit was still pending at the last check: Flutter CI and Functions tests. Passing checks were only the unrelated Action Executor, Plugin Worker, and Plugin Worker image checks.
- No Flutter test/analyze result or Firestore Emulator result is claimed for this batch yet.
- A write to `firestore.rules` was blocked by the GitHub connector's safety checks, so report-review and appeal rules, their security tests, and the end-to-end governance UI remain outstanding.
