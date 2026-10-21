# AUREN Business & Economy — MVP

Status: implementation on `feat/auren-business-economy-mvp`; not merged or released.

## Existing foundations reused
- **Local Business OS:** `AurenBusinessScreen` and `BusinessRepository` already support business records and public discovery.
- **Business Discovery:** reuses the curated supplier/business source directory. Listings and external sources are not endorsements.
- **Trade & Export Hub:** reuses Business Navigator and the local-only trade opportunity draft tracker.
- The existing supplier offer comparison workflow remains separate and unchanged.

## Added in this batch
- **Business & Economy hub:** one entry point to the five business capabilities.
- **Buyer–Seller Matching:** an on-device matching brief with advisory term/category/location scoring. It does not publish a request or contact either party.
- **Business Growth Planner:** a lightweight on-device plan for a goal, customer group, and next action.
- Pure logic tests for matching score bounds, missing inputs, and growth-step normalization.

## Safety and data boundaries
- Matching briefs and growth plans use SharedPreferences on the device; they are not synced or backed up by this feature.
- Matching scores are heuristic hints only, not a verified suitability, credit, legal, export, or quality assessment.
- No payment, transfer, purchase, RFQ, message, contract, or external trade action is triggered by these new screens.
- Users should independently verify business identity, licences, product quality, and applicable import/export rules.

## Verification
- Run `flutter test test/features/business_economy/business_economy_logic_test.dart`.
- Run `flutter analyze` and the repository's CI workflows before treating this batch as validated.
- No PR, merge, or deployment is part of this batch.
