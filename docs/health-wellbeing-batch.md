# AUREN Health & Wellbeing — implementation audit

Date: 2026-10-22
Working branch: `feat/health-privacy-hardening`
Parent work: `feat/health-wellbeing`

## Scope and existing foundations

- The Master Blueprint, `docs/AUREN_47_SYSTEMS_10_BATCHES.md`, places Health / Sports / Fitness in Batch 7. A system is ready only when its user flow, data layer, security, error/empty states, and integrations are implemented.
- `lib/services/health/auren_wellbeing_local_store.dart` and `lib/features/health/presentation/health_wellbeing_screen.dart` provide the private, account-scoped local wellbeing workspace for journal notes, fitness goals/activity, sleep, healthy habits, reminder preferences, and care coordination notes.
- The local workspace uses secure local storage and does not itself call Firestore, analytics, or AI. It does not claim cross-device sync or cloud backup.
- `lib/features/health/presentation/health_sports_screen.dart` routes users to the local workspace. Its AI Coach cards open Messenger with general prefilled prompts; local journal records are not automatically attached to those prompts.
- General habits, reminders, and calendar services under `lib/services/personal_ai/` are Firestore-backed. They are separate from the private local health workspace and must not be described as local-only.
- Messenger stores conversation messages remotely and may send AI conversation text to the configured AI service. The Arabic AI privacy notice is displayed above the composer in AI conversations. Users should not enter sensitive health details into AI chat unless they choose to share them.

## Remote health check-in compatibility path

- `lib/services/health/auren_health_repository.dart` remains for compatibility and accesses `users/{uid}/healthCheckins` in Firestore. The current local wellbeing workspace does not call it.
- Reads and writes require a `HealthDataSharingConsent` object created after explicit user confirmation. Missing consent fails closed.
- Consent purpose is required and bounded. The hardening branch now rejects consent older than 15 minutes or implausibly future-dated before reads/writes.
- A Firestore watch is cancelled when the consent window expires and emits a `StateError`, preventing a live subscription from silently continuing indefinitely under an expired consent token.
- Consent is not persisted by the consent class. The UI flow that creates consent must still be explicit, specific about the remote purpose, and must not reuse a stale token.
- Firestore owner-only rules are access control; they are not a replacement for user consent.

## Safety and limitations

- The wellbeing feature is for general tracking, not diagnosis, treatment selection, medication changes, or dosage advice.
- Reminder preferences are stored locally; OS notification scheduling is not implemented in this slice.
- Care coordination notes organize questions and dates but do not contact providers or confirm appointments.
- Secure storage depends on platform support/device security. This is not cloud backup, and app removal/device loss can result in loss of local records.
- This is a focused audit, not a complete repository-wide privacy certification. Indirect flows through shared context builders, generic analytics/logging, and unrelated systems still require a separate audit. Do not claim that all health-related data across AUREN stays on-device.

## Verification

The targeted workflow is `.github/workflows/health-wellbeing-tests.yml`. On `feat/health-privacy-hardening`, it runs local store tests, remote health repository consent tests, wellbeing screen tests, AI privacy notice tests, formatting, and targeted Flutter analysis.

This batch adds tests for expired consent being rejected before Firestore writes and updates the confirmed-consent test to use the current time. CI must pass before this batch is considered verified. No pull request, merge, or deployment is performed as part of this work.
