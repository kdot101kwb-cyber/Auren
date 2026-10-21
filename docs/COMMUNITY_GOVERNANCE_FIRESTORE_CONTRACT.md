# Community Governance — Firestore Security Contract

Status: design gate only; **not implemented rules**.

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

## Current known gap

The current `firestore.rules` permits constrained report creation only. It does not authorize report queue reads/updates, `community_case_appeals`, or `community_case_events`. The integration suite intentionally asserts these operations remain denied. This is a safe failure mode, not a working moderation workflow.

## Release gate

Do not deploy or advertise casework/appeals as operational until the rules change passes the complete Firestore emulator suite, service/UI integration is verified, and the relevant CI checks pass. No production deployment is authorized by this document.
