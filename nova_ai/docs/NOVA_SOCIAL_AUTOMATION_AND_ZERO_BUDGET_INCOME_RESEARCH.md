# NOVA Global Social Management & Zero-Budget Income Research

Date: 2026-10-26  
Status: research shortlist only; no external service has been connected or deployed.

## Objective

Find maintainable GitHub projects NOVA could use to manage the owner's social channels and build repeatable, low-cost income experiments. Priorities: zero upfront spend, official APIs, private operation, measurable outcomes, and reversible integration. Open source does not mean zero operating cost: hosting, AI inference, platform API access, domains, payment processing, and account approvals may still cost money.

## Shortlist: social media operations

| Priority | Project | Potential role | License / caution | Decision |
|---|---|---|---|---|
| 1 | https://github.com/brightbeanxyz/brightbean-studio | Multi-account content calendar, scheduling, publishing, monitoring; README advertises a hosted free version | AGPL-3.0. Verify current hosting limits, security, channel coverage, and OAuth behavior before connecting accounts | Test hosted option first; no spend |
| 2 | https://github.com/postmill-ai/postmill-app | AI-oriented social management, visual content tools, cross-channel calendar, analytics, comments, API/MCP and automation | AGPL-3.0; requires configured AI/media providers and social OAuth apps; no bundled AI credits | Strong feature candidate, but heavier stack and licensing review required |
| 3 | https://github.com/gitroomhq/postiz-app | Established social scheduling and analytics platform with broad channel support | AGPL-3.0; self-hosting requires infrastructure and platform developer apps | Compare against Postmill; do not run both in production initially |
| 4 | https://github.com/inovector/mixpost | Self-hosted publishing/calendar and analytics | MIT for Lite repository; some advanced capabilities are in commercial Pro product; requires server and platform credentials | Lightweight alternative if its supported channels meet needs |
| 5 | https://github.com/n8n-io/n8n | Orchestrate RSS/trend research, content drafts, approvals, reports, and API calls | Sustainable Use License (fair-code), not OSI open source; self-hosting still needs a machine and secure configuration | Use as automation glue only after license/hosting review |

## Shortlist: general-purpose agent and coding projects

- https://github.com/openclaw/openclaw — MIT-licensed personal assistant/gateway; study task routing and tool integration. Model/API costs and secure deployment remain separate.
- https://github.com/All-Hands-AI/OpenHands — coding agent candidate; sandboxing, model requirements, and runtime costs must be assessed before any integration.
- https://github.com/langchain-ai/langgraph — stateful agent orchestration library; useful architecture reference, not a complete always-on hosted worker by itself.

## Income pathways to test (not guaranteed earnings)

### A. Content-led affiliate income
1. Pick one focused niche with real buyer intent (e.g. practical AI tools for small businesses).
2. Publish useful original tutorials, comparisons, and short demonstrations on YouTube/Instagram/TikTok and a searchable home base.
3. Add disclosed affiliate links only after joining legitimate programs that accept the owner's country/payment method.
4. Track clicks, qualified leads, conversion, refunds, and net earnings; stop topics that show no signal after a defined test window.
5. Never fabricate reviews, spam comments/DMs, or mass-publish near-duplicate AI content.

### B. Sell a small digital product or service
Build one practical deliverable using existing skills/tools: templates, content calendars, short-video editing, simple websites, AI workflow setup, or social-media reporting. Validate demand with a sample and a few real prospects before building a large product. Collect payment only through services available in the owner's jurisdiction.

### C. Productized social-media service
Offer a clearly scoped package (for example, 12 edited posts plus a monthly performance report) to a small number of local or online businesses. NOVA can draft, schedule, and report, but a human must approve brand claims, client-facing messages, and publishing until adapters are verified.

### D. Small niche site / newsletter
Create original guides and a mailing list around one subject, then test sponsorships, affiliate offers, or paid resources after audience traction. Avoid relying on ad networks until country eligibility and payout methods are confirmed.

### E. Micro-SaaS / automation setup
Use n8n or a small custom backend to solve one repetitive business task, then charge for setup/support only after customer validation. Do not assume n8n's license permits every resale/hosted-service model; review current terms first.


## NOVA income-platform catalog (50 candidates)

The server-side daily revenue prompt now includes the owner-supplied 50-platform list in `functions/nova_income_platform_catalog.js` and asks NOVA to rank only the best 5–10 candidates for the current user. It must treat the list as a research shortlist, not verified eligibility or an income forecast.

- Prioritize $0 startup cost and direct client services while payment access is being verified.
- Before recommending a marketplace or creator program, check official current rules for Sudan, identity/tax requirements, payout provider, fees, proposal/task limits, and program availability.
- Label unknown eligibility as **UNVERIFIED**; exclude options requiring upfront fees from the immediate plan. Shopify, Etsy listing fees, Chrome Web Store registration, paid plans, and production/hosting costs are not presumed free.
- Separate client-acquisition channels (e.g. LinkedIn) from platforms that pay creators directly.
- Do not assume TikTok monetization thresholds, country support, or payout availability from generic social posts; confirm official rules.
- The catalog is not proof that any account is accepted, that work is available, or that payment can be received. No applications, messages, listings, or publishing are executed by adding this catalog.

## Proposed NOVA workflow

1. Daily research queue: collect public trends, relevant questions, and potential customer problems.
2. Score opportunities by audience fit, evidence of demand, effort, payout feasibility, and policy/licensing risk.
3. Create a weekly content batch: one source article/tutorial, then platform-specific adaptations and short-video outlines.
4. Require approval before first-time publishing, affiliate claims, pricing, financial claims, or direct outreach.
5. Use an official platform adapter and verified scopes for every publish action; fail closed when auth/scope is missing.
6. Store evidence for each action: source URLs, draft version, approval, publish response, post URL, analytics snapshot, and any cost.
7. Weekly review: clicks, watch time, qualified leads, conversion, revenue, spend, and next experiment. No claim of income without recorded payout evidence.

## Hard constraints

- Budget assumption: USD 0 upfront; no paid plan, API credits, or new infrastructure without explicit approval.
- Do not embed secrets in Flutter/APK, commits, logs, or public workflows. Store credentials only in an approved secret store.
- Do not bypass platform limits, scrape private data, automate spam, buy engagement, or send bulk unsolicited messages.
- Keep the existing social policy fail-closed: publishing remains disabled until an authorized adapter, OAuth authorization, publish scope, owner enablement, and any cost approval are verified.
- Do not merge third-party code before license review, dependency/security review, a sandbox trial, and CI tests.
- A phone app alone cannot run continuously while powered off. Always-on behavior requires an actually deployed worker/host and reliable queue/scheduler; this document does not create one.

## Next evaluation gates

1. Verify BrightBean's free-hosted limits and supported channels using its official documentation; test with a non-critical account or draft-only mode.
2. Compare Postmill vs Postiz install footprint, supported networks, API/MCP quality, license implications, and minimum resource needs.
3. Inspect security posture, dependencies, recent releases, backup/export, and OAuth token handling.
4. Choose one candidate for a disposable sandbox. No production integration until it passes the gates above.
5. Separately validate one income experiment with no spend before expanding automation.

## Primary project links

- BrightBean Studio: https://github.com/brightbeanxyz/brightbean-studio
- Postmill AI: https://github.com/postmill-ai/postmill-app
- Postiz: https://github.com/gitroomhq/postiz-app
- Mixpost: https://github.com/inovector/mixpost
- n8n: https://github.com/n8n-io/n8n
- OpenClaw: https://github.com/openclaw/openclaw
- OpenHands: https://github.com/All-Hands-AI/OpenHands
- LangGraph: https://github.com/langchain-ai/langgraph
