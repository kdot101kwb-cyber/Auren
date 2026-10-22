# AUREN Community Governance & Memory Batch — 2026-10-21

This batch reuses the existing Communities, Clubs & Circles, Collaboration Spaces, and Volunteer & Causes foundations. The broad Communities system is not rebuilt. The replacement child capability is Community Memory & Outcomes: milestone, decision, and outcome posts attached to an existing community and stored through the shared feed.

Community Governance target: reviewer-only report transitions, appeals by report participants after a decision, and immutable case-event records. The client service prototypes now check report/appeal state inside Firestore transactions and write each decision with its audit event atomically. Appeal submission checks participant eligibility, a terminal report status, and duplicate submission. These client checks are defense-in-depth only: the required Firestore rules remain safe-deny and were not changed, so the flows are not ready to use. Emulator-backed service tests and explicit moderator/owner rules are still required.

Community Memory current scope: member-authored, bounded posts with a kind/title label and body, using the existing community-post authorization. Because existing post rules allow authors to edit or delete their own posts, this is **not yet an append-only or immutable log**.

Acceptance remains open: focused tests and Firestore Emulator validation must pass before calling the batch complete. No production data, deployments, PR merges, or destructive operations are part of this batch.
