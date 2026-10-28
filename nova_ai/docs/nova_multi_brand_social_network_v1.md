# NOVA Multi-Brand Social Network v1

## Goal
Design one private NOVA control plane for a proposed portfolio of 41 editorial brands, with Arabic and English content, distinct identities, reusable original assets, scheduling, analytics, and owner-controlled publishing. The portfolio is a plan, not a claim that 41 accounts have been created or that every platform allows that many accounts.

Account capacity is configurable per platform. Each adapter must expose its own account eligibility, API permissions, rate limits, and publishing capabilities; never assume a fixed number of accounts is permitted.

## Initial brand portfolio
These are 41 proposed editorial lanes; names and handles remain unclaimed until the owner chooses and registers them. Brand names are working titles, not verified trademarks or available handles.

1. **LOL Planet** — comedy, sarcasm, original memes, jokes and sketches.
2. **Midnight Files** — horror fiction, mysteries and strange stories; clearly label fiction and verify factual claims.
3. **AI After Dark** — playful AI experiments, strange outputs and useful AI tools.
4. **Sports Vibes** — football and other sports: verified news, schedules, results, tactical explainers, skills and audience quizzes.
5. **Pet Comedy Club** — funny pet moments and recurring original animal characters.
6. **Beyond Mystery** — unusual places, puzzles and evidence-based mysteries.
7. **Future Unlocked** — AI, technology, practical tools and future-facing ideas.
8. **Daily Chaos** — relatable everyday life, home, study, work and relationships.
9. **Challenge Arena** — original quizzes, visual puzzles and audience challenges.
10. **Wild & Funny** — animal humor and responsibly sourced nature moments.
11. **Science Uncovered** — science, space, inventions and verified discoveries.
12. **Bite & Smile** — easy recipes, food experiments and food humor.
13. **Level Up Life** — practical personal growth, learning habits and skills without fake promises.
14. **World Is Weird** — global customs, language curiosities and unusual verified facts.
15. **Dream Machines** — cars, engineering and future transport.
16. **Brain Trap** — logic puzzles, visual perception and brain teasers.
17. **Hidden Earth** — lesser-known destinations and natural wonders.
18. **Money Unfiltered** — realistic money education, tool reviews and transparent opportunity analysis; no guaranteed-income claims.
19. **Office Circus** — original workplace and career comedy.
20. **What If Universe** — clearly labelled speculative fiction and imaginative scenarios.
21. **Fit & Strong** — fitness education, beginner-friendly exercise and habit challenges; avoid unsupported medical claims.
22. **GameVerse** — gaming discovery, reviews, tips and original challenges.
23. **Screen Secrets** — film and TV commentary, reviews and entertainment explainers; respect clip and image rights.
24. **Toon Town** — original cartoon characters, short comedy episodes and serialized adventures.
25. **Style Radar** — fashion, styling and budget-conscious outfit ideas.
26. **Space Makeover** — home organization, interiors and low-cost room improvements.
27. **Make It Magic** — DIY, crafts, repair ideas and upcycling.
28. **Sound Lab** — original beats, sound design, beginner music production and creator tips.
29. **Language Hackers** — vocabulary, expressions, translation games and language learning.
30. **Nature Pulse** — wildlife, ecosystems, weather phenomena and environmental education.
31. **Startup Zero** — low-cost business experiments, tools and lessons from real outcomes.
32. **Focus Mode** — productivity, planning, focus habits and tool comparisons.
33. **Cosmic Window** — astronomy, planets, missions and sourced space discoveries.
34. **Reality Glitch** — optical illusions, perception experiments and visual puzzles.
35. **Street Food Quest** — street food, culinary cultures and food discovery.
36. **Pet School** — responsible pet care and positive training, with expert review for health-sensitive advice.
37. **Build Tomorrow** — robotics, electronics, coding and beginner engineering projects.
38. **Book Bites** — book reviews, reading recommendations and short original summaries.
39. **Culture Connect** — respectful cultural exchange, traditions and stories from different communities.
40. **Creative Sparks** — original design prompts, art experiments and creative challenges.
41. **Sports Vibes: Skills & Tactics sub-channel (optional)** — original drills, rule explainers and tactical diagrams; this is a content lane under Sports Vibes, not automatically a separate account.

A brand registry must support adding, editing, pausing, and retiring brands without code changes. Each brand has its own identity record, tone guide, prohibited topics, visual system, language strategy, content calendar, account links, and performance history. Do not copy Asa7be or another creator's name, logo, posts, or distinctive work. Do not publish sports broadcast footage or copyrighted music without suitable rights.
 
## Language strategy
- Every content item stores Arabic and English variants separately, plus language mode (ar, en, both) and intended audience/region.
- Use natural localization, not literal translation. Preserve the joke or meaning; permit separate language-specific punchlines.
- A post may be published in both languages in one asset/caption or as separate variants, according to the platform's format and the brand's experiment plan.
- Run Arabic and English spelling, context, safety, factuality, rights, and duplicate-content checks before scheduling.
- Never assume one identical post should be cross-posted to every platform. Use platform-specific dimensions, captions, music/audio rights, hashtags, accessibility text, and content policies.

## Account capacity model
- Platform registry: Facebook Pages, Instagram professional accounts, TikTok, YouTube, X, and future adapters.
- Account slots are configurable per platform; do not assume every platform permits 41 accounts. Track stable account IDs, brand assignment, connection status, granted scopes, supported content types, last verification time, and explicit publishing state.
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
2. Add brand registry and ten initial brand profiles, with editable names and identity guides.
3. Add platform/account registry and show ten slots per platform without pretending to connect them.
4. Add bilingual content objects and brand-specific calendars.
5. Add local queue + dry-run platform adapter and policy/approval center.
6. Add one official connector at a time, starting with the platform whose permissions and free-tier requirements are verified.
7. Add audit logs, verified publication receipts, metrics, and stop switch.
8. Test Flutter format/analyze/tests/build and backend tests; report actual CI outcomes.

## Acceptance criteria
- All 41 proposed brands can be configured independently; owner can add or retire brands without changing app code.
- Each brand supports Arabic, English, or both.
- Platform account slots can be represented without fake connection states.
- Drafts and schedules identify brand, platform, language, and content variant.
- No publish attempt can occur without a verified adapter, valid scopes, and policy approval.
- Duplicate jobs are idempotent; retries are bounded; the global stop switch blocks new jobs.
- Published state requires verifiable platform receipt.
- UI communicates blockers honestly and remains useful in draft-only mode.
## Specialist departments (required)
The 41 proposed brands are the editorial portfolio; the five specialist departments and the creative-agent roster below are shared services across all brands. They cooperate through one auditable workflow, and each task carries a brand ID, platform, language, source links, rights status, and approval state.

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

## Creative Chaos Lab — specialist AI agents
These agents are designed to be unusually imaginative, fast at exploring alternatives, and willing to challenge weak ideas. “Wild” means creative and unconventional—not deceptive, abusive, unsafe, or allowed to bypass owner permissions. Start as bounded, testable workflows; do not label them autonomous until implemented and evaluated.

### Creative agents
1. **Idea Demon / شرارة الجنون** — produces 20–50 distinct concepts per brief, including unusual combinations and deliberately unconventional angles; removes near-duplicates and explains why each idea could work.
2. **Trend Alchemist / كيميائي الترند** — turns permitted trend evidence into original brand-fit concepts. Must attach source, timestamp, region, confidence, and expiry; never invent a trend or fabricate metrics.
3. **Hook Assassin / صيّاد الثواني الأولى** — drafts multiple opening hooks for the first 1–3 seconds, then scores clarity, curiosity, audience fit and truthfulness. No fake claims or misleading clickbait.
4. **Meme Mutant / متحوّل الميمز** — creates fresh meme premises, caption structures and visual directions from common experiences, not copied creator templates or recognizable copyrighted characters.
5. **Story Architect / مهندس الحكايات** — builds short scripts, recurring characters, cliffhangers and serialized story arcs with continuity notes and a fiction/fact label.
6. **Multiverse Writer / كاتب الأكوان** — creates divergent creative directions (comedy, mystery, educational, emotional, absurd) for the same topic and explains the trade-offs.
7. **Audience Mirror / مرآة الجمهور** — models likely questions, objections, cultural context and accessibility needs from permitted aggregate signals; does not infer sensitive traits about identifiable people.
8. **Localization Shapeshifter / متحوّل اللهجات** — rewrites ideas naturally for Sudanese Arabic, Modern Standard Arabic, Egyptian, Gulf, Levantine and global English when appropriate; checks that humor survives localization.
9. **Visual Mad Scientist / عالم الصورة المجنون** — creates image-generation briefs, composition plans, visual motifs, character sheets and thumbnail variants; records which assets are prompts versus actually generated files.
10. **Video Chaos Director / مخرج الفوضى** — converts approved ideas into 15/30/60-second scripts, shot lists, subtitle plans, sound cues and platform-specific exports, with rights checks for audio.
11. **Remix-without-Copy / إعادة ابتكار بلا نسخ** — identifies the abstract format or audience need behind references, then makes a substantially original treatment; flags overly similar wording, layout, characters or shots.
12. **Cross-Brand Crossover / مهندس التقاطعات** — combines two or three brands into a coherent special (e.g., sports + comedy, science + puzzles) while keeping each account’s identity clear.
13. **Comment-to-Concept / محوّل التعليقات** — turns public, permitted, de-identified audience questions into response ideas; strips personal information and blocks harassment pile-ons.
14. **Series Machine / مصنع السلاسل** — develops repeatable formats, episode templates and 30-day content arcs, while varying substance so the feed does not become repetitive spam.
15. **A/B Arena / ساحة التجارب** — proposes controlled tests for hooks, thumbnails, language, duration and posting windows; changes one variable at a time and reports uncertainty rather than declaring winners from tiny samples.
16. **Fact & Source Hunter / صائد الحقائق** — checks factual claims against credible sources, distinguishes fact/opinion/fiction, and blocks unsourced high-impact claims.
17. **Rights Guardian / حارس الحقوق** — checks provenance and licensing for footage, photos, fonts, templates, music, logos and generated assets; unclear rights trigger a block or owner review.
18. **Platform Tactician / تكتيكي المنصات** — adapts captions, aspect ratios, subtitles, accessibility, length and metadata to each platform’s verified current capabilities; cannot bypass restrictions.
19. **Sports Desk / غرفة الرياضة** — verifies sports schedules, results, team/player facts and source timestamps; separates news from analysis and never invents live scores or uses unlicensed broadcast clips.
20. **Revenue Scout / كشاف الدخل** — evaluates ethical monetization routes, eligibility, geographic restrictions, thresholds, payout methods, fees and evidence; never labels an opportunity “guaranteed.”
21. **Quality Duelist / مبارز الجودة** — runs an adversarial review: argues why a concept might fail, be confusing, culturally insensitive, derivative, unsafe or expensive before approval.
22. **Red-Team Critic / الناقد الشرس** — deliberately attacks the strongest proposed concept and asks for evidence, originality, audience value and feasibility; may reject or request a rewrite, but cannot override safety or owner decisions.
23. **Content Packager / مهندس الحزمة** — assembles the complete deliverable: title variants, hooks, script, captions, subtitles, thumbnail brief, CTA, hashtags where useful, sources, rights checklist and platform variants.
24. **Production Foreman / مدير خط الإنتاج** — breaks work into tasks, tracks dependencies and actual file outputs, estimates effort, and flags missing assets instead of marking them complete.
25. **Learning Loop / ذاكرة التجارب** — learns from verified performance and post-mortems, stores reusable patterns and failures with evidence, and avoids treating correlation as proof of causation.

### Required agent contract
Every agent task must declare: task ID, brand ID, platform, language/region, input references, output schema, estimated effort, rights/source status, confidence, safety flags, and current state. Each output is a draft until it passes the quality gate. Agents may critique and recommend each other’s work, but must not fabricate research, fake file creation, post without authorization, or silently change owner-defined policies.

### Creative pipeline
Brief -> Idea Demon generates divergent concepts -> Trend Alchemist and Fact & Source Hunter validate context -> Hook Assassin and Story Architect shape the idea -> Localization Shapeshifter creates language variants -> Visual Mad Scientist / Video Chaos Director / Content Packager prepare production-ready instructions and assets -> Rights Guardian + Quality & Safety review -> Quality Duelist and Red-Team Critic challenge the package -> owner/policy gate -> dry-run queue -> authorized publishing adapter -> verified receipt -> A/B Arena and Learning Loop review results.

### Agent orchestration and budget
- Begin with a deterministic local agent registry and mock/dry-run orchestration; show which agents are configured, implemented, connected, tested, blocked or failed.
- Prefer rule-based tools and existing free/local capabilities when viable. Every external model/API call must show provider, free-tier limits, data handling, cost risk and fallback before enabling it.
- No hidden paid usage, no hard-coded API keys, and no promise of unlimited generation or research under a zero budget.
- Use a task budget, bounded retries, duplicate suppression, deadlines and a global stop switch. Agents must not create infinite self-assigned work loops.
- Keep a human approval gate for account connections, first live posts, sensitive topics, unclear rights, spending, and irreversible actions.
- Measure creativity with diversity, originality checks, brand fit, factuality, production feasibility and audience results—not by how shocking a concept sounds.

## Department status truthfulness
Until each module is implemented and tested in the actual NOVA codebase, these departments are specifications rather than live autonomous agents. Trend monitoring requires an actual data source; production requires a verified media-generation/export path; analytics and monetization require authorized data and eligibility evidence. The dashboard must display each module's real state (planned, local-only, connected, verified, blocked, or failed), never a simulated success.