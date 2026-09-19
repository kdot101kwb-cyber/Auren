# AUREN Agent Commerce & Trust

Agent actions can be bound to idempotency keys, wallet reservations, capability tokens and trust checks.

## Wallet lifecycle
Money is represented as integer minor units plus an explicit ISO-like currency code.
The backend now supports:
- reserve: move amount into reserved balance
- settle: consume the reservation and reduce available balance
- release: return a reservation to available balance
- refund: return a previously settled amount to available balance

Each lifecycle operation is transaction-protected and writes an audit event.

## Capability tokens
Capabilities are short-lived, agent-bound grants signed server-side with HMAC and protected against token replay with a Firestore nonce record.

## Trust
Agent trust records track completed work and disputes. Trust is informational and policy gates can require a minimum score.

## Disputes
Commerce and agent operations retain immutable transaction/audit references. A dedicated dispute workflow can use these references to investigate and resolve future commerce issues.

## Production payment boundary
This wallet is an internal accounting/reservation foundation. It is not a payment processor and does not yet connect to bank cards, mobile money, Stripe, PayPal, or other external settlement providers.
