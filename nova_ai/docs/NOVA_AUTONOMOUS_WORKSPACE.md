# NOVA Autonomous Workspace & Market Radar

## Goal
NOVA is AUREN's dedicated research and build workspace. It should use the existing repository, project documentation, tests, issue/PR history, and approved ideas as its working context rather than inventing project state.

## Workstreams
1. **AUREN project knowledge** — index architecture, modules, roadmap, open issues, PRs, CI failures, and accepted product decisions. Keep links and timestamps so every claim is traceable.
2. **Builder** — turn approved ideas into scoped tickets and branches; make small, reviewable changes; run formatter, analyzer, unit/widget tests, and build checks; report exact commit, logs, and artifact links. Never claim completion based only on a UI state.
3. **Market radar** — run a scheduled public-feed scan daily, label headlines as weak signals, deduplicate, and produce a report for human review. A feed scan is not market validation or investment advice.
4. **Dedicated workspace page** — show saved ideas/files, research reports, build jobs, CI status, artifacts, and blockers. Provide search/filter and explicit source links.
5. **Background orchestration** — use server-side scheduled jobs and a persistent job queue. Mobile background execution is not reliable as an always-on scheduler. The app should display last run, next run, failures, and stale-data warnings.
6. **Governance** — read-only by default; build on isolated branches; tests and security checks required; never expose tokens in the app; require approval before merging, publishing, spending money, or executing trades.

## First implementation slice
- `.github/workflows/nova-market-radar.yml`: daily scheduled workflow plus manual dispatch.
- `.github/scripts/nova_market_radar.py`: collects public RSS headlines, tags them by topic, and writes a Markdown digest as a downloadable workflow artifact.
- The initial radar is deliberately evidence-limited: no paid data API, no LLM-generated conclusions, no live stock quotes, and no automatic financial transactions.

## Required follow-up before calling NOVA autonomous
- Add a secure server-side integration that stores reports and job states for the app to read.
- Add repository/roadmap/CI indexing with source references and safe access controls.
- Implement the dedicated workspace UI and connect it to the persistent data layer.
- Configure Firebase project values, App Check, auth rules, callable functions, and scheduled-function deployment.
- Add tests for source failures, duplicate items, stale reports, authorization, and job retries.
- Verify a real Android APK build and install test; this PR alone does not prove a production-ready app.
