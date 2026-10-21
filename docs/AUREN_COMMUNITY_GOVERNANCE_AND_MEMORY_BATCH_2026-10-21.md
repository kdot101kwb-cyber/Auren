# AUREN Community Governance & Memory Batch — 2026-10-21

This batch reuses the existing Communities, Clubs & Circles, Collaboration Spaces, and Volunteer & Causes foundations. The broad Communities system is not rebuilt. The replacement child capability is Community Memory & Outcomes: milestone, decision, and outcome posts attached to an existing community and stored through the shared feed.

Community Governance target: reviewer-only report transitions, appeals by report participants after a decision, and immutable case-event records. The target is documented, but the required Firestore rules were not changed in this run, so these flows are not ready to use.

Community Memory current scope: member-authored, bounded posts with a kind/title label and body, using the existing community-post authorization. Because existing post rules allow authors to edit or delete their own posts, this is **not yet an append-only or immutable log**.

Acceptance remains open: focused tests and Firestore Emulator validation must pass before calling the batch complete. No production data, deployments, PR merges, or destructive operations are part of this batch.
