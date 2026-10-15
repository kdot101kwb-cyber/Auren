# AUREN Entertainment Universe v1 — Product & Implementation Plan

Status: planning baseline only. This document does not claim that the features below are implemented.
Branch: `feat/entertainment-universe-v1-plan`
Base: `main`

## Product goal

Unify AUREN's existing entertainment, short-video, creator, production, audio, gaming, and watch-together capabilities into one discoverable experience. Build on existing screens and services instead of duplicating them. Encourage enjoyable, creative, social return visits without dark patterns, forced streaks, artificial scarcity, or endless-scroll pressure.

## Repository inventory checked

Existing code paths found on `main` during initial review:

- `lib/features/entertainment/presentation/auren_entertainment_discover_screen.dart` — entertainment search and AI recommendation stream.
- `lib/features/entertainment/presentation/entertainment_shorts_screen.dart` — short-form video experience, mood selection, saved IDs, view/action tracking, creator/profile entry points, sharing and comments.
- `lib/features/entertainment/presentation/watch_together_screen.dart` — watch-together rooms, invite codes, membership, playback control, and room chat.
- `lib/features/entertainment/presentation/auren_live_entertainment_screen.dart` — live entertainment discovery.
- `lib/features/entertainment/presentation/auren_ai_series_studio_screen.dart` — AI-assisted series briefs and production jobs.
- Additional entertainment paths include music, radio, podcasts, books/manga, TV, gaming, 3D world, production pipeline, and continue-watching/history screens.
- `lib/features/creator/presentation/creator_universe_screen.dart` exists on the separate `feat/creator-universe-hub-v1` branch and gathers existing creator tools. Do not assume it is merged into `main`.

This is an initial path-level inventory, not a claim that every flow has been tested end-to-end. Before implementation, inspect routing, Firestore rules, repository methods, and existing tests for each affected flow.

## Experience structure

One Entertainment Universe entry point with these destinations:
1. **For You** — curated mixed feed and user-controlled mood/intention.
2. **Toon & Stories** — original cartoon characters, connected stories, interactive endings, and audio stories.
3. **Shorts** — existing short-form video experience.
4. **Play & Puzzles** — daily optional puzzle, hidden clues, mini-games, and creator challenges.
5. **Creators** — creator discovery and user-generated remixes.
6. **Watch Together** — existing synchronized viewing/room flow.
7. **Library** — saved moments, watch progress, followed stories, and downloaded/offline-eligible content.

Do not create a second implementation of Shorts, Watch Together, AI series production, creator tools, or entertainment search if the existing service can be safely reused.

## New differentiating concepts

### Low-cost MVP candidates
- **Mood Mixer:** user chooses a goal such as laugh, wonder, learn, relax, or play with friends. Suggestions respond to this explicit choice; users can reset or disable personalization.
- **Daily Discovery:** one optional featured item (toon, short, puzzle, audio story, or creator work). No penalty for missing a day and no artificial countdown.
- **Audience Director:** story creators can offer a poll that genuinely determines a later story branch. Persist poll configuration and results; validate eligibility and close times server-side where applicable.
- **Hidden Clues:** optional clues embedded in selected stories. A clue can unlock a bonus scene or explanation; never block the main story for users who do not participate.
- **AUREN Moments:** save a timestamped scene, quote, puzzle, or creator work to a personal searchable library.
- **Audio Adventures:** reuse the existing audio/player infrastructure for original, rights-cleared audio stories and listening progress.
- **Culture Exchange:** themed collections featuring Sudanese, African, and global creators with context, language labels, and moderation.

### Later-stage concepts
- **Remix Engine:** one original brief can produce multiple formats (toon storyboard, short script, audio script, puzzle) while preserving attribution and rights metadata. Generated outputs remain drafts until reviewed.
- **Voice Lab:** original licensed/synthetic character voices with consent and disclosure; no unauthorized impersonation of real people.
- **Story City:** a community-built fictional world with moderated locations, characters, and events.
- **AUREN Versus:** skill- and creativity-based challenges with transparent scoring, anti-spam measures, and accessibility options.
- **Seasonal community events:** opt-in themed events; no loss of core content for people who miss the event.

## Safety, privacy, and healthy engagement

- No manipulative infinite-loop mechanics, shame-based reminders, forced streaks, or fake scarcity.
- Notifications are opt-in, rate-limited, quiet-hours aware where supported, and easy to disable.
- Make watch history and personalization controls visible; allow reset/disable where feasible.
- Avoid exposing private watch activity to friends by default.
- Moderation/report/block controls and creator rights checks are required before broad user-generated publishing.
- For minors, apply age-appropriate discovery, privacy, and safety requirements.
- Track useful quality signals (completion when relevant, saves, satisfaction, hides/reports, creator diversity), not raw watch time alone.
- Use rights-cleared media only; generated content must not be represented as generated if no provider actually produced it.

## Implementation phases

### Phase 0 — Inventory and safeguards
- Confirm current main routing and existing navigation entry points.
- Inspect relevant Firestore rules, repository methods, and tests.
- Identify reusable components and avoid changing unrelated supplier/workflow code.
- Record baseline analyze/test/build results before UI changes.

### Phase 1 — Unified discovery shell
- Add a single entry point and lightweight category navigation using existing screens.
- Include For You, Toon & Stories, Shorts, Play & Puzzles, Creators, and Library as routes or sections only when their destinations are real.
- Add explicit empty/loading/error states and accessibility labels.
- Do not introduce new backend collections until the data contract is agreed.

### Phase 2 — Mood Mixer and Daily Discovery
- Start with deterministic, low-cost selection from existing content metadata.
- Store preferences only when needed and give users control.
- Add unit tests for filtering, fallback behavior, and empty catalogs.

### Phase 3 — Audience Director and Hidden Clues
- Define versioned story/poll/clue models.
- Validate poll closing and vote uniqueness in trusted backend/rules; do not rely only on client checks.
- Add tests for duplicate votes, closed polls, deleted content, and no-clue paths.

### Phase 4 — Moments and Audio Adventures
- Reuse existing save/history/player services where compatible.
- Respect media rights and download/storage limits.
- Add offline support only for content that is explicitly eligible and licensed.

### Phase 5 — Remix, Voice Lab, Story City, and seasons
- Defer until the low-cost MVP demonstrates engagement and moderation capacity.
- Add creator attribution, rights metadata, review workflow, rate limits, and cost controls before enabling generation at scale.

## Acceptance criteria for the first implementation PR

- Only the dedicated entertainment feature paths are changed; no supplier or unrelated workflow files.
- Existing navigation and content flows remain reachable.
- Loading, empty, error, and unauthenticated states are handled.
- No claim of real-time sync or AI media generation unless backed by a working service.
- `flutter analyze`, relevant tests, and Android debug build are run and their actual results reported.
- No PR is opened and nothing is merged until the project owner explicitly approves.

## Current branch implementation status

The current feature branch contains an initial entertainment-universe hub linked from the existing entertainment screen. It links to the existing anime, shorts, watch-together, gaming, podcasts, books/manga, creator, AI-series, live-entertainment, and messaging experiences where available. The hub also surfaces a small rotating selection from the existing entertainment catalog.

The live-entertainment destination reuses the existing catalog and detail screen, and links to the existing radio screen. It only lists catalog entries with a media URL and a live/broadcast type or live-related text; it does not create a streaming backend or imply that a live event is running.

## Remaining validation before review

- Wait for the branch's `flutter_ci` status and inspect its actual result.
- Confirm the feature branch against the latest `main` before proposing integration; it may be behind main.
- Run or confirm `flutter analyze`, relevant tests, and an Android debug build. Do not mark these as passed unless the CI logs show success.
- Test navigation into and back from each destination, catalog loading/empty/error states, and missing-image fallbacks.
- Keep future features such as audience-voted endings, hidden clues, Moments, and Remix clearly marked as planned until implemented.
- Keep the supplier workflow isolated. Do not open a PR or merge without explicit project-owner approval.