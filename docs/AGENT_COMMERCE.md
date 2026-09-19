# AUREN Agent Commerce & Trust
Agent actions can be bound to idempotency keys, wallet reservations, capability tokens and trust checks.

## Wallet
Money is represented as integer minor units plus an explicit ISO-like currency code. Spending must be reserved before settlement and never inferred from an approval-limit field.

## Capability tokens
Capabilities are short-lived, agent-bound grants. Production deployment should sign and verify them server-side and include nonce/replay protection.

## Trust
Agent trust records track completed work and disputes. Trust is informational and policy gates can require a minimum score.

## Disputes
Commerce and agent operations should create immutable transaction/audit references so a later dispute system can investigate without altering the original execution record.
