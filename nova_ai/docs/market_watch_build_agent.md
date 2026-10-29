# NOVA Market Watch & Build Agent

Status: implemented on feature branch for review; **not yet deployed**. This agent adds a scheduled market-signal scan and turns each candidate into a structured, research-backed build pack. It does not autonomously publish apps, buy domains, contact customers, spend money, or claim that a candidate is validated.

## What it watches

- Hacker News public Algolia search counts: last 7 complete UTC days compared with the preceding 7 days.
- GitHub public repository search: repositories created within the previous 90 days for each discovery theme.
- Six discovery lenses: small-business AI automation, offline-first mobile apps, creator production tools, coding-agent QA, niche micro-SaaS research, and digital setup for local businesses.

Source requests are bounded and time-limited. Failed sources are labelled unavailable; missing data is not replaced with invented values. Public counts are weak discovery signals, not proof of market size, demand, or willingness to pay.

## What it prepares

Each candidate receives a `research_pack_ready` record with:
- product hypothesis and target buyer;
- source-window counts and source links;
- MVP scope and proposed architecture;
- a zero-cost validation experiment;
- a monetization hypothesis and key risks;
- acceptance criteria, privacy/security/licensing checks, and release-readiness checklist.

`notYetBuilt: true` is intentional. A build pack is not a completed app. NOVA must still validate the problem, inspect competitors and licenses, obtain approval to start a build, generate code in an isolated worker, run tests, and pass Android QA before a product can be marked ready.

## Backend interfaces

- `getNovaMarketWatch`: authenticated callable; serves a cached scan for six hours and otherwise refreshes it.
- `runNovaMarketWatchDaily`: scheduled daily at 08:40 Africa/Khartoum.
- Firestore cache: `nova_market_watch/latest`.
- Test command: `node --check nova_market_watch_agent.js && node --test nova_market_watch_agent.test.js`.

## Required next steps

1. Run the NOVA Functions test suite and CI on this branch.
2. Review current platform/API terms, quotas, and data retention.
3. Deploy only to the intended staging Firebase project after approval.
4. Connect the Flutter Market Watch screen to `getNovaMarketWatch` and show last scan time, source failures, evidence confidence, ranked candidates, and build-pack details.
5. Add a human-approved lifecycle for `research_pack_ready -> validation -> approved_to_build -> building -> QA -> ready`; never skip tests or treat a generated brief as a finished app.
6. Before enabling scheduled scans in production, confirm Firebase billing/quota and scheduler configuration. Public APIs are unauthenticated and rate-limited; scan frequency must remain conservative.

## Scoring limits

The initial ranking is a simple, deterministic average of HN trend score and GitHub new-repository activity proxy. It is intentionally not described as an AI prediction. The ranking must not be used to promise revenue, invest money, or automatically purchase a domain. Future iterations should add alternative/competitor saturation, user pain evidence, payout eligibility, and small human-verified experiments before improving the score.