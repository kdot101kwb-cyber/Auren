# AUREN Mobility & Transport — foundation v1

## Existing capability audit

The repository already has `lib/features/transport/presentation/transport_screen.dart`, a Discover entry for Transport, and `lib/services/transport/transport_service.dart` for ride requests. The existing ride-request service writes to Firestore and therefore remains unchanged in this advisory/local-first slice. Existing Journey & Mobility blueprint concepts (route planning, route preference, navigation, bike/scooter routes, charging routes and alternative routes) are explicitly out of scope to avoid duplication with Everyday Life & Services.

The repository's available numbered systems document groups Transport/Taxi with Travel, Stay and Offline Navigation. A separate canonical “Master Blueprint” file was not found at the expected `docs/AUREN_MASTER_BLUEPRINT.md` path on `main`; the implementation therefore records the observed repository evidence and the previously established blueprint route-planning exclusions rather than claiming a complete blueprint audit.

## Five bounded capabilities

1. **Public Transport Intelligence** — typed route/stop metadata. A route requires a named source and a user-entered observation date in `YYYY-MM-DD` format; the app does not silently substitute the current time for the observation date. No routes, stop sequences, fares, or departure times are invented.
2. **Vehicle Ownership** — validated local domain records for make/model/year, registration note, insurance expiry, maintenance due date and notes. The screen surfaces local insurance/maintenance attention flags, but does not upload document files, schedule operating-system notifications, or send reminders.
3. **Mobility Cost Planner** — deterministic estimate from user-entered distance, trip count, fuel consumption, fuel price, tolls, parking and other costs. Currency is mandatory; there is no exchange-rate lookup. Assumptions are shown.
4. **Freight & Cargo Coordination** — shipment reference, origin/destination, carrier label, status and delivery requirements. It records user-entered status only and does not contact carriers.
5. **Maritime & Port Intelligence** — port/country operational notes require a named source and a user-entered observation date in `YYYY-MM-DD` format before being described as sourced. No live port status or schedules are claimed.

## Safety, offline and cost boundaries

- Domain models have no network or Firebase dependency and can be used offline.
- No booking, payment, dispatch, external messaging, or binding commitment is initiated.
- Existing ride-request service and journey-planning surfaces are not modified.
- No paid package or external data provider is added.
- Routes, vehicles, shipment drafts and port notes are persisted on-device with `SharedPreferences` and reload after reopening the screen. This is offline local persistence only: there is no cloud sync, export/backup, encryption layer added here, or cross-device access. Do not use the registration field for highly sensitive identifiers until the app's storage/privacy policy is reviewed.
- Cost output is an estimate, not a quote. It excludes costs not supplied by the user and multiplies per-trip tolls/parking/other costs by the entered trip count.

## Validation plan

Focused unit tests cover source evidence gates, vehicle input/date flags, cost arithmetic and invalid values, shipment endpoint validation, port-source gating, and SharedPreferences round-trips for offline records. Widget tests cover the five workspaces, cost arithmetic, route-source validation, cargo status/requirements, and vehicle alerts. Flutter CI must run on the branch before this batch can be called green. No local test or build result is claimed from the repository connector session.
