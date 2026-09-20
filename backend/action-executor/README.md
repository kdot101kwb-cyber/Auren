# AUREN Action Executor

Trusted server boundary for user-approved AI actions.

The production Flutter path currently uses the Firebase callable function
`executeAurenAction` in `functions/index.js`. The standalone Node executor
in this directory remains the hardened backend boundary for future external
deployments and expanded action capabilities.

## Security contract

1. Verify the Firebase ID token.
2. Derive the UID from the verified token.
3. Load the action from `users/{uid}/actions/{actionId}`.
4. Require `status == approved`.
5. Validate the action type and payload against an allowlist.
6. Atomically mark it `executing`.
7. Execute only server-side.
8. Write `completed` or `failed`.
9. Write an execution record and audit event.

Never trust a client-supplied UID, action description, completion status, or
authorization decision.
