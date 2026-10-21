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

1. **Appointment drafts (draft-only):** The domain model validates required fields, time ranges, past dates, bounded notes, and legal lifecycle transitions. This batch adds `AurenAppointmentDraftStore` for UID-scoped device-local persistence and rejects terminal-state reopening. It still does not contact providers or claim that a booking is confirmed.
2. **Home Essentials (inventory/restock foundation):** Added household item validation, threshold-based low-stock detection, and deterministic restock-list sorting. A local stock movement policy supports restock/consumption adjustments while rejecting mismatched item IDs, invalid amounts, overflow, and stock going below zero. Ledger replay sorts movements by timestamp and then ID, rejects duplicate movement IDs, and validates the initial item even for an empty history. Same-timestamp ordering is explicitly covered by tests.
3. **Device-local inventory storage (new partial persistence slice):** Added `AurenHouseholdInventoryStore` using the existing `shared_preferences` dependency. Data is namespaced by the caller-supplied authenticated Firebase UID; items and movement history are encoded together in one preference value. It validates records on read/write, rejects blank UIDs, duplicate movement IDs, missing item IDs, invalid consumption, and preserves quantity when updating item metadata. This is local-device storage only, not encrypted storage, cloud sync, cross-device synchronization, or a transactional database. The caller must pass the authenticated Firebase UID only after authentication; this store does not independently verify Firebase identity. App data clearing/uninstall can remove the data.
4. **Household inventory screen (first user-facing slice):** Added an Arabic-first screen reachable from Discover. It lists items, flags low stock, adds/edits item metadata, records restock/consumption movements, and shows the five most recent movements per item. Existing item quantity is read-only in metadata editing so quantity changes go through the movement ledger. It requires a current authenticated UID and clearly discloses device-only storage. This is not cloud sync, encrypted storage, or automatic purchasing.
5. **Household maintenance log (partial):** Added validation, due-date ordering, estimate totals, and guarded status transitions, plus `AurenHouseholdMaintenanceStore` for UID-scoped device-local persistence. This is distinct from the generic reminder/calendar services; it does not hire providers or create external work orders.
6. **Trip itinerary planning (partial):** Added `AurenTripStop` validation, deterministic ordering, remaining-stop filtering, completion progress, and `AurenTripItineraryStore` persistence. It is planning/checklist data only; no transport, stay, tickets, or activities are booked.
7. **Home utility meter ledger (new partial system):** Added typed cumulative readings for electricity, water, gas, or other meters, per-meter ordering, latest-usage deltas, consistent-unit validation, and rejection of decreasing readings or duplicate timestamps. `AurenHomeUtilityReadingStore` persists readings locally by UID. It does not estimate bills without tariff data and does not connect to utility providers.
8. **Errands / service-request tracking (audit result):** Do not add a generic second task system yet. `DailyPlanService` already tracks ordered, completable tasks; `RoutineService`, `CalendarService`, and `ReminderService` cover scheduled personal activity; `AurenTransportService` covers ride requests; marketplace/order flows cover commerce; and `AurenSupplierRequestsRepository` covers supplier-contact/RFQ drafts. A separate generic errands queue would overlap these without a verified distinct user journey.

## Verification status

- Source added: yes.
- Domain/store automated tests authored: `test/services/everyday/appointment_draft_service_test.dart`, `test/services/everyday/household_inventory_service_test.dart`, `test/services/everyday/household_inventory_store_test.dart`, `test/services/everyday/trip_itinerary_service_test.dart`, and `test/services/everyday/household_maintenance_service_test.dart`.
- Inventory screen widget tests authored: `test/features/everyday_life/household_inventory_screen_test.dart` covers signed-out state, authenticated empty state, item creation, restock, consumption, and movement history rendering.
- Inventory store tests cover UID isolation, blank UID rejection, invalid item rejection, metadata updates preserving quantity, movement persistence, duplicate movement rejection, over-consumption, and missing-item rejection.
- Verification: GitHub Actions run `39559336881` on `feat/everyday-life-services-core-v2` completed successfully on 2026-10-21. All ten domain/storage test commands, the household inventory widget test, and targeted `flutter analyze lib/features/everyday_life lib/services/everyday` passed.
- Firestore persistence, owner authorization rules, cloud sync, and provider adapters: not implemented. Device-local preferences are not encrypted and must not be represented as cloud-backed or tamper-proof data.
- Therefore these are **partial foundations**, not completed production-ready systems.

## Next audit targets

1. Run targeted Flutter tests and analyze in CI for the new persistence/utility files; fix any confirmed failures before expanding the UI.
2. If cloud sync becomes necessary, review auth/repository conventions and explicit Firestore owner-only rules first; do not simply move this JSON schema to Firestore.
3. Keep this branch unmerged pending review.
4. Do not create a generic errands/service-request tracker unless a distinct workflow is demonstrated; prefer linking existing task, calendar, transport, commerce, and supplier records.
