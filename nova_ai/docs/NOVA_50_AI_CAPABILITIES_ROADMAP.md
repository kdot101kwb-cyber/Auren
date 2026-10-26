# NOVA — 50 AI Capability Roadmap
Date: 2026-10-26
Branch: feat/nova-ai-android-app

## Product rule
NOVA must distinguish **planned**, **running**, **succeeded**, and **failed** work. It must never claim success without evidence. Prefer free/open-source and local-first options; do not activate paid services or spend credits without explicit approval. Secrets must stay out of source code, logs, and APKs.

## 50 features

### A. Knowledge and reasoning
1. **Verified web research** — gather current information from multiple sources, cite sources and publication dates, and flag conflicts.
2. **Source reliability scoring** — label official documentation, primary research, reputable reporting, community posts, and unverified claims separately.
3. **Knowledge notebook** — save user-approved facts, project decisions, links, and notes with dates and provenance.
4. **Freshness monitoring** — mark information as potentially stale and schedule rechecks for fast-changing topics.
5. **Arabic/Sudanese language mode** — understand Sudanese Arabic and switch between colloquial Arabic, Modern Standard Arabic, and English when useful.
6. **Structured task decomposition** — turn a goal into small steps, dependencies, acceptance checks, and a completion definition.
7. **Decision log** — record important decisions, why they were made, and what evidence would justify changing them.
8. **Uncertainty and assumption labels** — explicitly distinguish known facts, estimates, hypotheses, and missing information.
9. **Cross-project memory with consent** — retrieve relevant project context without mixing unrelated projects or exposing sensitive details.
10. **Specialist workflows** — route coding, research, content, analytics, and finance tasks to separate checklists and tools.

### B. Execution and self-repair
11. **Action planner and queue** — maintain a prioritized backlog with status, owner/tool, deadline, and dependencies.
12. **Tool capability registry** — know which integrations are connected, their permissions, limits, and last successful use.
13. **GitHub issue-to-fix workflow** — inspect issue, reproduce, create a focused branch, implement a fix, and report changed files.
14. **Automated test gate** — run relevant unit/widget/integration tests and block a success status when required tests fail.
15. **CI failure diagnosis** — collect failing step logs, identify likely root causes, and propose or implement a minimal tested fix.
16. **Regression protection** — add a test for each confirmed bug before or alongside fixing it.
17. **Safe patch review** — inspect diffs for unintended changes, secrets, risky dependencies, and unrelated formatting churn.
18. **Build and artifact verification** — verify file existence, non-zero size, type, version, and required metadata before saying an artifact is ready.
19. **Rollback and recovery plan** — preserve known-good commits and explain recovery options before risky changes.
20. **Truthful progress reporting** — show queued/running/passed/failed/blocked states with evidence links; never fake green indicators.

### C. Monitoring and reliability
21. **Scheduled health checks** — periodically check configured repositories, CI workflows, APIs, and publishing connections where permitted.
22. **Failure alerts** — notify only on meaningful failures, repeated errors, or actionable changes; avoid noisy alerts.
23. **Dependency and security alerts** — identify outdated or vulnerable dependencies and propose safe upgrade PRs.
24. **Quota and rate-limit monitor** — track API limits and avoid loops that waste free quotas.
25. **Integration heartbeat** — report whether each connected service was last verified working, not merely connected.
26. **Data backup/export** — let the user export project notes, settings, and task history in portable formats.
27. **Audit trail** — record actions taken, timestamps, results, and links, while redacting credentials and private tokens.
28. **Privacy and secret scanner** — prevent API keys, wallet secrets, passwords, and personal tokens from entering commits or logs.
29. **Permission boundaries** — separate read-only, draft, and write permissions; ask before irreversible or external-facing actions.
30. **Recovery playbooks** — attach clear next steps to common CI, build, API, and publishing failures.

### D. Content and trend intelligence
31. **Trend radar** — monitor selected niches and platforms using available legitimate sources, with timestamped evidence.
32. **Trend velocity scoring** — rank topics by growth, freshness, audience fit, competition, and production effort.
33. **Audience question mining** — cluster public comments and search questions into real audience needs without exposing personal data.
34. **Competitor format analysis** — compare public titles, thumbnails, formats, posting cadence, and outlier performance where data is available.
35. **Originality and saturation check** — warn when a topic is overused and suggest a distinct angle rather than copying creators.
36. **Content opportunity backlog** — rank ideas by expected relevance, effort, evergreen value, and plausible monetization path.
37. **Hook and script workshop** — produce multiple opening hooks, short scripts, calls to action, and platform-specific variants.
38. **Title/thumbnail testing plan** — generate distinct packaging options and define measurable comparison criteria; do not claim a winner without data.
39. **Multiformat repurposing** — turn one approved idea into Shorts/Reels/TikTok, X posts, and longer-video outlines with platform-appropriate edits.
40. **Trend expiry and evergreen balance** — distinguish short-lived trends from durable search topics and plan a balanced content mix.

### E. Publishing, analytics, and income
41. **Editorial calendar** — schedule realistic publishing slots based on available time and production capacity.
42. **Pre-publish checklist** — check aspect ratio, captions, audio rights, spelling, links, disclosure, and platform requirements.
43. **Publishing integration status** — verify connected account permissions and distinguish draft creation from actual publication.
44. **Performance dashboard** — consolidate available views, watch time, retention, engagement, clicks, and follower changes with dates and source labels.
45. **Learning loop** — compare each post with the channel's own baseline at the same age and update future recommendations.
46. **Ethical monetization radar** — find plausible affiliate, service, sponsorship, product, and creator opportunities; flag fees, eligibility, and scams.
47. **Opportunity verification** — check official requirements, deadlines, region eligibility, payout method, and upfront costs before recommending an opportunity.
48. **Zero-budget planner** — prioritize free tiers, open-source tools, organic distribution, and small experiments; surface hidden limits before use.
49. **Experiment tracker** — define one hypothesis, one change, a success metric, and a review date for each growth experiment.
50. **Daily executive brief** — summarize what changed, what completed with proof, what failed, the best next actions, and any decisions needed from the user.

## Implementation order

### Phase 1 — trust and engineering foundation
Prioritize 6, 11, 14, 15, 18, 20, 27, 28, 29, and 50. These make execution measurable and safe before adding autonomy.

### Phase 2 — knowledge and monitoring
Implement 1–5, 7–10, 21–26, and 30 with explicit source links, timestamps, permissions, and graceful failure states.

### Phase 3 — content intelligence
Implement 31–40 using available sources and connected-channel data. Recommendations must state evidence and uncertainty; no guarantee that content will trend or go viral.

### Phase 4 — publishing and sustainable income
Implement 41–49 only after relevant integrations are connected and tested. Keep external publishing, spending, account changes, and financial transactions behind explicit user approval.

## Acceptance standard for every feature
- Has a clear UI/status and a testable definition of done.
- Handles offline, empty, permission-denied, API-limit, and error states.
- Does not expose credentials or private data.
- Has tests where applicable and a verifiable result link or artifact.
- Is labelled **implemented**, **in progress**, or **planned** accurately.
- Does not promise guaranteed virality, profit, autonomous operation, or 24/7 monitoring without the required working infrastructure.
