# NOVA owner-approved action queue

This local queue defines a fail-closed lifecycle for proposed NOVA actions:

`awaitingApproval → approved → running → completed|failed`

An owner may instead reject a pending request. Rejected, completed, and failed
requests are terminal in this first implementation.

## Approval policy

- Local read-only inspection may enter the approved state without a separate
  confirmation because it has no external side effect.
- Writes, publishing, messages, deployments, payments, account changes, and
  sensitive actions must wait for explicit owner confirmation.
- A caller cannot claim a pending, rejected, running, or terminal action.
- The queue records request summaries and lifecycle state only. It does not
  contain arbitrary action payloads and does not execute anything.

## Important boundary

This is a local policy/state component, not a secure authorization server.
Any future executor must independently validate the exact action payload,
owner identity, scopes, kill switch, and policy immediately before execution.
The queue must never be treated as proof that a remote service accepted or
completed an action.
