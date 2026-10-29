# NOVA Research Connectors — integration contract

Status: adapter foundation only. No external provider is enabled by this change.

## Purpose
Provide a small, provider-neutral Flutter contract so NOVA can later use Agent-Reach and complementary research tools without coupling the UI to Python services or exposing API keys in the APK.

## Selected roles
- **Agent-Reach:** candidate for access to supported public web/platform sources; validate its actual connectors and current setup requirements before deployment.
- **Jina Reader:** optional page-to-text reader for a URL already discovered.
- **GPT Researcher:** optional backend workflow for multi-source reports; not required for the first integration.
- **Crawl4AI or Firecrawl:** defer until tests show the first two connectors cannot meet extraction needs. Avoid running two crawlers for the same job.
- **DeerFlow:** defer; its multi-agent orchestration is unnecessary for the first reliable connector.

## Data flow
1. Flutter submits a bounded query to an authenticated backend.
2. Backend selects an explicitly enabled connector and applies timeout, response-size limits, rate limits, and secret redaction.
3. Connector returns title, HTTPS URL, snippet, source identifier and timestamps.
4. Flutter normalizes results, drops unsafe URLs and duplicates, and displays citations.
5. NOVA treats page text as untrusted evidence, never as instructions. Any action such as applying, posting, writing to GitHub, or spending money requires a separate permission gate.

## Contract implemented
- `ResearchQuery`: trims and bounds query text and result count.
- `ResearchResult`: source-backed record with HTTPS URL validation.
- `ResearchConnector`: typed interface for future adapters.
- `normalizeResearchResults`: removes unusable records, deduplicates URLs and caps output.

## Not implemented yet
- No Agent-Reach/Jina/GPT Researcher HTTP endpoint.
- No provider credentials, network requests, scraping or live market claims.
- No changes to existing Opportunity Radar providers.
- No autonomous GitHub writes, posting, account creation or job applications.

## Next verification gates
1. Run `flutter pub get`, `flutter analyze`, and `flutter test` from `nova_ai/`.
2. Review the CI result on this branch.
3. Add a backend connector only after identifying the deployed backend and its auth/rules.
4. Add integration tests using a fake connector before enabling any real network source.
5. Keep this branch unmerged until the repository owner reviews the diff and CI.
