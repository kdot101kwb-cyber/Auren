# AUREN Plugin Runtime

AUREN now has a runtime security gate before plugin execution.

## Controls
1. Manifest validation and capability allowlisting.
2. SHA-256 package integrity metadata.
3. HMAC signature verification for trusted publishing.
4. Payload size limits.
5. Per-agent/per-plugin daily invocation quotas.
6. Version matching between manifest and package.

## Important boundary
This gate does not execute arbitrary plugin code inside the API process.

Production execution must use a separately deployed isolated worker/container with:
- deny-by-default network
- no provider secrets
- isolated filesystem
- CPU/memory/process limits
- timeout enforcement
- read-only package mount
- egress allowlist
- malware/dependency scanning
- signed artifact verification
- kill switch and rollback

The API should invoke that worker only after the runtime gate succeeds.

## End-to-end flow

`POST /api/agents/plugins/runtime/execute` authenticates the Firebase user, validates the agent, verifies package signature/version/hash metadata, consumes quota, then sends only the validated manifest and payload to the isolated worker.

The worker requires a separate shared secret and only accepts mounted `file:` entrypoints. The Action Executor never executes plugin code itself.

### Required deployment environment

Action Executor:
- `AUREN_PLUGIN_SIGNING_SECRET`
- `AUREN_PLUGIN_WORKER_URL`
- `AUREN_PLUGIN_WORKER_SECRET`

Plugin Worker:
- `WORKER_SHARED_SECRET`
- `PLUGIN_TIMEOUT_MS`

The worker should remain private/internal; do not expose port 8090 publicly.
