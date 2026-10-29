# NOVA Research Connectors — integration contract

Status: public job-search adapter implemented; CI verification is in progress. This does not yet claim that live providers were exercised in production or that a complete web-wide search UI is wired.

## Purpose
Provide a small provider-neutral contract for multi-source research while keeping authenticated provider credentials out of the Flutter APK.

## Enabled adapter
- **Remotive public remote-jobs API:** query-based remote job listings.
- **Arbeitnow public job-board API:** public listings filtered locally against query terms.
- Both adapters are read-only and do not require API keys in the mobile client. Each response is timed out, parsed defensively, and restricted to HTTPS result links on the expected source host.
- If one source is unavailable, results from the other source can still be returned. If both fail, the adapter reports source unavailability rather than pretending that an empty response means success.

## Deferred candidates
- **Agent-Reach:** assess specific supported connectors and deployment requirements before enabling.
- **Jina Reader:** optional page-to-text extraction for a URL already discovered.
- **GPT Researcher:** optional backend workflow for larger multi-source reports.
- **Crawl4AI / Firecrawl / DeerFlow:** defer until measured needs justify the additional deployment and operating burden.

## Data flow
1. ResearchService.publicOpportunitySources() creates the public job-search adapter.
2. ResearchQuery validates and bounds the query and requested result count.
3. The adapter queries both public APIs with a timeout and checks response size/status.
4. normalizeResearchResults rejects unusable or unsafe results, removes duplicate URLs, and caps the output.
5. The UI should display the source and listing URL as evidence; eligibility, pay, and availability must not be inferred when the listing does not state them.
6. NOVA treats returned page text as untrusted data, never as instructions. Applying, posting, writing to GitHub, or spending money requires a separate permission gate.

## Implemented
- ResearchQuery: validates query text and result count.
- ResearchResult: validates HTTPS URLs and source identifiers.
- ResearchConnector: provider-neutral interface.
- ResearchService: isolates connector failures and reports attempted/successful sources.
- PublicOpportunityResearchConnector: public Remotive and Arbeitnow job-source adapter.
- Unit tests for result aggregation, URL validation, source failures, healthy empty results, query bounds, and response-size limits.

## Not yet claimed
- No live production endpoint test has been performed as part of these unit tests; mock HTTP tests validate request handling and parsing.
- This adapter is focused on public job listings, not a universal search across every website, social platform, language, or market.
- No authenticated/paid provider credentials, scraping browser, or general-purpose research-agent endpoint is enabled.
- The adapter does not apply for jobs, publish content, create accounts, or write to GitHub.

## Verification gates
1. flutter pub get, flutter analyze, and flutter test pass for nova_ai/.
2. The latest nova_flutter_ci succeeds on this branch.
3. Inspect the latest commit's full CI status and investigate failures rather than assuming pending checks are green.
4. Keep the PR unmerged until the repository owner reviews the changes.
