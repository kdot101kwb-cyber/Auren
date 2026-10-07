# AUREN Action Engine Security Gate v1.1

> Any red item means the Production Security Gate is not closed.

## 1. Failure-state matrix

| Condition | Required result |
|---|---|
| Validation / permission / expiry fails before execution | Reject; status remains `approved` |
| Executor fails before any external effect | `failed` |
| Failure during/after provider call, or provider result is unknown | `recovery_required` |
| Provider confirms success | `completed` |
| Provider confirms no execution (`not_found`) | `failed` |
| Reconciliation is inconclusive | `manual_review` |

Terminal states: `completed`, `failed`. They cannot be executed again; the user creates a new action.

Permission revocation must be checked both before approval and again immediately before execution from authoritative server-side state.

## 2. Draft approval contract

- Client edits are allowed only while `status == pending`.
- Client may change only the explicit draft allowlist.
- `draftVersion` must be an integer and must increase by exactly 1 per client draft update.
- The approval request sends `expectedVersion` only.
- The server reads the current stored payload inside the approval transaction.
- The server computes and stores the canonical payload hash.
- The client never supplies the authoritative approval hash.
- If `expectedVersion` differs from the stored version, approval is rejected and the user must refresh/review the latest draft.
- Server validation of the action payload remains mandatory; Firestore Rules are not a substitute for action-specific validation.

## 3. Firestore Rules gate

### Positive

- [ ] Owner can read their own action.
- [ ] Owner can edit draft `title`, `description`, `payload`, `draftVersion`, and `updatedAt` only while pending.
- [ ] Draft update requires `draftVersion == oldVersion + 1`.

### Negative

- [ ] Same version rejected.
- [ ] Version jump rejected.
- [ ] Status change rejected.
- [ ] `actionType` change rejected.
- [ ] `createdAt` change rejected.
- [ ] Approval fields rejected.
- [ ] Updates after pending are rejected.
- [ ] Delete rejected.
- [ ] Cross-user read/update rejected.
- [ ] Unauthenticated read/update rejected.
- [ ] Direct client create rejected.

### Rule boundary

Rules protect document ownership, lifecycle state, and the draft field allowlist. They do not replace server-side `validateAurenAction` or authoritative permission checks.

## 4. Approval transaction

The server transaction must:

1. Read the action document.
2. Require `status == pending`.
3. Require `draftVersion == expectedVersion`.
4. Validate the stored payload.
5. Compute the server-side payload hash.
6. Write approval fields and the transition audit event in the same transaction.

A concurrent draft update must cause the approval transaction to retry and then reject on the new version.

## 5. Recovery gate

- [ ] Recovery job finds `executing` actions beyond the recovery threshold.
- [ ] Recovery threshold is longer than the executor's maximum timeout.
- [ ] Stale `executing` action becomes `recovery_required`.
- [ ] Recovery emits an alert (mocked in tests).
- [ ] `manual_review` cannot close without documented reconciliation.
- [ ] Provider idempotency-key retention exceeds the recovery window.
- [ ] Crash after provider call does not cause a second external effect.

## 6. Audit gate

Every state transition must have exactly one corresponding append-only audit event.

Audit fields:

- `workflowId`
- `fromStatus`
- `toStatus`
- `actorId`
- `timestamp`
- `payloadHash`
- `reasonCode`
- `errorClass`

Do not store provider secrets, idempotency keys, or sensitive approval internals in the audit projection.

## 7. Execution gate

- [ ] Execution requires exact `approved` status.
- [ ] Permission is rechecked from authoritative server state.
- [ ] Approval expiry uses server time.
- [ ] Approval is bound to the authenticated user.
- [ ] Approval is bound to the exact action type.
- [ ] Approval is bound to the server-computed payload hash.
- [ ] `approved -> executing` is atomic.
- [ ] Concurrent execution allows only one winner.
- [ ] Terminal states cannot execute again.
- [ ] Financial operations use a server-generated idempotency key.
- [ ] Executor uses only approved payload plus freshly verified authoritative external state.

## 8. Spatial Graph boundary

The Spatial Graph is a read-only projection.

- [ ] Projection is written by backend only.
- [ ] Projection fields use an explicit allowlist.
- [ ] Risk level is server-derived.
- [ ] Client rules permit read only.
- [ ] No `idempotencyKey`.
- [ ] No approval internals.
- [ ] No provider secrets/details.
- [ ] No execution authority.
- [ ] No direct mutation of payload, permissions, approval, or workflow state.

## 9. CI definition of GREEN

The gate is GREEN only when:

- [ ] Firestore Rules emulator suite is GREEN.
- [ ] Action failure-state tests are GREEN.
- [ ] Concurrent execution test is GREEN.
- [ ] Provider-crash/recovery test is GREEN.
- [ ] Idempotency test is GREEN.
- [ ] Audit transition tests are GREEN.
- [ ] Rules deployment verification confirms the deployed rules match the tested source.
- [ ] Required CI checks are GREEN.

Any red item means the Production Security Gate remains open.
