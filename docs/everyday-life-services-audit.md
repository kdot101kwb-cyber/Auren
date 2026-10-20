# AUREN Everyday Life & Services — initial audit and implementation slice

Date: 2026-10-20
Repository baseline: `main` at `c9167bcc83bbfc6fe18bcc94878f6b4580344507`.
Working branch: `feat/everyday-life-services`.

## Audit findings (initial, repository evidence)

- **Local Discovery:** do not rebuild blindly. The repo has Local Intelligence and related discovery systems (for example `lib/services/local/local_intelligence_service.dart`, `lib/services/social/adaptive_discovery_service.dart`) and a roadmap item for Local Intelligence.
- **Personal Organization:** an existing foundation exists in `lib/services/personal_ai/auto_organize_service.dart` and `lib/features/personal_ai/presentation/auto_organize_screen.dart`. Treat it as reuse/integration work, not a new system.
- **Appointments & Booking:** no appointment-specific service was found in repository code search. Existing stay listings/bookings are a separate accommodation domain; they are not general appointments.
- **Home Management:** no dedicated home-management system was found in the initial search. The roadmap includes Food / Home Essentials, which must be checked before choosing a final scope.
- **Travel Companion:** a Travel system is already listed in `docs/AUREN_47_SYSTEMS_10_BATCHES.md`; avoid creating a duplicate travel shell. Trip itinerary functionality requires a deeper audit before selection.

## Initial implementation slice

Added a pure, UI-independent appointment draft model and lifecycle policy. It validates required fields, time ranges, past dates, bounded notes, and legal status transitions. It explicitly does not contact providers or claim that a booking is confirmed.

## Verification status

- Source added: yes.
- Automated tests authored: yes, in `test/services/everyday/appointment_draft_service_test.dart`.
- Tests executed in this environment: no; the GitHub connector cannot run Flutter locally.
- Firestore persistence, owner authorization rules, UI, and provider adapters: not implemented in this slice.
- Therefore this is a **partial foundation**, not a completed appointment system.

## Next audit targets

1. Inspect Travel, Stay/booking, Food/Home Essentials, Transport, and offline-navigation implementations.
2. Confirm current auth/repository conventions and explicit Firestore rules before adding persistence.
3. Select the remaining non-duplicate systems only after that inspection.
4. Run targeted Flutter tests and analyze in CI; keep this branch unmerged pending review.
