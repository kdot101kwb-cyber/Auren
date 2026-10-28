# NOVA Multi-Brand Social Network v1

## Goal
Design one private NOVA control plane that can manage up to five distinct brands per supported platform, with Arabic and English content, different editorial identities, reusable original assets, scheduling, analytics, and owner-controlled publishing.

This is a capacity target, not a claim that every platform currently permits or approves five connected accounts. Each platform adapter must expose its own account eligibility, API permissions, rate limits, and publishing capabilities.

## Initial brand portfolio
These are proposed editorial lanes; names and handles remain unclaimed until the owner chooses and registers them.
1. Comedy & sarcasm — original memes, jokes, sketches, relatable situations.
2. Strange stories & mysteries — explainers and curious stories; fact-check claims before publication.
3. AI, technology & future — tools, experiments, practical AI and tech news.
4. Everyday life & relationships — relatable situations, light humor and useful observations without targeted harassment.
5. Games, challenges & audience participation — original quizzes, prompts, polls where supported, and community challenges.

Each brand has its own identity record, tone guide, prohibited topics, visual system, language strategy, content calendar, account links, and performance history. Do not copy Asa7be or another creator's name, logo, posts, or distinctive work.

## Language strategy
- Every content item stores Arabic and English variants separately, plus language mode (ar, en, both) and intended audience/region.
- Use natural localization, not literal translation. Preserve the joke or meaning; permit separate language-specific punchlines.
- A post may be published in both languages in one asset/caption or as separate variants, according to the platform's format and the brand's experiment plan.
- Run Arabic and English spelling, context, safety, factuality, rights, and duplicate-content checks before scheduling.
- Never assume one identical post should be cross-posted to every platform. Use platform-specific dimensions, captions, music/audio rights, hashtags, accessibility text, and content policies.

## Account capacity model
- Platform registry: Facebook Pages, Instagram professional accounts, TikTok, YouTube, X, and future adapters.
- Capacity target: five account slots per platform, with stable account IDs, brand assignment, connection status, granted scopes, supported content types, last verification time, and explicit publishing state.
- A brand may link to multiple platforms; a platform account must be assigned intentionally to a brand.
- Do not store passwords or long-lived OAuth secrets in Flutter, SharedPreferences, repository files, or client logs. Tokens belong in a protected server-side secret store.
- Never claim an account is connected until OAuth/official API identity and permissions have been checked.

## Core modules
1. Brand Registry — create/edit brand identity and assign account slots.
2. Content Studio — bilingual drafts, memes, image/carousel/video briefs, asset provenance and rights.
3. Research Radar — collect permitted trend signals and source links; distinguish verified facts from speculation.
4. Localization & Quality Gate — language-specific editing, platform formatting, duplicate detection and safety/rights review.
5. Calendar & Queue — time zone, schedule, per-platform jobs, retries with bounds, idempotency, and pause/resume.
6. Approval & Policy Center — owner-defined auto-publish rules, per-brand and per-platform permissions, sensitive-topic review, daily caps and emergency stop.
7. Platform Adapters — one adapter per official API, exposing capability/permission checks and dry-run mode.
8. Analytics — record platform-returned post IDs/URLs and permitted metrics; compare by brand, language, format, and publication age.
9. Audit Log — immutable events for approvals, connection changes, schedule decisions, API outcomes and stop-switch actions.

## Publishing states
idea -> researched -> draft -> localized -> quality_review -> owner_approval_or_policy_gate -> scheduled -> publishing -> published | failed | blocked

published requires a successful platform response and a verifiable post ID or URL. Failed, blocked, or unverified jobs remain clearly labelled; no fake success state.

## Permission model
- Default: disconnected and draft-only.
- Initial live integration: owner manually connects an account and verifies identity/scopes.
- First real post on each platform/account: explicit owner approval.
- Auto-publish: disabled until the platform adapter has passed permission checks, API policy review, dry-run tests and a verified owner-approved test post.
- The owner can pause one job, one account, one brand, one platform, or the whole network immediately.
- Never bypass platform API review, rate limits, account restrictions, or required user interaction. When an API cannot publish a requested format, offer a draft/export/manual handoff.

## Platform-specific constraints to validate at runtime
- Meta: use official APIs and eligible Page/Instagram professional accounts with the required permissions and app review; verify each Page/account link and scope.
- TikTok: Direct Post requires the appropriate API configuration, authorization and review; unaudited clients may be restricted to private-only posting. Do not copy arbitrary videos from other platforms.
- YouTube: use authorized channel-level APIs and obey quotas, rights and platform policies.
- X and any future platform: implement only documented, currently authorized API capabilities; report any plan/credit/API-access requirement before enabling it.
- The UI must show per-platform blockers instead of implying universal cross-posting.

## Zero-budget operating principle
Build the control plane, local drafts, brand profiles, policy rules, and dry-run queue first. Before implementing or enabling any live connector, check whether the required official API access and hosting can be operated within the user's current free-tier budget. Never promise fully automatic publishing, unlimited research, or guaranteed income on a zero-cost setup.

## Delivery sequence
1. Inspect actual NOVA Flutter project and current CI; keep the current Comedy Studio PR unmerged until reviewed.
2. Add brand registry and five initial brand profiles, with editable names and identity guides.
3. Add platform/account registry and show five slots per platform without pretending to connect them.
4. Add bilingual content objects and brand-specific calendars.
5. Add local queue + dry-run platform adapter and policy/approval center.
6. Add one official connector at a time, starting with the platform whose permissions and free-tier requirements are verified.
7. Add audit logs, verified publication receipts, metrics, and stop switch.
8. Test Flutter format/analyze/tests/build and backend tests; report actual CI outcomes.

## Acceptance criteria
- Five brands can be configured independently.
- Each brand supports Arabic, English, or both.
- Platform account slots can be represented without fake connection states.
- Drafts and schedules identify brand, platform, language, and content variant.
- No publish attempt can occur without a verified adapter, valid scopes, and policy approval.
- Duplicate jobs are idempotent; retries are bounded; the global stop switch blocks new jobs.
- Published state requires verifiable platform receipt.
- UI communicates blockers honestly and remains useful in draft-only mode.
## Specialist departments (required)
The five brands are the editorial portfolio; these five specialist departments are shared services across all brands. They cooperate through one auditable workflow, and each task carries a brand ID, platform, language, source links, rights status, and approval state.

### 1. Trend Hunter
- Monitor permitted public trend signals, search demand, platform trend surfaces and credible sources where access is available.
- Score each idea on momentum, audience fit, originality, language/region fit, production effort, rights risk, policy risk and monetization relevance.
- Show evidence, timestamp, source and confidence; label hypotheses as hypotheses, not facts.
- Do not scrape private accounts, bypass access controls, or promise virality.

### 2. Comedy Department
- Generate original jokes, memes, captions and sketch concepts in the selected Arabic dialect or English style.
- Allow dialect choices such as Sudanese Arabic, Modern Standard Arabic, Egyptian, Gulf, Levantine, or English; make dialect configurable per brand and audience.
- Use cultural context and localization rather than direct translation; keep a distinct joke/caption version per language when useful.
- Avoid copying another page's wording, characters, branding, or recognizable creative assets.

### 3. Production Department
- Prepare image concepts, meme layouts, short-video scripts/storyboards, shot lists, subtitles, titles, hooks, descriptions and platform-specific exports.
- Track asset provenance, creator/source, licenses, music/audio rights, font/template rights and permitted usage.
- Separate planned outputs from actually rendered media; the system must not mark an image/video as produced until the file exists and basic validation passes.
- Generate variants for each platform's current format and accessibility needs when supported by available tools.

### 4. Growth & Revenue Department
- Measure permitted impressions, views, watch time, retention, engagement, follows and link/conversion metrics when each platform exposes them.
- Compare results by brand, platform, language/dialect, format, hook and publication age; use small, documented experiments.
- Explore eligible monetization routes and document eligibility, country availability, thresholds, payout methods, fees and current evidence before recommending them.
- Do not promise earnings or treat views as income; distinguish observed results, estimates and unverified opportunities.

### 5. Quality & Safety Department
- Review originality, language quality, factual claims, defamation/targeted harassment, privacy, sensitive topics, platform policies and audience suitability.
- Check image/video/music/font/template rights and source licenses before approving publication; request owner review when rights are unclear.
- Flag manipulated media, impersonation, misleading claims, copyright risk, and unsafe content; return rejected items with actionable reasons.
- Keep an audit trail of checks, reviewer/rule versions, warnings, approval decisions and any overrides.

## Shared workflow and handoffs
Trend Hunter proposes and scores ideas -> Comedy develops original concept/copy -> Production prepares media and platform variants -> Quality & Safety checks language, claims, rights and policy -> Growth & Revenue sets measurement goals and reviews performance -> findings feed back into the next trend and content decisions.

Quality & Safety is a hard gate for scheduled or automatic publishing. Growth & Revenue can recommend experiments but cannot override safety, rights, platform restrictions or owner permissions. Owner pause/stop controls take precedence over all departments.

## Department status truthfulness
Until each module is implemented and tested in the actual NOVA codebase, these departments are specifications rather than live autonomous agents. Trend monitoring requires an actual data source; production requires a verified media-generation/export path; analytics and monetization require authorized data and eligibility evidence. The dashboard must display each module's real state (planned, local-only, connected, verified, blocked, or failed), never a simulated success.