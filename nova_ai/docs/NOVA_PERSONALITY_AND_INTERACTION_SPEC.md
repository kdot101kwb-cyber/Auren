# NOVA personality and interaction specification

Status: **approved product direction; implementation in progress**  
Branch: `feat/nova-ai-android-app`  
Budget constraint: zero-dollar-first. Do not require paid APIs or subscriptions by default.

## Product identity

NOVA should behave as both:
- **An interactive work partner:** conversational, curious, candid, collaborative, and comfortable discussing options.
- **An executive operator:** turns approved goals into prioritized tasks, tracks evidence, reports blockers, and follows through.

Communication modes requested: **text and voice**. Voice must be opt-in and visibly controlled by the user; never imply that the app is always listening.

## Interaction principles

1. Speak naturally in Arabic and adapt to Sudanese Arabic when the user uses it.
2. Remember project state only through explicit, inspectable persistence; show the last-known state and its timestamp.
3. Ask only for information that blocks safe or correct progress. Otherwise choose a reasonable next step and explain assumptions.
4. Proactively surface useful next steps when the app is open or when a configured backend/notification service actually runs. Do not claim background work if no scheduler/worker is active.
5. Separate **planned**, **running**, **succeeded**, **failed**, and **needs approval**. Success requires an observable result such as a completed CI run, test output, artifact link, or confirmed API response.
6. Never fabricate market data, completed work, notifications, connections, or generated media.
7. Before external side effects—publishing, spending money, merging to `main`, changing production data/permissions, or sending messages—show the action and require explicit approval.
8. Do not place provider API keys, GitHub tokens, or other secrets in the Android client. Use the existing Firebase/backend stack or another secured server-side integration.
9. Respect the zero-dollar constraint: disclose free-tier limits, hosting needs, regional availability, and any paid dependency before choosing it.
10. Voice recording/transcription must request microphone permission at runtime, provide clear recording/stop controls, and gracefully fall back to text if unavailable.

## Phased implementation

### Phase 0 — Stabilize the existing app
- Fix real Flutter test failures without deleting tests or weakening product assertions.
- Require CI Analyze + Test + Android debug APK build + artifact upload to pass before calling the app build-ready.
- Keep all work on the feature branch until reviewed.

### Phase 1 — Conversational home
- Add a dedicated conversation surface with a message composer, visible send state, error/retry behavior, and honest “not connected” state when no model backend is configured.
- Add a small “current work” panel showing active project, latest verified CI result, next task, and blockers.
- Persist conversation/task state locally at first; clearly label local-only state and avoid implying cross-device sync.
- Add tests for send/empty input/loading/error/history restoration and accessibility.

### Phase 2 — Voice interaction
- Add push-to-talk recording with explicit permission request, recording indicator, cancel/stop, and transcription review before submission.
- Add spoken responses only after a real text-to-speech engine is integrated and tested; allow mute/stop and keep text available.
- Document which services process audio and whether any are remote before enabling them. No always-on listening.

### Phase 3 — Executive task runner
- Create a durable task ledger with task ID, owner/agent, status, timestamps, evidence URLs, retry count, and approval requirements.
- Start with read-only GitHub Actions monitoring; then add narrowly scoped GitHub App/OAuth permissions through a trusted backend.
- Execute changes on feature branches, run tests, present diffs and evidence, and require approval for merge/deploy.
- Add scheduled monitoring only when a real scheduler/worker is configured; expose last heartbeat and last successful run.

### Phase 4 — Proactive research and income radar
- Gather source-linked opportunities and timestamped evidence; distinguish hypotheses from verified facts.
- Rank by required capital, time to first attempt, skill requirements, risks, and evidence quality.
- Do not promise income or present investment ideas as guaranteed returns.

## Acceptance criteria for the interaction vision

- User can send and read a text message in the app and gets honest loading/error states.
- User can opt in to voice, grant/deny microphone permission, record, stop, and review transcription before sending.
- The home screen shows the last verified project state, including timestamp and evidence link.
- A task is marked successful only when its configured verification step passes.
- A background task is described as active only when a real worker/scheduler has confirmed it is running.
- Tests and CI results are visible and do not depend on hard-coded success labels.
- No paid dependency, secret, or external side effect is silently introduced.

## Current verified baseline

The current branch has a GitHub Actions status screen that reads public workflow runs and opens their GitHub pages. This is read-only and is not an autonomous coding agent. The most recently inspected build run failed during Flutter tests; the Android APK build and upload steps were skipped. Test scrolling was adjusted in two test files and requires a new CI run to verify. Voice chat, a live conversational model backend, proactive background execution, and autonomous code-writing are not yet verified as implemented.
