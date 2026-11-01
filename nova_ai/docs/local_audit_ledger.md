# NOVA local audit ledger

The ledger stores a bounded, device-local history of workflow events. It is
intended for visible accountability in the NOVA app, not as a tamper-proof
security log.

## Redaction

Metadata keys containing password, token, secret, seed, private-key,
authorization, API-key, wallet, credential, or cookie terms are replaced with
`[redacted]`. Nested maps and lists are sanitized recursively with depth and
size limits. Long strings and messages are truncated.

## Limits

- Local SharedPreferences storage only; it is not synchronized.
- Records can be modified or removed by a user with device access.
- Do not place raw request bodies, credentials, private keys, wallet seed
  phrases, or payment information in audit messages.
- Production-grade audit integrity requires a server-side append-only store
  with authenticated writes and retention controls.

Tests verify nested redaction, persistence, duplicate rejection, malformed
storage recovery, and bounded history.
