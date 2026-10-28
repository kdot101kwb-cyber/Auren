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