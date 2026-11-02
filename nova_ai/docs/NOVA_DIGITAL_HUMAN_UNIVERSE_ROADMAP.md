# NOVA DIGITAL HUMAN UNIVERSE
## Product roadmap and implementation blueprint

**Status:** Approved product direction — planning only  
**Owner:** NOVA  
**Target:** Private, Arabic-first Android experience; Flutter/Firebase architecture  
**Build mode:** Hybrid (photorealistic + 3D/cartoon + anime + hybrid styles)  
**Launch portfolio:** All three tracks, delivered progressively  
**Autonomy:** Broad operational autonomy within explicit safety, rights, budget, and approval boundaries

> This document records the approved product scope. It does not claim that any feature is implemented, that media has been rendered, or that social accounts have been connected.

## 1. Product vision

NOVA Digital Human Universe is a private creative and media operating system for creating, managing, producing, and growing original digital characters and the worlds around them. It is more than an image generator or a social scheduler: each character has a persistent identity, visual specification, voice profile, personality, memory, relationships, story history, content portfolio, and measurable business performance.

The system must reuse existing NOVA/AUREN AI, production, series, provider-routing, creator, and analytics foundations wherever suitable. It must not create duplicate production queues or provider adapters without a documented gap.

## 2. Approved creative formats

The character pipeline supports four compatible visual families:

1. **Photorealistic digital humans** — original virtual presenters, educators, entertainers, lifestyle creators, sports explainers, and brand ambassadors.
2. **Stylized 3D and cartoon characters** — original animal casts, comedy characters, family-friendly characters, mascots, and episodic animation.
3. **Anime and illustrated characters** — original fictional casts, serialized stories, adventure, mystery, and game-linked characters.
4. **Hybrid characters** — consistent characters that can appear in approved alternate visual treatments while preserving recognizable identity.

Each character must have a canonical Character Identity Pack: name, original concept, age presentation where relevant, personality, biography, language, dialect, visual bible, reference assets, voice specification, motion/acting notes, wardrobe rules, continuity constraints, rights provenance, and disclosure requirements.

## 3. Launch portfolio — all tracks, phased

All three tracks are approved. They are not required to ship simultaneously; each progresses through validated milestones.

### Track A — Monkey Universe
- Original comedy ensemble with distinct characters, voices, motives, relationships, and running jokes.
- Short-form sketches, recurring episodes, mini-arcs, crossovers, audience polls, and compilations.
- No copying existing characters, signature designs, scripts, catchphrases, or protected franchises.
- Start with a small cast and a pilot batch; expand only after quality and audience signals justify it.

### Track B — AI Influencer Network
- Original photorealistic and stylized virtual creators in technology, science, culture, lifestyle, fashion, sports, education, and entertainment.
- Each account has a transparent virtual-persona disclosure appropriate to the platform and content.
- Editorial calendar, brand-safe content briefs, audience analysis, partnership pipeline, and revenue reporting.
- No impersonation, fake personal testimony, fabricated credentials, or deceptive claims that a synthetic persona is a real human.

### Track C — NOVA Stories
- Original animated and mixed-media series, short films, recurring story worlds, and interactive narrative experiments.
- Series bible, character arcs, episode bible, scene breakdown, asset manifest, voice/audio plan, production plan, continuity review, and rights review.
- Reuse the existing series planning and production pipeline instead of creating a second queue.
- Begin with one pilot episode per selected concept before committing to a full season.

## 4. Core platform modules

1. **Character Lab** — concept creation, originality checks, character setup, versioning, and approval.
2. **Identity & Continuity Engine** — canonical visual bible, reference set, outfit/location rules, and cross-shot consistency checks.
3. **Personality & Memory Engine** — stable voice, values, speech patterns, safe memory, canon facts, and story history.
4. **Voice & Performance Studio** — licensed/original synthetic voices, multilingual delivery, acting notes, expression and motion briefs.
5. **Human Studio** — photorealistic scene planning and generation through approved providers.
6. **3D & Animation Studio** — character assets, rigging/animation workflows, scene assembly, and rendering handoffs.
7. **Writers' Room** — premise generation, scripts, dialogue, story arcs, episode bibles, and character-specific dialogue.
8. **Director & Shot Planner** — shot lists, camera, lighting, staging, performance, and continuity instructions.
9. **Production Orchestrator** — job planning, provider selection, queueing, progress, retries, cancellation, and output manifests.
10. **Universe Graph** — characters, relationships, locations, timelines, canon, crossovers, and audience-driven story branches.
11. **Trend & Audience Intelligence** — trend discovery, audience questions, content hypotheses, and evidence-based experiments.
12. **Social Publishing Desk** — platform-specific packaging, captions, scheduling, moderation queues, and account health.
13. **Growth & Revenue Desk** — performance analytics, sponsorship leads, affiliate opportunities, licensing, products, and revenue attribution.
14. **Rights, Safety & Quality Gate** — originality, likeness/voice rights, copyright, factual review, age suitability, disclosure, and platform policy checks.
15. **Executive Dashboard** — portfolio status, production jobs, approvals, errors, costs, performance, and audit history.

## 5. Character lifecycle

Idea → originality review → identity pack → pilot script → asset creation → voice/performance → scene production → continuity/QC → owner review → publish/experiment → analytics → character improvement.

A character must not be promoted to an active public brand until its identity pack, rights provenance, disclosure plan, safety profile, and pilot quality review are complete.

## 6. Autonomy policy — Full within boundaries

NOVA may independently:
- Research ideas and trends, draft concepts, scripts, calendars, and production plans.
- Create private drafts and non-public test assets within approved free resource limits.
- Run quality, continuity, metadata, and policy checks.
- Retry recoverable technical failures within bounded retry and resource limits.
- Analyze results and recommend changes.

NOVA must request explicit user approval before:
- Spending money, subscribing, buying credits, or accepting paid usage.
- Publishing a new character/account or making a material identity change.
- Posting content in sensitive categories, making factual claims with meaningful risk, or responding to high-impact controversies.
- Using a real person's likeness, voice, identity, or personal data without documented authorization.
- Signing agreements, accepting sponsorship terms, licensing assets, or making legal/financial commitments.
- Deleting valuable assets, changing account ownership/security, or taking irreversible actions.

Pre-approved routine publishing may be enabled later as a separately configured policy, with platform-specific limits, disclosure, logs, and a pause switch. Full autonomy does not mean bypassing consent, platform rules, copyright, user approvals, or budget limits.

## 7. Architecture and reuse rules

Before implementation, inspect the current repository and map existing modules. Initial inspection has identified reusable foundations including:
- nova_ai/lib/features/debate/nova_debate_screen.dart
- lib/features/entertainment/presentation/auren_production_studio_screen.dart
- lib/services/entertainment/auren_production_service.dart
- lib/features/entertainment/presentation/auren_ai_series_studio_screen.dart
- lib/services/entertainment/series_production_service.dart
- lib/features/talent/presentation/talent_engine_screen.dart
- lib/services/ai/auren_ai_provider_catalog.dart

These paths were found during initial read-only inspection. Their presence does not imply they are production-complete or directly reusable without tests.

Implementation principles:
- Keep NOVA-specific orchestration and product logic within the NOVA area where the repository architecture permits; integrate through documented interfaces.
- Reuse the existing production job system and series pipeline where appropriate.
- Keep provider credentials server-side; never place API keys in the Android app.
- Store canonical character metadata separately from generated media files; version all identity and canon changes.
- Make every production job traceable to its prompt/brief, provider, model, rights metadata, cost/quota, outputs, and QC result.
- Design for free-first operation, local/offline drafting where feasible, low bandwidth, and graceful provider unavailability.
- Do not promise unlimited free generation; provider quotas, hardware, storage, and rendering capacity must be measured.

## 8. Delivery phases and acceptance gates

### Phase 0 — Repository and architecture audit
- Confirm the current NOVA directory, app entry point, package boundaries, roadmap location, tests, provider adapters, production queues, storage model, and security rules.
- Produce a reuse/gap map before code changes.
- **Gate:** no duplicate module or queue proposed without evidence.

### Phase 1 — Character foundation
- Character schema, identity pack, style family, versioning, private library, and lifecycle states.
- **Gate:** create, edit, archive, version, and reload a character without losing identity data; owner-only access is tested.

### Phase 2 — Identity, memory, and universe graph
- Personality profiles, voice specification, canon memory, relationships, locations, timelines, and continuity references.
- **Gate:** continuity data is deterministic, auditable, and scoped to the owning user/project.

### Phase 3 — Pilot production workflows
- One pilot workflow for each approved track: Monkey Universe, one virtual influencer, and one NOVA Stories episode.
- Connect to existing production/series systems through explicit interfaces.
- **Gate:** real provider execution is distinguished from a plan or placeholder; failed jobs and unavailable providers are handled honestly.

### Phase 4 — Quality, rights, and disclosure
- Similarity/originality review, source provenance, likeness/voice authorization, age suitability, factual checks, synthetic-media disclosure, and human review.
- **Gate:** publishing is blocked when required rights or review metadata is missing.

### Phase 5 — Audience and social operations
- Content calendar, platform packaging, comment insights, moderation support, analytics, experiments, and controlled publishing.
- **Gate:** no public publishing without the applicable permission and audit record.

### Phase 6 — Growth and monetization
- Sponsorship CRM, licensing catalog, affiliate tracking, digital products, revenue attribution, and cost accounting.
- **Gate:** report actual received revenue separately from projected or pending revenue.

### Phase 7 — Scale and franchise operations
- Multi-character collaborations, crossovers, interactive stories, fan communities, live formats, character licensing, and franchise extensions.
- **Gate:** scale only after reliability, rights, retention, and unit economics are demonstrated.

## 9. Minimum dashboard requirements

- Character library with filters by style, status, language, and project.
- Character profile showing identity pack, visual references, voice, personality, canon, relationships, and version history.
- Production board showing queued/running/review/failed/completed jobs, provider, quota/cost, and output links.
- Approval inbox for identity changes, publishing, sensitive content, and commercial actions.
- Universe map for character relationships and story continuity.
- Analytics showing reach, watch time, retention, engagement, follower growth, and revenue with source and time range.
- Global pause controls for production and publishing, plus per-character pause controls.

## 10. Definition of done

The universe is not considered implemented because a screen or mockup exists. Each release must include:
- A complete user flow and persisted data model.
- Firestore/security rules and ownership tests where applicable.
- Error, empty, loading, offline, and quota-exhaustion states.
- Provider contract tests and real execution evidence for any claimed media output.
- Character identity/continuity tests and rights/disclosure checks.
- Flutter analysis, relevant unit/widget/integration tests, and CI evidence.
- Documentation of limitations, costs, and manual approval points.

## 11. Current audit findings (read-only; branch-aware)

### NOVA application
- The standalone NOVA Flutter application exists on the development branch `feat/nova-ai-android-app`, with `nova_ai/pubspec.yaml`, `nova_ai/lib/main.dart`, and `nova_ai/lib/firebase_runtime.dart`.
- The NOVA entry point is `nova_ai/lib/main.dart`; it initializes the NOVA Firebase runtime and composes the dashboard, agent, creative, opportunity, integration, task, app-builder, revenue, AUREN workspace, DevOps, autonomous-brain, and global-radar screens.
- The app package is named `nova_ai`. Its Firebase dependencies are on the 3.x/5.x generation, while the AUREN root package uses newer Firebase 4.x/6.x packages. Keep the two Flutter package boundaries explicit; do not casually merge dependency versions.
- `nova_ai/README.md` explicitly labels the app a UI prototype. It states that remote GitHub edits, builds, email/social account management, and task synchronization are not yet implemented. The creative studio currently prepares requests but does not render media or compile games.
- Firebase runtime uses compile-time `--dart-define` configuration and App Check. Cloud features remain unavailable if the build lacks Firebase configuration.

### Reusable AUREN foundations
- AUREN has a Production Studio screen and Firestore-backed `users/{uid}/production_jobs` service with queued/planning/generating/assembling/review/completed/failed/cancelled states, retry/cancel operations, and output URL fields.
- AUREN has a Series Studio and series project service with series bible, character lists, season arcs, episode records, stages, and rights-review status.
- AUREN has a Talent Engine and creator-related services that may support casting and creator workflows, but these are not yet a NOVA character identity system.
- The provider catalog lists image/video/audio capabilities. The provider contract and UI must be checked separately from actual rendering: a provider being listed or a job being accepted is not proof that media was generated.
- Firestore and Storage rules exist. The current Storage rule inspected covers owner-scoped user media paths; dedicated character/universe ownership and lifecycle rules have not been demonstrated by this audit.

### Confirmed gaps for Digital Human Universe
- No implemented NOVA Character Lab, canonical identity pack, character versioning, character memory, relationship/universe graph, or visual-continuity service was found in the inspected NOVA app documentation and entry point.
- No verified end-to-end digital-human workflow was found that takes a character from identity pack through actual image/video/voice generation, quality review, and stored output.
- No verified NOVA publishing integration or real revenue attribution flow was found for these three creative tracks.
- The approved roadmap file is currently on the documentation branch `nova-digital-human-universe-roadmap`; it is not yet merged into `main` or the NOVA app branch.

### Audit decision
Reuse the existing series and production foundations through documented interfaces. Build NOVA-specific character identity, memory, continuity, universe, rights, and portfolio orchestration in the NOVA area. Do not create a second production queue or claim provider execution until a real worker and output verification are demonstrated. No application code, Firebase rules, provider configuration, or production jobs were changed during this audit.

## 12. Immediate next steps

1. Confirm the current NOVA app root/entry point and its active branch.
2. Locate or establish the canonical NOVA roadmap and link this blueprint from it.
3. Map existing character, creator, entertainment, production, provider, storage, and security components.
4. Write a gap report and proposed file-level implementation plan.
5. Only then begin the first code batch, keeping changes scoped to NOVA and opening a reviewable pull request; do not merge without user approval.
