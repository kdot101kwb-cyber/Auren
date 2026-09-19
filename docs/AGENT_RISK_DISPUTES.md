# AUREN Agent Risk, Disputes & Liability

## Transaction lifecycle
`reserved -> settled`
`reserved -> released`
`settled -> refunded`
`reserved/settled/refunded -> disputed`

Disputes are immutable from the client side and are managed by the trusted Action Executor.

## Dispute lifecycle
`open -> under_review -> resolved`
`under_review -> rejected`
`open/under_review -> cancelled`

Evidence is stored under the dispute and is read-only to the client.

## Liability
Every dispute creates an Agent Liability record containing:
- agent
- transaction
- amount/currency
- assigned party
- liability state
- resolution
- policy reference

## Risk engine
Risk states:
- normal
- watch
- restricted
- suspended

The current baseline policy increases risk from execution failures and opened disputes. Reaching the suspension threshold pauses the primary agent server-side.

This is a policy foundation, not a legal determination of liability.

## Recovery
Action execution leases expire after five minutes. A retry can recover an abandoned execution claim before attempting execution again.

## Production hardening still required
- human/platform review workflow for high-value disputes
- external payment-provider reconciliation
- evidence file storage and malware scanning
- jurisdiction-specific dispute/consumer rules
- signed agent credentials
- dedicated admin review controls
- automated monitoring and alerting
