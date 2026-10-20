# AUREN Knowledge & Information Ecosystem v1

## Scope and de-duplication

This batch reuses existing foundations instead of rebuilding adjacent systems:
- Education/Learning already has course discovery, saved courses, enrollment/progress, and a daily learning-plan foundation; it is not duplicated here.
- Event discovery and research/library search already exist in the Functions layer.
- The existing AI gateway already has translation intent handling; Language Bridge now adds a direct, bounded translation action for the knowledge workspace.

The five capabilities delivered in this batch are:

1. **Knowledge Hub / Knowledge Inbox** — save a note or source URL with bounded tags and provenance.
2. **Research Desk / Evidence Vault** — store a claim separately from source URLs and keep the initial verdict explicitly `unverified`.
3. **Source Provenance** — save publisher/source type and user notes without asserting the source has been independently verified.
4. **Research Reading Queue** — save a source, track `to_read` / `reading` / `read`, change priority, and remove entries. Updates preserve the original `createdAt`.
5. **Language Bridge** — preserve user-curated terminology with context and alternatives, and request a provider-backed translation with source/target language, optional context, bounded input, and a controlled unavailable response.

## Implementation map

- `functions/knowledge_information_ecosystem.js` — authenticated user-scoped callables and bounded list operations.
- `functions/knowledge_information_validation.js` — reusable text, URL, list, and enum validation.
- `functions/knowledge_information_validation.test.js` — pure Node tests for validation.
- `functions/knowledge_information_ecosystem.test.js` — callable wiring, user scoping, UI adapter, and contract checks.
- `functions/index.js` — provider-backed `translateAurenText` callable using existing configured provider adapters.
- `functions/package.json` — runs the new validation and contract tests in the Functions CI job.
- `lib/services/knowledge/knowledge_information_service.dart` — client adapter and early validation.
- `lib/features/knowledge/presentation/knowledge_information_screen.dart` — six tabs: knowledge, evidence, sources, reading, glossary, and translation. The reading queue includes status and removal actions.
- `test/services/knowledge/knowledge_information_service_test.dart` — Flutter unit tests for URL and text validation.
- `lib/features/culture/presentation/culture_news_screen.dart` — entry point for the Knowledge workspace.

## Security and limits

- All callable writes require authentication and are scoped below `users/{uid}`.
- Inputs and list sizes are bounded.
- URLs must be HTTP(S), have a host, and must not embed credentials.
- Evidence is not automatically marked verified; source profiles start as `not_checked`.
- Translation requires an authenticated user and a configured AI provider secret. Translation is not available when every configured provider is missing or unavailable.
- No Firestore rules were changed, and no deployment or production data mutation was performed.

## Validation status

Automated tests were added to CI, but the latest head must report fresh CI results before this batch can be marked green. Emulator-backed authorization tests, deployed provider configuration, and full end-to-end device validation remain outstanding.
