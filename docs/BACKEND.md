# AUREN Backend Boundary

The app is intentionally provider-agnostic.

## Firebase
Planned production adapters:
- Firebase Authentication
- Cloud Firestore for profiles, conversations and messages
- Cloud Functions for trusted server operations
- Firebase Storage for media/files
- App Check and security rules

## AI Gateway
Client calls an AUREN-controlled HTTPS gateway. The gateway owns provider credentials, routing, fallback, rate limits, cost controls and safety checks. Provider keys must never be shipped in the Flutter app.

## Personal AI memory
Memory is user-controlled. Each item has an explicit enabled state and can be deleted. Sensitive actions require explicit approval before execution.

## Migration strategy
Current local adapters exist only to keep the UI runnable. Production adapters can implement the same interfaces without rewriting feature screens.
