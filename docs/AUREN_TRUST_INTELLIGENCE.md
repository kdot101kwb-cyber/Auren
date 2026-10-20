# AUREN Trust Intelligence

## Purpose
Build a shared, explainable trust and safety layer for AUREN social, commerce, opportunities, services, and agent interactions.

## Existing capabilities found during the initial audit
- Social reporting and account blocking: `lib/services/social/safety_repository.dart`.
- Social safety actions sheet: `lib/features/social/presentation/safety_actions_sheet.dart`.
- Talent evidence submission: `lib/features/talent/presentation/talent_verification_screen.dart`.
- User trust-signal storage abstraction: `lib/services/personal_ai/trust_graph_service.dart`.
- Agent commerce trust checks and dispute references: `docs/AGENT_COMMERCE.md` and agent services.

These must be reused and hardened rather than duplicated. The current trust-signal client service accepts labels and types directly; signals such as identity verification must never be treated as authoritative merely because a client wrote them. Authoritative verification and scoring need trusted server-side provenance.

## Security audit note
The current `firestore.rules` file has no explicit `trust_signals` subcollection rule, and no recursive wildcard grant was found in the audited rules text. Treat the trust-signal client service as unavailable to ordinary clients unless emulator/integration tests confirm the intended authorization; do not solve this by adding broad client read/write access. If the feature is enabled later, define a narrowly scoped rule set and server-owned provenance fields first. In particular, a client must not be able to create an `identity_verified` signal that appears authoritative.

## Initial delivery scope
1. Provide a clear Trust & Safety Center explaining what signals mean, what users can do, and how to report/block suspicious activity.
2. Link the center to the existing people-search flow so users can reach profile-level safety actions without creating a second reporting/blocking implementation.
3. Explain the difference between profile claims, submitted evidence, user reports, and automated signals in user-facing guidance.
4. Establish explainable trust indicators with provenance, timestamps, and explicit limitations; do not show a numeric score until its inputs, abuse resistance, and rules are validated.
5. Treat reports as unverified allegations, not proof. Protect reporters and subjects from retaliation and brigading.
6. Define server-owned review states and audit history before using trust indicators to gate financial or high-impact actions.
7. Add unit and Firestore rules tests; verify privacy boundaries and authorization.

## Authorization regression coverage
- Added `functions/trust_signals_rules.integration.test.js` to verify that owners, other signed-in users, and unauthenticated clients cannot read or mutate trust-signal documents under the current rules.
- The client trust graph service no longer accepts `identity_verified` as a client-authored signal type. Authoritative identity verification must be created only by a trusted server/reviewer workflow.
- Run with `npm run test:emulator` from `functions/` when the Firestore emulator is available. The test is included in both the `functions/package.json` emulator suite and the Firestore Rules Validation workflow. For each revision, confirm the corresponding CI run before reporting validation status.

## Non-goals for the first slice
- No automatic public accusation or public fraud label.
- No identity verification claim without trusted evidence/reviewer provenance.
- No client-controlled reputation score.
- No production deployment or merge without explicit authorization.

## Acceptance criteria
- Existing social report/block flows remain compatible.
- User-facing copy distinguishes verified evidence, user-submitted claims, and automated risk signals.
- Trust data is readable only to authorized audiences and cannot be self-awarded as authoritative by a client.
- Tests cover invalid data, unauthorized writes/reads, duplicate/abusive reports, and signal provenance.
- CI results are reported accurately; skipped deployment is not described as deployed.
