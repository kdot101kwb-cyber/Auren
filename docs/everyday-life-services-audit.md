# AUREN Everyday Life & Services — initial audit and implementation slice

Date: 2026-10-20
Repository baseline: `main` at `c9167bcc83bbfc6fe18bcc94878f6b4580344507`.
Working branch: `feat/everyday-life-services`.

## Audit findings (repository evidence)

- **Local Discovery:** do not rebuild blindly. The repo has Local Intelligence and related discovery systems (for example `lib/services/local/local_intelligence_service.dart`, `lib/services/social/adaptive_discovery_service.dart`) and a roadmap item for Local Intelligence.
- **Personal Organization:** an existing foundation exists in `lib/services/personal_ai/auto_organize_service.dart` and `lib/features/personal_ai/presentation/auto_organize_screen.dart`. Treat it as reuse/integration work, not a new system.
- **Appointments & Booking:** no appointment-specific service was found in repository code search. Existing stay listings/bookings are a separate accommodation domain; they are not general appointments.
- **Home Management:** no dedicated home-management system was found in the initial search. The roadmap includes Food / Home Essentials, which must be checked before choosing a final scope.
- **Travel Companion:** a Travel system is already listed in `docs/AUREN_47_SYSTEMS_10_BATCHES.md`; avoid creating a duplicate travel shell. Trip itinerary was not found in the initial code search; a planning-only itinerary helper has now been added as a subflow, not a new Travel shell.
- **Food / Stay / Transport:** existing Firestore-backed services cover food listings, accommodation listings/bookings, and ride requests. New work in this branch stays in local household planning and does not duplicate those provider-facing flows.

## Initial implementation slices

1. **Appointment & Booking (draft-only foundation):** Added a pure, UI-independent appointment draft model and lifecycle policy. It validates required fields, time ranges, past dates, bounded notes, and legal status transitions. It does not contact providers or claim that a booking is confirmed.
2. **Home Essentials (inventory/restock foundation):** Added household item validation, threshold-based low-stock detection, and deterministic restock-list sorting. A local stock movement policy now supports restock/consumption adjustments while rejecting mismatched item IDs, invalid amounts, overflow, and stock going below zero. It does not persist inventory, place orders, or claim supplier availability.
3. **Household maintenance planning (partial foundation):** Added maintenance-task validation, active-task ordering by due date, estimate totals, and guarded status transitions. This is a maintenance work log/planning model, not a reminder scheduler; it does not hire providers or persist records.
4. **Trip itinerary planning (partial foundation):** Added `AurenTripStop` validation, deterministic stop ordering, remaining-stop filtering, and completion progress. It does not book anything or persist trips.
5. **Errands / service-request tracking (audit result):** Do not add a generic second task system yet. `DailyPlanService` already tracks ordered, completable tasks; `RoutineService`, `CalendarService`, and `ReminderService` cover scheduled personal activity; `AurenTransportService` covers ride requests; marketplace/order flows cover commerce; and `AurenSupplierRequestsRepository` covers supplier-contact/RFQ drafts. A separate generic errands queue would overlap these without a verified distinct user journey.

## Verification status

- Source added: yes.
- Automated tests authored: yes, in `test/services/everyday/appointment_draft_service_test.dart`, `test/services/everyday/household_inventory_service_test.dart`, `test/services/everyday/trip_itinerary_service_test.dart`, and `test/services/everyday/household_maintenance_service_test.dart`.
- Tests executed in this environment: no; the GitHub connector cannot run Flutter locally.
- Firestore persistence, owner authorization rules, UI, and provider adapters: not implemented in these slices.
- Therefore these are **partial foundations**, not completed user-facing systems.

## Next audit targets

1. Inspect auth/repository conventions and explicit Firestore rules before adding persistence.
2. Integrate these domain models into an existing UI only after checking the current feature navigation and tests.
3. Do not create a generic errands/service-request tracker unless a distinct workflow is demonstrated; prefer linking existing task, calendar, transport, commerce, and supplier records.
4. Run targeted Flutter tests and analyze in CI; keep this branch unmerged pending review.
