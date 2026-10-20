# AUREN Community & Collaboration — Implementation Notes

## Audit basis

- Repository execution map: `docs/AUREN_47_SYSTEMS_10_BATCHES.md`.
- Existing broad communities implementation: `lib/services/social/community_service.dart`, `lib/features/communities/presentation/communities_screen.dart`, and `lib/features/communities/presentation/community_detail_screen.dart`.
- Existing reporting foundation: `reports` rules in `firestore.rules`.
- No file explicitly named “Master Blueprint” was found in the initial repository code search; the 47-system execution map is the closest identified planning document. Confirm whether a separate blueprint exists before final scope sign-off.

## Scope decision

1. **AUREN Communities — existing foundation; do not rebuild.** Existing service/screens support public communities, membership, posts, and polls. Review remaining rule/UX gaps in a later pass.
2. **AUREN Clubs & Circles — foundational data layer added.** New `community_clubs` collection and Discover-linked `Clubs & Circles` screen support public clubs, creation, owner membership, join/leave, and category-based discovery. Private/invite-only circles, roles, and activity scheduling remain.
3. **AUREN Collaboration Spaces — foundational data layer added.** New `collaboration_spaces` collection plus a Discover-linked screen support owner-created spaces and owner-managed invitations by user UID. Shared documents, tasks, comments, and activity history remain.
4. **AUREN Community Governance — partial reuse.** Reports are submitted through the existing `reports` collection, avoiding a duplicate reporting pipeline. A moderator queue, case status transitions, sanctions, appeals, and audit history remain unimplemented.
5. **AUREN Volunteer & Causes — foundational data layer added.** New `volunteer_causes` collection plus a Discover-linked directory screen support open causes and volunteer opt-in. Cause creation is currently service-supported but is not yet exposed in this first directory screen. Capacity management, organizer review, shifts, project tasks, and impact tracking remain.

## Changed files

- `lib/services/social/community_collaboration_service.dart`
- `firestore.rules`
- `test/services/social/community_collaboration_service_test.dart`

## Verification status

The new service tests have been authored using the repository's existing `fake_cloud_firestore` and `firebase_auth_mocks` dev dependencies. They have **not yet been executed** in a Flutter runtime in this workflow. Firestore rules have been edited but have **not yet been validated with the Firebase emulator**. Do not treat cloud authorization or runtime integration as verified until those checks pass.

## Safety and release constraints

- Changes are isolated on `feat/community-collaboration-foundation`; no PR was merged and no production data was changed.
- Before release, run `dart format`, `flutter analyze`, the focused test file, the full test suite, and Firestore emulator rules tests.
- Add organizer-facing cause creation, then complete collaboration-space documents/tasks/comments and governance review workflows after the service and security contract pass validation.
