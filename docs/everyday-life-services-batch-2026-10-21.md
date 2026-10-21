# AUREN Everyday Life & Services — Batch 2026-10-21

Branch: `feat/everyday-life-services-core-v2`.

## Five distinct outcomes

1. Household inventory/restock: existing Arabic-first screen, local store, movement history, and low-stock filter retained; no duplicate module created.
2. Appointment drafts: persisted locally with lifecycle guards; never creates or confirms a provider booking.
3. Household maintenance: persistent task/cost log, distinct from general reminders/calendar; no provider hiring.
4. Trip itinerary: persistent ordered stops and progress; no travel or accommodation booking.
5. Home utility meter ledger: cumulative readings and usage deltas; rejects decreasing readings and unit changes; does not estimate bills without tariff data.

## Files added

- `lib/services/everyday/uid_scoped_json_list_store.dart`
- `lib/services/everyday/appointment_draft_store.dart`
- `lib/services/everyday/household_maintenance_store.dart`
- `lib/services/everyday/journey_itinerary_store.dart`
- `lib/services/everyday/home_utility_ledger_service.dart`
- `lib/services/everyday/home_utility_reading_store.dart`

## Tests added

- `test/services/everyday/appointment_draft_store_test.dart`
- `test/services/everyday/household_maintenance_store_test.dart`
- `test/services/everyday/journey_itinerary_store_test.dart`
- `test/services/everyday/home_utility_ledger_service_test.dart`
- `test/services/everyday/home_utility_reading_store_test.dart`

The Everyday CI workflow now includes these tests and runs on this branch.

## Security and limits

Storage uses the existing `shared_preferences` dependency and namespaces data by a caller-supplied authenticated Firebase UID. This is device-local, not encrypted, tamper-proof, cloud-synced, or server-authorized. The caller must use the current authenticated UID. Clearing app data or uninstalling can remove records. No external provider, booking, payment, transfer, or purchase action was added.

## Blueprint / overlap review

The canonical Master Blueprint markdown was not located in the repository or library search. Review used the Master Feature Registry Dashboard image, the duplicate/overlap audit, the current Everyday audit, actual repository services/screens/tests, and Discover routing. The dashboard's historic counts are not treated as authoritative. Generic errands were rejected as duplicate work because DailyPlan, Routine, Calendar, Reminder, Transport, marketplace/order, and supplier-request flows already exist.

## Completion state

- Implemented: four new persistence/ledger APIs and their tests; CI coverage added.
- Partial: appointment, maintenance, itinerary, and utility are service/store-level; dedicated screens/navigation for them remain future work. Household inventory remains the only user-facing screen in this slice.
- Verified: GitHub Actions run `39559336881` completed successfully on 2026-10-21. All ten domain/storage test commands, the household inventory screen widget tests, and targeted analyze passed.
- Not done: PR, merge, deployment, cloud sync, or external actions.