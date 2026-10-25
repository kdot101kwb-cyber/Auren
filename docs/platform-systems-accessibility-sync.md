# AUREN platform foundations: access, notifications, accessibility, sync

## Existing implementations reused
- Identity: `lib/services/auth/auth_service.dart` and Firebase Auth own sign-in and auth-state changes. Do not create another credential/session provider.
- Notifications: `lib/services/notifications/notification_repository.dart`, `lib/services/social/notification_service.dart`, and `lib/features/notifications/presentation/notification_center_screen.dart` are the canonical in-app path. `AurenFcmService` remains delivery/token plumbing; Messenger is not an in-app notification store.
- Offline: `lib/services/offline/auren_offline_sync_service.dart` already provides a bounded SharedPreferences queue and handler registration. The new merge helper is a separate pure function; it does not automatically send data.
- Accessibility: use Flutter Semantics, FocusTraversalGroup, MediaQuery text scaling and theme colors in existing screens. Helpers in this batch support auditing, not a claim that all screens have been remediated.

## Added foundations
- Access policy helpers fail closed for unknown role claims and require an explicit, unexpired session context. These are client-side UX guards, not a replacement for Firestore/server authorization rules.
- Notification preferences model is serializable and filters only in-app display. It does not send, cancel, or change remote notifications.
- Accessibility utilities bound text scaling and calculate WCAG contrast ratios (4.5:1 normal text, 3:1 large text).
- Three-way sync merge preserves unilateral changes and reports same-field concurrent edits instead of silently choosing a remote value. Conflicts require an explicit caller decision.

## Validation boundary
This branch requires Flutter format, analyze, focused tests, full Flutter tests and Android debug build through CI. No local execution is claimed by the GitHub connector. Do not mark these systems complete until CI is green and the affected existing screens/services are integrated and reviewed. No PR is merged or deployed by this work.
