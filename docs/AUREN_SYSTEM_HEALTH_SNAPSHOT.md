# AUREN System Health Snapshot (foundation)

## Scope

This package is a typed, dependency-free aggregation model for health checks. The `auren_health_endpoint_adapter.dart` adapter maps the existing action-executor `/health` response into a snapshot, but it does not make network requests, read Firestore, or inspect secrets.

The action-executor adapter validates the expected service identifier and maps endpoint status plus AI/worker configuration flags. `AurenActionExecutorHealthService` can fetch the configured endpoint using `AUREN_ACTION_EXECUTOR_HEALTH_URL`; it requires HTTPS, uses a five-second default timeout, rejects responses larger than 16 KiB, and sends no Firebase token. A configured URL or credentials are configuration signals only; they do not prove that a provider or worker is live. Other callers may pass results from authorized checks into `AurenHealthSnapshot`. Each check should contain:
- a stable, non-empty identifier unique within the snapshot;
- a short label suitable for a developer-facing status page;
- a status from `AurenHealthStatus`;
- the UTC or otherwise consistently normalized time when the check completed;
- a non-negative duration in milliseconds;
- an optional pre-sanitized summary.

## Status aggregation

The overall status is intentionally conservative:
1. An empty snapshot is `unknown`, not healthy.
2. Any `unavailable` check makes the snapshot unavailable.
3. Otherwise, any `degraded` check makes the snapshot degraded.
4. Otherwise, any `unknown` check makes the snapshot unknown.
5. Only a non-empty snapshot where every check is healthy is healthy.

## Security and privacy boundary

- Do not put API keys, bearer tokens, credentials, request headers, user content, or raw exception dumps in `safeSummary`.
- Sanitize exception messages before constructing a check.
- A check's `id` and `label` should be fixed application identifiers, not user-supplied strings.
- This model does not grant permissions and must not be used as an authorization decision.
- Do not expose internal health detail to unauthenticated clients. Any future endpoint or screen must apply the existing authentication and least-privilege rules.
- Do not interpret a successful local model aggregation as evidence that Firebase, a worker, or an external provider is healthy.

## Verification

Run the focused tests with:

```sh
flutter test test/core/observability/auren_health_snapshot_test.dart
```

The tests cover empty snapshots, all-healthy snapshots, status precedence, counts, invalid input, duplicate IDs, and list immutability.

## Follow-up work

A production-ready observability feature still needs freshness/staleness policy, bounded safe event logging, retention rules, and an authenticated developer-facing view. The health endpoint itself remains a lightweight public deployment probe; do not treat it as a privileged developer API. No live provider probes or production deployment are included in this foundation.
