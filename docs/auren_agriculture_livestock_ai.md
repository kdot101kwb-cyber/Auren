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
The existing agriculture repository remains the Firestore/AI integration point. The new domain helper is dependency-free so draft planning can work offline and callers can add persistence incrementally. The crop checklist and resource-shortage calculator are now exposed from the existing AgriTech quick-tools panel. Livestock animal records, feed plans, and pending schedules already have a separate dashboard/service. The new domain records are not yet persisted as their own Firestore collections, and farm-operation tasks still need a dedicated persisted task workflow. No migration, rules deployment, external feed, paid API or release was performed.

## Validation
Tests added: `test/services/agriculture/farm_management_service_test.dart`. CI checks for the latest UI integration commit were still pending at the time of this note; do not treat them as passed until the actual run completes. No local Flutter test run is claimed.
