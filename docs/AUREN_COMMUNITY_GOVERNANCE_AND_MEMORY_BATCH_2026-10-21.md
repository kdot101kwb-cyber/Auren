# AUREN Community Governance & Memory Batch — 2026-10-21

This batch reuses the existing Communities, Clubs & Circles, Collaboration Spaces, and Volunteer & Causes foundations. The broad Communities system is not rebuilt. The replacement child capability is Community Memory & Outcomes: milestone, decision, and outcome posts attached to an existing community and stored through the shared feed.

Community Governance implementation now includes reviewer-only report transitions, participant appeals after a terminal decision, and append-only case-event rules. Firestore rules use the trusted `admin` custom claim, validate legal transitions, bind each report/appeal decision to its deterministic audit-event document with `getAfter()`, and deny event updates/deletes. Appeal creation is limited to a report participant and one deterministic report/UID pair. The service uses matching deterministic event IDs. This is implemented on the feature branch but remains **unverified until the Firestore Emulator suite and CI pass**; do not enable production flows before that gate.

Community Memory current scope: member-authored, bounded posts with a kind/title label and body, using the existing community-post authorization. Because existing post rules allow authors to edit or delete their own posts, this is **not yet an append-only or immutable log**.

Acceptance remains open: the expanded atomic transaction tests and Firestore Emulator validation must pass before calling the batch complete. No production data, deployments, PR merges, or destructive operations are part of this batch.
