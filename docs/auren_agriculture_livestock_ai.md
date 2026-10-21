# AUREN Agriculture & Livestock AI — implementation notes

## Repository review
The repository already has an AgriTech screen, agriculture repository, agriculture AI callable, GAEZ and market-price intelligence, producer-price and forecast services, plus agriculture contract tests. This branch extends that foundation rather than creating a second dashboard or duplicating household inventory or daily-life notebooks.

The repository tree search did not identify a clearly named Master Blueprint file; therefore this change is grounded in actual code and tests inspected, not a claim that a Master Blueprint was located.

## Systems addressed
1. Crop Advisor: offline-safe general crop checklist requiring crop, growth stage and observations; avoids diagnosis and chemical dosage.
2. Livestock Care: validated observation logs, optional next-check time and veterinary-review flag; no animal diagnosis.
3. Farm Operations: task model, status tracking and overdue detection.
4. Agricultural Market Intelligence: observations require date, currency/unit and traceable source name/reference. No fabricated prices are seeded.
5. Farm Resource Planner: offline quantity/availability planning and shortage calculation, without invented unit costs.

## Integration and limitations
The existing agriculture repository remains the Firestore/AI integration point. The new domain helper is dependency-free so draft planning can work offline and callers can add persistence incrementally. The crop checklist, resource-shortage calculator, farm task planner, farm task status manager, and livestock care-log form are exposed from the existing AgriTech quick-tools panel. The task planner saves owner-scoped task records in the existing `users/{uid}/agricultureNotes` collection using the already-supported `farm` note type, reads them back for the task summary, and supports status updates. Farm tasks can be marked planned, in progress, done, or skipped through the status manager. Livestock care observations are saved as owner-scoped notes with an optional follow-up date and veterinary-review flag; a follow-up view lists observations and marks follow-ups due based on the saved date. Existing livestock records, feed plans, and schedules remain in their separate dashboard/service. The new domain records are encoded inside the existing owner-scoped note schema rather than a new Firestore collection. These screens are not a push-notification system; users must open the app to view saved follow-ups. No new Firestore collection or rules expansion was introduced. No migration, rules deployment, external feed, paid API or release was performed.

## Validation
Tests added: `test/services/agriculture/farm_management_service_test.dart`. A recorded CircleCI status snapshot for commit `8890e147e1163f5ed095e6006e84053213efc58c` reports success for `flutter_ci`, `functions_tests`, `action_executor_tests`, `plugin_worker_tests`, and `plugin_worker_image`. This snapshot applies only to that commit; later changes require their own status checks. No local Flutter test run is claimed.
