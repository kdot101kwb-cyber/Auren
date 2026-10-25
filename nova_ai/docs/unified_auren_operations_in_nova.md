# NOVA AI — Unified AUREN Operations Integration

## Objective
NOVA AI is the single user-facing command center for operating AUREN. Every capability must be reachable through a shared task, identity, permission, provider, status, cost, and audit model. Individual screens must not pretend to be connected merely because a card or button exists.

## Capability map
| Capability | NOVA entry point | Required production services | Current state |
|---|---|---|---|
| Executive command center | Home / agents | Authenticated task API, durable queue, orchestrator, task events | Authenticated task intake/status/approval/cancel APIs added; NOVA client and execution worker still missing |
| AI gateway and agent routing | Manager / agent runtime | Callable/server API, provider adapters, server-side secrets, quotas, fallback policy | Backend provider code exists; NOVA client integration not complete |
| Opportunity intelligence | Revenue lab / alerts | Search/news sources, ingestion scheduler, provenance, scoring, Firestore inbox, optional FCM | Scoring + scheduled monitor exist; ingestion and mobile inbox missing |
| Content factory | Creative studio | LLM, image/video generation providers, asset storage, job polling/webhooks | UI only; no live media generation configured |
| Social publishing | Marketing center | Official platform APIs or validated publishing aggregator, OAuth, media upload, scheduled queue | Platform list/spec only; no verified OAuth or live publishing |
| AUREN engineering operator | AUREN tab | GitHub App/OAuth, least-privilege repository operations, CI run/status APIs, approval gates | Repository link only; no in-app authenticated operator yet |
| Integration automation | Integration hub | n8n or equivalent, signed webhooks, connector health checks, retries/idempotency | Hub status UI added; connectors are not live |
| Finance and revenue | Opportunity/finance | Actual platform analytics, tracked spend, transaction imports or approved finance APIs | Estimation/scoring only; no verified finance source |
| Memory, notifications, audit | Home/activity | Auth-scoped storage, user preferences, FCM/email/Telegram, append-only audit | Partial backend patterns; no end-to-end NOVA workflow |
| Reliability and security | All capabilities | App Check, auth, server-side secrets, rate limits, observability, CI + integration tests | Must be validated before production claims |

## Shared execution contract
All agent actions should flow through one server-side orchestrator rather than calling external services directly from Flutter.

1. Client submits an intent with an idempotency key and the user's authenticated identity.
2. Server validates auth, App Check where applicable, input schema, user permissions, provider availability, and budget.
3. Server creates a durable task with queued status and an audit event.
4. Worker transitions through collecting, analyzing, awaiting_approval, running, and succeeded / failed / cancelled.
5. Side effects (publish, send, purchase, delete, paid ads, financial commitments) require a specific approval record or a narrowly scoped owner-defined policy.
6. Results, evidence URLs, timestamps, provider, cost, retry count and error summary are persisted and returned to NOVA.
7. NOVA renders live task state and alerts from the authenticated backend; local-only state must be labeled as such.

## Provider requirements
- Keep API keys and OAuth refresh tokens in Firebase Secret Manager or a suitable server-side secret store. Never embed secrets in APK or commit them.
- Each provider adapter must expose capabilities, scopes, connection health, quotas, pricing, last successful test, and revocation status.
- Fail closed when credentials are missing, scopes are insufficient, or the paid-cost ceiling would be exceeded.
- Apply timeouts, bounded retries with jitter, circuit breakers, concurrency limits, deduplication, and idempotency keys.
- Respect official platform API rules, eligibility, content policies, and rate limits. Aggregators do not bypass platform restrictions.
- Mark a connector as connected only after a live authenticated health check and a safe capability-specific test.

## Recommended delivery sequence
### Phase 1 — Foundation
- [x] Add authenticated callable endpoints for task submission, listing, status, owner approval and cancellation, with per-user task storage, idempotency and audit events.
- [x] Add a scheduled queue worker for safe text tasks (`chat`, `plan`, `research`, `content_draft`) using the server-side `OPENROUTER_API_KEY` secret, retry handling, persisted results, and audit events.
- [x] Add pure validation tests for task type, prompt bounds, idempotency key and approval requirements.
- [x] Add Firebase Auth/Functions/Firestore/App Check dependencies, configurable Firebase bootstrap, and a NOVA task center that calls submit/list/approve/cancel APIs.
- [ ] Supply project-specific Firebase compile-time values, enable Anonymous Auth, configure the `OPENROUTER_API_KEY` Firebase secret, deploy Functions, and validate App Check on the real Android app.
- Fix the failing backend CI and verify Flutter analyze/test/Android build.
- Add Firebase configuration and Firebase Auth to NOVA with a clear unauthenticated state.
- Define task/event/audit schemas and callable endpoints; add authorization and App Check.
- Add secrets setup instructions without adding actual credentials to the repository.

### Phase 2 — Live NOVA command center
- Replace local checkbox task state with authenticated Firestore task streams.
- Add task creation, status, retry/cancel where safe, logs, and notification preferences.
- Connect the existing AI gateway through a secure callable endpoint and enforce provider/cost policies.

### Phase 3 — Opportunity pipeline
- Select a search source and configure its key server-side.
- Build a rate-limited ingestion adapter that writes source-backed signals with URL, observed time and trust metadata.
- Wire settings and alert inbox to Firebase; test one real alert end-to-end before enabling scheduled production scans.
- Add optional FCM only after token registration and notification permissions are implemented.

### Phase 4 — Creation and distribution
- Integrate one image provider and one video provider behind job-based adapters and storage.
- Integrate one publishing path first (Buffer or one official platform API), including OAuth, media upload, scheduling, post status, and analytics.
- Expand to other platforms only after an end-to-end authorized test for each.

### Phase 5 — Engineering, automation, and finance
- Add GitHub App/OAuth with least privilege; read workflow status before enabling proposed changes.
- Connect n8n using signed webhooks and a visible health check.
- Import real analytics and costs; distinguish actual revenue from estimates and show contribution margin.
- Add rollback, incident alerting, retention policy, and operational dashboards.

## Completion criteria
A capability is complete only when an authenticated end-to-end test proves: request → server execution → persisted result → NOVA UI update → audit event → failure/retry behavior. A passing unit test or a visible UI alone does not establish a live integration.

## Current implementation note
The backend now exposes `submitNovaTask`, `listNovaTasks`, `getNovaTask`, `approveNovaTask`, and `cancelNovaTask`. These persist per-user task state and audit events. A scheduled worker now claims queued text tasks (`chat`, `plan`, `research`, `content_draft`), calls OpenRouter's free-model route using a server-side secret, stores the result, retries transient failures up to three attempts, and writes audit events. Unsupported types fail explicitly rather than remaining queued forever. This worker does not yet perform web search, media generation, social publishing, GitHub changes, or financial transactions. The Flutter app now includes a Firebase bootstrap and task-center client. It deliberately remains disconnected unless build-time Firebase identifiers are supplied (`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, optional `FIREBASE_STORAGE_BUCKET`); enable Anonymous Auth and configure Android Play Integrity/App Check in Firebase. No credentials were added to source control.

The NOVA Flutter package currently declares only Flutter, Cupertino icons, and url_launcher. It does not yet declare Firebase Flutter SDK packages or generated Firebase options. The new Integration Hub is a transparent status/catalog screen; its setup links do not connect accounts automatically. External providers, Firebase client configuration, OAuth consent, secrets, deployment, and live tests remain required.