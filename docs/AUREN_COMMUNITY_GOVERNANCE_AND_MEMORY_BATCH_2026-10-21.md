# AUREN Community Governance & Memory Batch — 2026-10-21

This batch reuses the existing Communities, Clubs & Circles, Collaboration Spaces, and Volunteer & Causes foundations. The broad Communities system is not rebuilt. The missing child capability selected in its place is Community Memory & Outcomes: an append-only member-scoped record of milestones, decisions, and outcomes.

Community Governance scope: moderator-only report review, explicit case transitions, appeals by report participants after a decision, and immutable audit events. All access is enforced by Firestore rules using trusted custom claims; client-side role checks are only presentation hints.

Community Memory scope: member-readable entries, member-authored creation, bounded content, stable authorship, and no in-place edits/deletes so the log remains auditable.

Acceptance: focused Flutter service tests and Firestore Emulator rules tests must pass. No production data, deployments, PR merges, or destructive operations are part of this batch.
