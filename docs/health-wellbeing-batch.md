# AUREN Health & Wellbeing — implementation audit

Date: 2026-10-21
Branch: `feat/health-wellbeing`
Base: `main` at `c9167bcc83bbfc6fe18bcc94878f6b4580344507`.

## Existing systems inspected before changes

- `docs/AUREN_47_SYSTEMS_10_BATCHES.md` already places Health / Sports / Fitness in Batch 7. Its completion rule requires user flow, data layer, security, error/empty states and integration, and says to reuse existing foundations.
- `lib/services/health/auren_health_repository.dart` stores daily check-ins in Firestore under `users/{uid}/healthCheckins`. It is cloud-backed and not suitable as the default path for this privacy-first offline slice.
- `lib/features/health/presentation/health_sports_screen.dart` is the health/sports landing screen. Its former Daily Check-in action wrote fixed activity, water, sleep and mood values to Firestore without asking for explicit health-data sharing consent. This branch replaces that entry point with the local workspace.
- `lib/services/personal_ai/habit_service.dart` and `lib/features/personal_ai/presentation/habit_screen.dart` already implement general habits using Firestore. The new health workspace does not duplicate that remote dependency.
- `lib/services/personal_ai/reminder_service.dart` and `lib/services/personal_ai/calendar_service.dart` are general-purpose cloud services. Care coordination here is a health-context note and question list, not a duplicate general appointment scheduler.

## New implementation in this branch

- `lib/services/health/auren_wellbeing_local_store.dart`: five bounded domain models for wellness journal, fitness goals/activity minutes, sleep duration/quality, healthy habits with user-controlled local reminder preferences, and care coordination notes/questions. Data is scoped by the current account ID and stored through `flutter_secure_storage`; no network repository or AI client is used by this store. The model rejects invalid ranges, duplicate record IDs, oversized collections/notes, invalid reminder times, unsupported schema versions and malformed stored data without silently overwriting it.
- `lib/features/health/presentation/health_wellbeing_screen.dart`: Arabic-first local workspace for creating and viewing records in all five areas, tracking movement minutes and habit completion, setting/disabling reminder preferences, organizing care questions by date, and explicitly deleting local wellbeing records.
- `lib/features/health/presentation/health_sports_screen.dart`: the former fixed-value cloud check-in entry now opens the private local workspace. AI Coach cards still send the user's explicitly entered prompt to Messenger when tapped; local journal contents are not attached by this flow.
- Tests: `test/services/health/auren_wellbeing_local_store_test.dart` and `test/features/health/health_wellbeing_screen_test.dart`.
- Targeted workflow: `.github/workflows/health-wellbeing-tests.yml`.

## Privacy and safety boundaries

- No diagnosis, treatment selection, medication change or dosage recommendation is implemented.
- The new local workspace does not send its journal, sleep, fitness, habit or care-note records to Firestore, AI, analytics or another external service.
- Only the current account's locally stored dataset is read/written; a separate user ID receives a separate key.
- The `AurenHealthRepository` Firestore implementation and `healthCheckins` security rules remain in the codebase for compatibility. The old landing-screen call site was removed in this branch; the existence of the repository/rules alone does not mean the new local workspace uses them.
- AI Coach buttons on the landing screen send a fixed/general prompt chosen by the user tapping the button. The audit did not find a path attaching the local journal or care notes to those prompts in the inspected screen.
- The new local store and screen were inspected for Firestore, analytics, and AI-client usage: no such remote calls are present in these two files. This was a focused audit of the health landing screen, local workspace, local store, health repository, and the identified general habit/reminder/calendar services—not a complete repository-wide taint analysis. Generic logging/analytics and indirect call paths elsewhere in the application remain outside this audit, so do **not** interpret this as proof that no health-related data can ever leave the device.
- Reminder time preferences are saved locally and can be toggled off. Actual OS notification scheduling is **not** implemented in this slice; the UI discloses this.
- Secure storage behavior depends on platform support and device security. This is local-only storage, not cloud backup or cross-device sync. Data may be lost if app data is removed or the device is lost; this branch does not promise a recovery mechanism.
- The appointment date field validates the YYYY-MM-DD shape, not calendar validity. Care coordination does not contact providers or confirm appointments.

## Verification status

- Initial workflow runs `39647500601` and `39647898176` failed on a reminder-time regex and a malformed method boundary respectively; both issues were corrected.
- Workflow run [39648583473](https://github.com/kdot101kwb-cyber/Auren/actions/runs/39648583473) passed on implementation commit `92a2b7a2afb3d2e8138f3fc4fdd5090b3b5ac072`.
- Documentation-update workflow run [39650574997](https://github.com/kdot101kwb-cyber/Auren/actions/runs/39650574997) also passed. Successful steps: dependency resolution, formatting changed wellbeing sources, local wellbeing domain/storage tests, wellbeing screen tests, and targeted static analysis.
- Latest implementation commit `24146b85f949912406de4199dd8a3ebae13aa427` passed targeted workflow run [39652531380](https://github.com/kdot101kwb-cyber/Auren/actions/runs/39652531380), including the local store tests, wellbeing screen tests, and targeted analysis. The deletion-confirmation test checks cancellation preserves data and confirmed deletion only clears the active account.
- The latest documentation-only privacy-audit update needs its own workflow run to verify. All checks listed above are targeted checks, not a full-repository Flutter test/build. No PR was opened, and no merge or deployment was performed.

## Follow-up repository tree and call-site audit (2026-10-21)

- Resolved the branch ref to commit `a32248c2c06d50ac0f588ebbe650272b4bf8dc38` and inspected its complete recursive Git tree: 998 entries; GitHub reported `truncated: false`.
- Confirmed the branch version of `lib/features/health/presentation/health_sports_screen.dart` imports the local wellbeing screen and contains no import or direct call to `AurenHealthRepository`. Its AI Coach cards submit only fixed/general prompts through `MessengerScreen(initialPrompt: ...)`; this screen does not read the local journal to build those prompts.
- Confirmed `lib/services/health/auren_health_repository.dart` still provides Firestore read/write methods for `users/{uid}/healthCheckins`. It remains a possible remote data path for any other caller and has not been deleted or made consent-gated in this batch. Firestore owner-only rules are access control, not explicit sharing consent.
- The recursive tree confirms the health feature/store/tests, the Messenger screen, and the health repository are present. A repository tree lists paths, not call relationships or data values. GitHub code-search results in this environment resolve to the default branch rather than reliably targeting this feature branch, so those results were not treated as proof of branch-wide absence.
- **Audit outcome: partial, not a repository-wide privacy certification.** The direct landing-screen path to the fixed-value cloud check-in is removed; the local wellbeing screen/store remain separate from the cloud repository. Remaining work is to inspect all call sites of the health repository and indirect data flows through generic logging/analytics, shared AI/context builders, and Messenger. No claim is made that all health-related data in the whole app stays on-device.

## Follow-up data-flow findings (2026-10-21)

- Reviewed the branch versions of `lib/services/personal_ai/habit_service.dart`, `reminder_service.dart`, and `calendar_service.dart`. These are separate Firestore-backed general-purpose services under `users/{uid}/habits`, `users/{uid}/reminders`, and `users/{uid}/calendar_events`. They must not be described as local-only; users should avoid putting sensitive health details into those general cloud features unless they understand that the data is stored remotely.
- Reviewed `lib/services/messaging/message_repository.dart` and the send path in `lib/features/messenger/presentation/messenger_screen.dart`. A message is written to the conversation's Firestore messages collection before the AI request is made; for AI conversations the message text is also passed to the configured AI gateway. The AI gateway's server-side conversation-context behavior is not fully audited here. The local wellbeing journal is not automatically attached by the health landing-screen prompts, but anything a user manually types into an AI chat may be stored remotely and sent to the AI service.
- Reviewed `lib/services/ai/ai_gateway.dart`: the resilient gateway attempts the configured remote gateway and falls back to a local echo response only for selected transient infrastructure errors or missing endpoint state. This does not make ordinary successful AI conversations local-only.
- The AI Health Coach and other health prompt cards open Messenger with a prefilled general prompt and send it automatically through the existing initial-prompt flow. Because the prompt is general and does not include local journal records, this is not an automatic journal export; however, the user should be informed that AI chat messages are cloud-stored and may be sent to an AI provider.
- **Recommended next implementation:** add a clear, Arabic-first disclosure adjacent to the AI message composer (and ideally a one-time first-use acknowledgement) explaining that AI messages are stored in AUREN conversations and may be sent to the configured AI service, and advising users not to enter sensitive medical details unless they choose to share them. Add widget tests proving the notice appears in AI conversations but does not unnecessarily appear in ordinary person-to-person chats. This audit pass records the finding; it does not claim that the disclosure has been implemented.

