# AUREN Information Intelligence Tools v1

This batch was selected after checking the existing system map and open work. It deliberately avoids rebuilding the Education foundation, event discovery, research/library search, Knowledge Hub, Research Desk, Language Bridge glossary, Source Registry, and Knowledge Notebook that are already represented in the repository or open PRs.

## Five distinct tools added

1. **Citation Export Studio** — formats a user-provided source record as APA 7, MLA 9, Chicago, BibTeX, or RIS. URL schemes and embedded credentials are validated. Generated citations still require human review; the tool does not claim bibliographic metadata has been independently verified.
2. **Topic Watchlist** — saves a local list of topics and checks user-provided titles/summaries for case-insensitive matches. It does not yet subscribe to feeds or send background alerts.
3. **Source Freshness Radar** — records a user's last review date and classifies the source as fresh, due for review, stale, or unknown. This is a reminder signal, not a trust score or fact-check.
4. **Offline Knowledge Pack Planner** — validates selected knowledge entries and creates a bounded JSON manifest with a UTF-8 byte estimate. It does not download or cache remote content; that remains a follow-up integration with the existing offline/cache layer.
5. **Knowledge Revision Ledger** — compares a baseline text with a current version and lists added/removed lines. The baseline is stored locally on the device; cloud sync and full version restoration are not implemented.

## Integration

- Service logic: `lib/services/information/auren_information_intelligence_service.dart`
- Interactive UI: `lib/features/information/presentation/auren_information_intelligence_screen.dart`
- Entry point: Culture & News screen
- Tests: `test/services/information/auren_information_intelligence_service_test.dart`

## Data and safety boundaries

Topic watchlists, source review records, and revision baselines are device-local via SharedPreferences. No Firestore rules or production data were changed. Offline pack output is a manifest only, not a download. The topic matcher scans only the text supplied by the user.

## Validation

Unit tests cover citation formatting and unsafe URLs, topic matching, freshness thresholds, manifest bounds/duplicate IDs, and revision differences. The latest CI/device results must be checked before claiming the batch is green.
