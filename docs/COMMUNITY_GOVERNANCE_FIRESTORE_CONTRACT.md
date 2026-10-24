# Community Governance — Firestore Security Contract

Status: implemented on `feat/community-governance-and-memory`; **verification gate remains open until Emulator and CI results pass**.

This contract records the minimum security behavior required before report review or appeals can be enabled. Do not treat the current casework/appeal service prototypes as production-ready.

## Identity and authorization

- A moderator must be authenticated and carry the trusted custom claim `request.auth.token.admin == true`; client-writable profile fields must never grant moderator access.
- Reporters may create only reports whose `reporterUid` equals their authenticated UID, whose `reportedUid` differs from that UID, and whose initial status is `open`.
- Ordinary users must not list or read the global `reports` queue.
- An appellant may read only their own appeal. Moderator queue reads and decisions require moderator authorization.
- Do not rely on a rule added to one matching path without auditing all matching rules: Firestore allows access when any applicable `allow` expression evaluates true.

## Allowed state transitions

- Report: `open -> under_review`, then `under_review -> resolved|rejected`. No client may change reporter, reported user, reason, content reference, or creation time after submission.
- Appeal: `pending -> accepted|rejected`. The appellant identity, report reference, reason, and creation time are immutable after submission.
- A decision must record the authenticated moderator UID, server timestamp, and a bounded review note.
- Case events are append-only audit records. Clients must not be able to rewrite or delete prior events. Event identity and transition fields must agree with the associated decision; use an atomic write and appropriate `getAfter` validation where feasible.

## Required emulator coverage before enabling writes

1. Valid report creation succeeds; forged reporter UID, self-report, malformed status, extra fields, and oversized reason fail.
2. Unauthenticated and ordinary users cannot read/list or mutate reports.
3. A trusted moderator can read the bounded queue and perform only allowed report transitions.
4. A user can submit/read their own appeal, but cannot impersonate another appellant or decide any appeal.
5. A trusted moderator can read pending appeals and decide each pending appeal once; invalid transitions and self-granted moderator claims fail.
6. Case events cannot be forged independently, changed, or deleted; valid decision and event writes succeed atomically.
7. Regression tests cover every other existing `/reports` and recursive matching rule so no broader rule accidentally grants access.

## Implementation state and remaining gate

The feature branch now includes explicit rules for moderator report reads/transitions, participant appeal submission/reads, moderator appeal decisions, and append-only audit events. Decision writes must be paired with the deterministic event ID and matching fields in the same atomic transaction. The integration suite has been expanded with valid report-transition and appeal-decision transactions plus privilege-denial cases. The rules and tests have been committed, but CI/Emulator results for the current HEAD are still pending; therefore this is **not yet accepted or production-ready**.

## Release gate

Do not deploy or advertise casework/appeals as operational until the rules change passes the complete Firestore emulator suite, service/UI integration is verified, and the relevant CI checks pass. No production deployment is authorized by this document.

## Implementation sequence before enabling the workflow

1. Keep the current deny-by-default behavior while implementing rules; do not add broad collection reads or generic moderator exceptions.
2. Use trusted custom claims for reviewer authorization and explicitly test both a token with `admin: true` and ordinary users. A profile document or client-provided field is never an authority source.
3. Make each decision/audit pair addressable by a deterministic event document ID derived from the case ID and destination state, or use another rule-verifiable binding. Firestore rules cannot query for an arbitrary audit event, so a random event ID cannot prove from the case update rule that its paired event exists.
4. Validate the paired writes using `getAfter()`: a report/appeal transition must match the audit event's entity type, entity ID, actor UID, prior state, destination state, note, and server timestamp. Event creation must independently validate the post-transaction case state. Keep events append-only.
5. For appeal creation, require the report to exist after reads, be resolved/rejected, and identify the appellant as the reporter or reported user; constrain the appeal document ID to the report/appellant pair and reject duplicates. Read access must be limited to the appellant and trusted reviewers.
6. Audit every matching Firestore rule, including recursive wildcard matches. An additional matching allow can override a deny in another match block.
7. Run the full Firestore Emulator suite from `functions/package.json`'s `test:emulator`, then the complete CI suite. Do not enable UI actions or describe this as operational until valid transactions succeed and each privilege-escalation regression fails as expected.

The report and appeal services now use deterministic event IDs (`reportId__destinationStatus` and `appealId__destinationStatus`) to satisfy the binding enforced by these rules. Preserve this convention in any future service changes; do not relax event rules to accommodate random IDs.

