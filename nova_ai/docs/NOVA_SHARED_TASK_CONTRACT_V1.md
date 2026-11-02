# NOVA Shared Task Contract v1

## Purpose
One versioned envelope is shared by task submission and the scheduled worker. It is the persistence boundary for future App Market Scout, Application Factory, debate execution, and DevOps adapters. This is a compatibility-first foundation, not a claim that every workflow is connected.

## Canonical task fields
- Identity: `schemaVersion`, `taskId`, `ownerUid`, `idempotencyKey`, `type`.
- Request: bounded `prompt` and normalized `metadata`.
- Lifecycle: `status`, `executionMode`, `createdAt`, `updatedAt`, optional `checkpoint`.
- Approval: `requiresApproval` plus an `approval` object. Future side-effect adapters must bind approval to the exact action/input/commit; a generic approval flag is not sufficient.
- Result: `result`, `error`, `provider`, bounded `evidence[]`.
- Reliability: `retryCount`, `maxAttempts`.
- Cost safety: `estimatedCostUsd` and `actualCostUsd` default to zero. The contract does not authorize spend.

## Lifecycle
Allowed transitions are defined in `nova_task_contract.js` and tested:
- `awaiting_approval -> queued | cancelled | blocked`
- `queued -> running | cancelled | blocked`
- `running -> verifying | provider_processing | succeeded | queued | failed | blocked | cancelled`
- `verifying -> succeeded | queued | failed | blocked | cancelled`
- `provider_processing -> succeeded | failed | blocked | cancelled`
- `failed -> queued` only for an explicit retry path.
- `succeeded`, `blocked`, and `cancelled` are terminal.

The current scheduled worker uses the shared transition policy before claiming queued tasks. Existing legacy records remain readable; this change does not bulk-migrate Firestore documents.

## Queue and audit
Queue records carry the same schema version, owner/task identity, bounded attempt count, and claim/lease placeholders. Audit events carry a schema version and a strict allowlist of detail fields to reduce accidental secret leakage.

## Evidence
Evidence references are accepted only as HTTPS URIs, bounded in count and length. SHA-256 is retained only when it is a valid 64-character hexadecimal digest. Evidence must be produced by the real adapter; the contract itself does not manufacture proof.

## Current integration
- `submitNovaTask` now creates task and queue records through the shared contract.
- `processNovaTaskQueue` uses the shared transition guard before claiming a task.
- Node tests cover identity, approvals, queue defaults, transition rules, audit allowlisting, and evidence validation.
- Existing task types, current execution adapters, and legacy status fields remain compatible.

## Not yet implemented
- Firestore backfill/migration for old task documents.
- Exact-action approval hashes and approval expiry/revocation.
- Lease recovery for a worker that dies after claiming a task.
- End-to-end persisted checkpoints and evidence from all providers.
- Shared contract adoption by App Builder jobs, Debate Council plan steps, and local Brain task storage.
- UI status mapping for every canonical state.
- Production deployment verification.

No production data is migrated and no deployment, publishing, merge, or paid action is performed by this change.
