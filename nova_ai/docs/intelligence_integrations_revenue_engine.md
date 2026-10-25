# NOVA Intelligence, Integrations, Speed and Revenue Engine

## Purpose and honest status
NOVA should gather authorized information from connected social accounts and public web sources, reason about opportunities, propose experiments, and track real revenue outcomes. This is an implementation blueprint, not a claim that APIs or account credentials are already connected. Every provider must have a visible connection/health state, tested scopes, timestamps, quotas, and cost.

## Recommended integration strategy
Do not search for one mythical API that grants unrestricted access to every platform. Use a provider adapter interface and select the best official API per action; optionally add a unified publishing provider to reduce integration work.

### Platform adapters
- **Facebook Pages + Instagram professional accounts:** Meta Graph API / Instagram API. OAuth, app review, Page/professional account eligibility and scopes apply. Do not imply personal Facebook-profile publishing support.
- **TikTok:** TikTok Content Posting API for authorized posting; read/research access depends on product, scopes and eligibility.
- **YouTube / Shorts:** YouTube Data API for uploads and resource metadata; YouTube Analytics API for authorized channel metrics. Enforce quota-aware batching.
- **X:** X API for authorized posting and allowed public/account data; check paid plan and endpoint-level limits before enabling polling.
- **LinkedIn:** LinkedIn APIs for the specific approved product and member/organization scopes; not all applications receive broad publishing access.
- **Pinterest, Threads, Telegram, Bluesky:** implement individual adapters only for documented supported operations and granted scopes. Telegram publishing requires a bot with appropriate channel permissions.
- **Optional unified publishing:** evaluate Buffer, Ayrshare, or Postiz against required channels, media types, analytics, comment handling, data retention, regional availability, plan limits and total cost. Choose only after a proof-of-connection and a test post on an authorized destination. An aggregator cannot bypass platform restrictions.

### Web research / information APIs
- Define a replaceable `WebSearchProvider` interface. Benchmark Brave Search, Exa, Tavily, Linkup, or a current low-cost/free tier on representative queries for source quality, latency, coverage, terms and price.
- Recommended starting posture: a low-cost provider for broad discovery plus direct official sources for verification; optional second provider only for high-value or conflicting claims. Cache normalized results with source URL, publication time, fetched time, confidence and expiry.
- Do not scrape behind logins, bypass access controls, or treat social analytics access as permission to collect private messages or other accounts' non-public data.

## Model/API routing
- Define a replaceable `LLMProvider` interface with model capability registry (reasoning, structured output, tool calling, multilingual quality, context, latency, pricing and region).
- Route simple tagging, deduplication and captions to a small/low-cost model; reserve stronger reasoning models for multi-source research, business decisions and code review.
- Allow an optional local model for offline drafting/classification where supported; when offline, clearly mark fresh market data as unavailable and queue sync jobs.
- Keep API keys and OAuth secrets server-side in a secrets manager. The Flutter APK must never contain provider secrets.
- Use request timeouts, retries with jitter, circuit breakers, idempotency keys, concurrency limits and provider fallbacks. Never silently switch to an unapproved paid provider.

## Fast data pipeline
1. Fetch independent sources concurrently under a bounded worker pool.
2. Normalize and deduplicate posts/metrics; respect platform freshness and retention rules.
3. Cache results by account, query and time window; refresh based on TTL and webhooks when available.
4. Store raw source metadata separately from derived summaries; every claim in a market brief links to its source and observed time.
5. Run cheap ranking first; send only top opportunities and compact evidence to the reasoning model.
6. Stream progress states to the client: queued, collecting, analyzing, recommendation-ready, failed or stale.
7. Track p50/p95 latency, errors, cost per run, token use, cache-hit rate, stale-data rate and provider health.

## Revenue / opportunity agent
The agent should optimize measured contribution margin, not just views or followers.

### Opportunity sources
- Find audience questions and recurring pain points from authorized comments, search trends, public discussions and the owner's own analytics.
- Score each opportunity: demand evidence, audience fit, competition, production effort, time-to-market, monetization path, platform fit, policy/IP risk and estimated cost.
- Suggest and compare practical routes: affiliate content (disclose sponsorship/affiliate links), digital products/templates, services/consulting, sponsorship leads, creator revenue programs where eligible, and qualified traffic to an owned landing page.
- For each idea produce: hypothesis, target audience, offer, content series, distribution plan, CTA, estimated cost range, leading metric, revenue metric, validation test and stop rule.
- Never invent revenue estimates or guarantee earnings. Label estimates as assumptions with confidence and show actual measured revenue separately.

### Experiments and feedback loop
- Create a weekly ranked backlog; test one variable at a time where practical (hook, format, CTA, offer, posting window).
- Use a holdout or comparable baseline when possible; wait for adequate sample size before claiming causality.
- Track funnel: reach → watch/engagement → clicks → leads → conversion → gross revenue → fees/costs → contribution margin.
- Pause campaigns that breach budget, policy, brand-safety or negative-return thresholds.
- No ad spend, purchases, DMs, replies, offers, or financial commitments without explicit owner-set limits and authorization.

## Controls and safe autonomy
- Owner-configured budget ceilings for model, search, storage and media generation; default paid spend is off.
- Separate switches for read analytics, read comments, publish, auto-reply, and run paid ads.
- Start in recommend/draft mode. Enable automatic publishing only for approved content classes and connected channels.
- Sensitive complaints, refunds, legal/medical issues, personal data and uncertain claims require human review.
- A global pause button stops new jobs; reconcile in-flight requests and show any action that could not be cancelled.
- Maintain audit records for source, model/provider, prompt/version, estimated and actual cost, approval, action result and revenue attribution.

## Build order
1. Provider interfaces, typed capability/permission registry, secure secret handling, telemetry and cost budgets.
2. Web research adapter + source-linked market brief + caching.
3. One social channel end-to-end: OAuth, analytics read, draft, approved test publish, status reconciliation.
4. Campaign queue, retry/idempotency, cross-post adaptations and dashboard health states.
5. Revenue opportunity scoring, link/campaign attribution, funnel and margin dashboard.
6. Add other channel adapters one by one only after permission, quota, content-format and failure tests pass.
7. Add bounded auto-replies and more autonomy after safety and audit tests pass.

## Acceptance criteria
- No provider/channel is shown as connected without a successful authorized health check.
- Every market claim has source/time or is explicitly marked as an inference.
- A failed publish is never shown as published; retries are idempotent.
- Paid API/model use is budgeted, logged and switchable; offline mode does not pretend to have current data.
- Every revenue recommendation includes a measurable validation plan; actual income is reported only from connected/verified evidence.
- CI tests permission-denied, expired-token, rate-limit, timeout, duplicate-job, partial-publish, stale-data and budget-exceeded cases.
