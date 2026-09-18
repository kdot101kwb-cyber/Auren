# AUREN AI Gateway

The Flutter app never stores provider API keys. It calls one HTTPS backend endpoint.

## Request
{ "conversationId": "string", "message": "string" }

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
AUREN can later support OpenAI, Gemini, Claude and compatible gateways behind this single contract. Provider choice remains a server-side concern.

## Client configuration
Run Flutter with:
--dart-define=AUREN_AI_GATEWAY_URL=https://your-backend.example/api/ai
Do not commit secrets or real provider URLs containing credentials.

## Failure behavior
The user message is persisted before the AI request. If the gateway fails, the message remains available for retry instead of being lost.
