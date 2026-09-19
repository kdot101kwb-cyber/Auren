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
