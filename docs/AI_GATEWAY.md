# AUREN AI Gateway

The Flutter app never stores provider API keys. It calls one HTTPS backend endpoint.

## Request
`POST /api/ai/chat`

Headers:
`Authorization: Bearer <Firebase ID token>`

Body:
`{ "conversationId": "string", "message": "string" }`

## Response
{ "text": "string", "action": "optional string", "requiresApproval": false }

## Server responsibilities
- authenticate the Firebase user
- validate conversation membership
- apply rate limits
- route between AI providers
- keep provider credentials server-side
- log usage/cost metadata without storing unnecessary private prompts
- return structured actions
- require explicit user approval before sensitive execution
- write audit events for executed actions

## Provider routing
The current backend uses a single OpenAI-compatible chat-completions endpoint configured by environment variables. OpenAI, Gemini, Claude-compatible gateways and other providers can later sit behind the same server contract.

## Client configuration
Run Flutter with:
--dart-define=AUREN_AI_GATEWAY_URL=https://your-backend.example/api/ai
Do not commit secrets or real provider URLs containing credentials.

## Failure behavior
The user message is persisted before the AI request. If the gateway fails, the message remains available for retry instead of being lost.


## Approved action execution

Sensitive AI actions use a separate trusted execution endpoint.

### Request
```json
{ "actionId": "string" }
```

The Flutter client sends the current Firebase ID token as:
`Authorization: Bearer <Firebase ID token>`.

The backend must:
- verify the Firebase ID token and derive the UID from the token, not from client input
- load `users/{uid}/actions/{actionId}` from Firestore
- require the action to be in `approved` state
- resolve the action type through the server-side Action Registry
- validate the action payload against the registered schema
- verify permission, risk level, approval level and spending limits against the registry
- enforce spending, permission and safety limits
- execute the action server-side
- write `executing`, then `completed` or `failed`
- append an immutable audit event
- return a safe result to the client

The client never receives provider secrets and never decides that an action completed. Firestore rules only allow the user to move a pending action to `approved` or `rejected`; trusted backend code performs final execution state changes.

Client configuration:
`--dart-define=AUREN_ACTION_EXECUTOR_URL=https://your-backend.example/api/actions/execute`

This separation is intentional: Firestore Security Rules authorize client data access, while trusted server code performs privileged execution. Firebase documents that server client libraries bypass Firestore Security Rules and instead use IAM/Application Default Credentials, so the execution backend must enforce its own authorization checks.

## Current backend configuration

The action-executor requires:
- `AUREN_AI_BASE_URL`
- `AUREN_AI_API_KEY`
- `AUREN_AI_MODEL`

Provider requests are authenticated server-side and have a 30-second timeout. The provider key is never sent to Flutter.
