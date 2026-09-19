# AUREN Action Executor

Trusted server boundary for user-approved AI actions.

## Run

Requires Firebase Application Default Credentials.

```bash
npm install
npm start
```

Set:

```text
PORT=8080
```

The Flutter app points to:

```text
--dart-define=AUREN_ACTION_EXECUTOR_URL=https://your-backend.example/api/actions/execute
```

## Security contract

1. Verify the Firebase ID token.
2. Derive the UID from the verified token.
3. Load the action from `users/{uid}/actions/{actionId}`.
4. Require `status == approved`.
5. Validate the action type against an allowlist.
6. Atomically mark it `executing`.
7. Execute only server-side.
8. Write `completed` or `failed`.
9. Write an audit event.

Never trust a client-supplied UID, action description, completion status, or authorization decision.
