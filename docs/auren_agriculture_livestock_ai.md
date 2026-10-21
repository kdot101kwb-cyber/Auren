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
The existing agriculture repository remains the Firestore/AI integration point. The new domain helper is dependency-free so draft planning can work offline and callers can add persistence incrementally. These records are not yet wired into a new screen or Firestore collections in this commit; no migration, rules deployment, external feed, paid API or release was performed.

## Validation
Run flutter test test/services/agriculture/farm_management_service_test.dart and flutter analyze. Results must be recorded from CI after the branch push; no test success is claimed by this document.
