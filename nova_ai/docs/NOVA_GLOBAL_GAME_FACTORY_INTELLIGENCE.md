# NOVA GLOBAL GAME FACTORY — Intelligence & Production Specification

**Status:** Approved product specification; implementation not yet verified.
**Location constraint:** All NOVA work stays under `nova_ai/`. Do not modify AUREN root files for this feature.
**Operating constraints:** $0-first, free/public evidence first, low-data and Android-aware, human approval for publishing, spending, contracts, account access, blockchain signatures, and irreversible actions.

## 1. Mission

Build a global game-and-content opportunity system that discovers underserved demand, analyzes games/apps/content across markets, proposes original concepts, creates small prototypes through NOVA Game Studio, validates them with evidence, and recommends ethical revenue paths.

The factory must not merely copy current hits. It should identify:
- early demand and repeated user complaints;
- successful mechanics that can be recombined into original concepts;
- underserved languages, devices, regions, and accessibility needs;
- content formats and characters that can support a game universe;
- failed or declining products and their documented failure causes;
- opportunities that can be tested with a free prototype before any spending.

A discovery signal is not proof of demand, profitability, virality, or a future sale.

## 2. Six continental market scouts

Use six regional scouts for the inhabited continents. Antarctica is intentionally excluded from consumer-market coverage; it has no ordinary resident consumer-game market.

| Scout ID | Coverage | Required research lens |
|---|---|---|
| `africa_scout` | Africa, with country-level views | Low-end Android, data costs, offline/low-data play, local languages, payment availability, local creator ecosystems |
| `asia_scout` | East, South, Southeast, Central and West Asia | Mobile-first genres, social play, anime/influenced aesthetics, localization, platform/store differences |
| `europe_scout` | Europe | Indie games, premium/free-to-play expectations, accessibility, privacy and consumer rules, PC/mobile crossovers |
| `north_america_scout` | North America | Creator-led discovery, PC/console/mobile trends, subscriptions, ad-supported games, community feedback |
| `south_america_scout` | South America | Mobile reach, localization, community-driven games, regional pricing and payment friction |
| `oceania_scout` | Australia, New Zealand and Pacific markets | Indie development, esports/community formats, mobile/PC niches, small-market distribution |

Each scout reports by country where evidence permits. A continent-level summary must never be presented as if every country has the same market, store availability, purchasing power, or payment access.

## 3. Specialist agents shared across all regions

Regional scouts collect and contextualize evidence; specialist agents analyze it across regions.

1. **Game Trend Hunter** — discovers emerging game genres, mechanics, tags, communities and search phrases.
2. **App Store Intelligence** — monitors official store listings, release notes, ratings, review themes, pricing and availability where public access permits.
3. **Viral Content Hunter** — studies public short-form videos, creator formats, challenges, memes and recurring audience reactions.
4. **Game Psychology Analyst** — analyzes documented retention loops, onboarding, session length, social motivation, difficulty curves and user complaints. It must not use manipulative or exploitative dark patterns.
5. **Character & Universe Creator** — proposes original characters, stories, visual identities and expandable worlds. It must check for confusing similarity and respect third-party copyrights, trademarks and likeness rights.
6. **Competitor Feature Analyst** — documents observable features and user experience; it must not copy proprietary code, art, assets, confidential data or protected characters.
7. **Game Monetization Lab** — compares transparent ads, optional purchases, cosmetic items, paid downloads, sponsorships and licensing. It must disclose assumptions and never promise earnings.
8. **Community & Localization Agent** — analyzes language, cultural context, accessibility, moderation needs and local relevance.
9. **Failed Games Intelligence** — studies shutdowns, delistings, declining products, negative reviews and documented postmortems; separates confirmed causes from hypotheses.
10. **Game QA & Accessibility Analyst** — checks usability, crashes, performance budgets, controls, localization, age-appropriate design and accessibility.
11. **Platform & Policy Analyst** — checks official platform rules, store policies, age ratings, privacy, advertising, payment and regional availability.
12. **Game IP & Brand Analyst** — checks name collisions and obvious IP risks before branding; this is a screening aid, not legal clearance.

## 4. Public evidence sources

Use free public sources first, subject to each site's terms and rate limits:
- Official Google Play and Apple App Store listing pages, public reviews and release notes.
- Official Steam pages, SteamDB public pages where permitted, itch.io, GDevelop, Godot and other engine communities.
- Official developer blogs, game studio announcements, product changelogs and public postmortems.
- GitHub repositories, releases, issues, discussions and commit activity.
- Hacker News, Reddit communities, public developer forums and public creator posts.
- YouTube, TikTok, Instagram and Facebook public content where accessible and permitted.
- Google Trends where accessible; record the selected region, time window, search term and comparison settings.
- arXiv and public research papers for new interaction, AI, rendering, game design and user research techniques.

Do not scrape behind logins, bypass rate limits, defeat access controls, or collect private user data. Prefer official APIs and feeds when available. If a source cannot be accessed reliably, mark it unavailable instead of filling the gap with guesses.

## 5. Evidence and trend measurement rules

Every signal record must contain:
- exact source title and canonical URL;
- publisher/account or repository;
- observation timestamp in UTC;
- publication/update date when available;
- geography, language and platform;
- observed fact, separately from interpretation;
- measured count and its unit only when the source exposes it;
- baseline and comparison window for any growth calculation;
- access method and confidence;
- rights/policy notes where relevant.

Never invent downloads, revenue, active users, retention, conversion, search volume, view velocity, ratings, or growth. GitHub stars are a repository-interest signal, not game demand. Views are not unique viewers. Review counts are not sales. If only a single snapshot exists, report a count without a growth claim.

Deduplicate the same announcement reposted across sites. Keep source snapshots so future comparisons use the same metric and window.

## 6. Opportunity scoring

Score each opportunity from 0–100 with an explicit evidence ledger:

- Evidence quality and recency: 25 points.
- Clear audience pain or unmet need: 20 points.
- Free prototype/validation feasibility: 15 points.
- Buyer and distribution clarity: 15 points.
- Differentiation and original IP potential: 10 points.
- Revenue-path plausibility: 10 points.
- Device, bandwidth and regional fit: 5 points.

Subtract risk penalties for unclear IP rights, platform-policy conflicts, deceptive monetization, high infrastructure cost, payment barriers, sensitive data, or weak evidence. Display the component scores and reasons; never show a naked score.

Suggested gates:
- 80–100: prototype candidate, only after council review.
- 65–79: run a free validation experiment or produce a concept brief.
- Below 65: watchlist, research gap, or archive.

A high score is prioritization, not a forecast or guarantee.

## 7. End-to-end production workflow

1. **Discover:** scouts gather public evidence and user pain points.
2. **Normalize:** intelligence hub deduplicates records and preserves source dates.
3. **Analyze:** specialists produce regional and cross-region findings.
4. **Debate:** Game Council compares at least three concept directions, including a no-build option.
5. **Choose:** rank concepts by evidence, cost-to-test, device fit, originality and buyer clarity.
6. **Design:** create a concise game design document, target audience, core loop, controls, accessibility and monetization assumptions.
7. **Prototype:** hand off an approved brief to the existing NOVA Game Studio pipeline.
8. **Test:** run deterministic tests and human playtests; record device, build, test steps, bugs and results.
9. **Content package:** prepare original trailers, clips, screenshots, store copy and creator briefs; no publishing without platform authorization and owner approval.
10. **Validate:** use opt-in interviews, landing-page interest, demo feedback or a small private test. Do not fake users, reviews, downloads or engagement.
11. **Launch readiness:** check IP, privacy, age rating, store policy, localization, support and payment eligibility.
12. **Measure:** track verified installs, active users, retention, purchases, ad revenue and refunds only when real analytics or statements support them.

## 8. Game Council roles

The council contains:
- Creative Director;
- Regional Market Director;
- Game Design Lead;
- Engineering/Build Lead;
- Art & Character Lead;
- QA & Accessibility Lead;
- Monetization & Finance Lead;
- Community & Localization Lead;
- Security, Privacy & Policy Reviewer;
- Skeptical Reviewer / Failure Analyst.

The skeptical reviewer must actively look for reasons not to build. Council output includes evidence, disagreements, unknowns, estimated free-test effort, cost risks, and a recommended next experiment. AI perspectives are not independent human approvals.

## 9. Revenue paths

Evaluate each project against multiple legitimate paths:
- free-to-play with clearly disclosed, non-manipulative ads;
- optional cosmetic purchases and expansions;
- paid game or premium upgrade;
- sponsorships and brand collaborations;
- original character licensing and merchandise only after rights and demand are established;
- game templates, asset packs and developer tools;
- contract game prototyping and interactive-content services;
- educational games and institutional licensing;
- creator content, streaming and community events;
- affiliate links only with clear disclosure and platform compliance.

Crypto/NFT or play-to-earn projects are a separate high-risk category. Verify official project sources, token/chain details, eligibility, fees, jurisdiction, custody and withdrawal terms. Never treat token points or unclaimed allocations as income. Never automate gameplay in ways that violate game rules, fake engagement, or bypass anti-bot protections. Never request or handle seed phrases/private keys; no automatic wallet connection, signing, payment or claiming.

## 10. Zero-budget and low-bandwidth rules

- Default to open-source engines and free tools, including Godot and other tools already catalogued in NOVA.
- Prefer local-first notes, cached public metadata and resumable downloads.
- Do not purchase domains, ads, assets, APIs, subscriptions, cloud compute or credits.
- Do not start paid infrastructure or incur usage charges without explicit owner approval.
- Prototype a small vertical slice before considering a full game.
- Include low-end Android performance and offline/low-data modes in the acceptance criteria when relevant.
- Use original or properly licensed assets; record license and attribution.
- No automatic publishing, account creation, spending, contract acceptance or external commitments.

## 11. Integration map — avoid duplicate systems

This specification is the intelligence layer, not a replacement for existing NOVA work:
- **NOVA Game Studio / free game toolkit:** prototype generation and build pipeline. An existing draft PR (#292) describes a Godot starter and a ten-tool plan; its own description says those tools are not all live integrations and the latest checks were pending. Re-check before depending on it.
- **3D Game Studio:** an existing PR (#291) adds a game-studio screen; review overlap before merging or adding another screen.
- **Global Opportunity Radar / Market Watch:** reuse existing public-source discovery and opportunity-scoring components where they fit; do not create a second general-purpose market radar.
- **Viral Distribution Engine / Video Factory:** reuse content planning and production pathways; keep publishing approval gates.
- **Digital Human Universe:** connect original characters and worlds to game concepts through shared character/IP records, not duplicate character databases.
- **Revenue Engine:** reuse evidence-gated income tracking and payment eligibility checks. Do not count hypothetical game revenue as actual income.

All code and documentation for this feature must remain under `nova_ai/`. Avoid editing `functions/`, root CI workflows, AUREN app files, or other non-NOVA paths in this workstream.

## 12. Suggested NOVA data entities

- `GameSignal`: source, observedAt, publishedAt, region, country, language, platform, metric, value, unit, baselineWindow, evidenceUrl, confidence.
- `MarketSnapshot`: region/country, store/platform, category, price band, device/bandwidth assumptions, availability and observedAt.
- `GameOpportunity`: audience, problem, concept, differentiation, score breakdown, risks, validation plan, status.
- `GameConcept`: original title candidates, core loop, mechanics, art direction, characters, target platform, accessibility and IP notes.
- `GameExperiment`: hypothesis, sample, method, consent, cost, dates, measured outcomes and conclusion.
- `GameBuild`: linked studio project, engine/tool versions, build hash, test results, known limitations and approvals.
- `GameRevenueRecord`: source, gross, fees, refunds, net, currency, date, evidence reference and verification state.

Use stable IDs, timestamps, source attribution, schema versioning and local-first storage. Avoid collecting personal data from players unless strictly necessary and explicitly consented.

## 13. MVP delivery phases and acceptance criteria

**Phase A — Evidence-first scout foundation**
- Six regional scout profiles and shared specialist role definitions.
- Source registry and evidence schema.
- Manual/public-source signal intake with date, geography and provenance.
- Deduplication and measured-count rules.
- Regional report and cross-region comparison.
- Tests proving missing metrics remain unknown rather than fabricated.

**Phase B — Opportunity and council**
- Transparent scoring with risk penalties.
- Three-concept comparison and skeptical review.
- Free validation experiment templates.
- Owner approval before prototype generation.

**Phase C — Game Studio handoff**
- Export a structured, versioned game brief to the existing Game Studio.
- Link concept, source evidence, acceptance criteria and approved assets.
- Track build/test status without claiming a runner executed when it did not.

**Phase D — Content and revenue validation**
- Generate platform-specific draft content and store listings.
- Maintain approval gates for publishing and external actions.
- Track real test outcomes and verified revenue separately from targets.

**Definition of done:** tests cover evidence provenance, regional scoping, metric honesty, duplicate detection, scoring explanations, risk gates, offline persistence, and approval boundaries. A screen or plan alone does not prove that live scouts, APIs, game engines, playtesting or revenue collection are operational.
