# NOVA AI Android

Arabic-first Flutter control-center starter for NOVA AI agents and AUREN project management.

## In-app app-building toolkit

NOVA now has a searchable catalogue of developer tools grouped by app development, UI design, backend/API, CI/build, games/3D, media generation, automation/AI, and publishing/marketing. Compatible HTTPS sites open in an in-app WebView, with a system-browser fallback when a provider blocks embedding or requires an external sign-in.

This is a unified entry point, **not** a claim that all listed products are installed, API-connected, or runnable inside NOVA. Desktop tools such as Blender, Godot, Unity, FFmpeg, and local coding agents require a compatible device or remote worker. Real code edits, tests, builds, publishing, and account actions require separate secure integrations, authorization, and verified results. Provider terms, regional availability, free quotas, and billing can change.

Security rules:
- Never store API secrets or long-lived tokens in the Android app.
- Use provider-approved OAuth/API flows and a trusted backend for secret-bearing operations.
- Ask the user before repository writes, publishing, messaging, purchases, or other external side effects.
- Treat a successful WebView load as browsing only, not as an API connection or completed build.

## Current scope
- Dashboard and local task checklist
- Planned agent roles (not yet autonomous)
- AUREN repository and roadmap shortcuts
- Activity/status page with explicit prototype limitations
- Searchable in-app developer-tool catalogue

## Strategic debate and opposition
The private AUREN management dashboard includes a strategic review screen backed by the Firebase callable `novaStrategicDebate`. The meeting agenda covers engineering, quality, cybersecurity/privacy, growth and user acquisition, global market/competitor research, legal/compliance/governance, and cost/performance. These are structured perspectives from one model call, not independent agents, and the model does not automatically fetch live market evidence unless source data is supplied.

- Strategy is fixed to strategic trade-off analysis; execution policy is agreement-first.
- Requests require Firebase Authentication and are rate-limited. Debate records and approval audit entries are stored under the authenticated user's private Firestore path.
- Configure the Firebase Secret Manager value `OPENROUTER_API_KEY` before deploying the callable. The key is never sent to the mobile app.
- Approval is not execution: the safe repository-editing executor, diff validation, and post-change CI verification still need to be connected.
- AI-generated objections and estimates are suggestions, not verified facts. Supply concrete logs, repository evidence, and test results in the context field when available.

## Creative studio
The app includes a UI for preparing image, video, and game-generation requests. This front-end flow does not itself generate media or compile games yet. Real output requires server-side provider adapters, secure credentials, asynchronous job tracking, file storage, and cost/abuse controls.

## Global multilingual opportunity radar
The radar searches public listings from Remotive and Arbeitnow, supports Unicode queries and multilingual keyword presets, ranks recent/remote listings, and stores saved leads locally on the phone. Sources are limited and do not form an exhaustive global job index. Check eligibility, payment method, identity requirements, deadlines, and fees at the original source before applying. Fresh searches need network access; saved listings remain available locally offline.

## Important limitations
NOVA remains a prototype for several workflows. It does not yet fully execute GitHub changes, remotely build every project type, manage email/social accounts, or synchronize all task state. Those capabilities require a secure backend, official OAuth/API integrations, least-privilege access, audit logs, and real CI verification. Do not place GitHub tokens or provider API secrets in the mobile app.

## Firebase configuration for Android builds
The Android workflow passes Firebase configuration into Flutter with `--dart-define`; it does not embed provider AI secrets. Configure the GitHub Actions variables `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, and `FIREBASE_PROJECT_ID` (optional `FIREBASE_STORAGE_BUCKET`) for the intended Android app. These are not a substitute for Security Rules, Authentication, App Check, or server authorization.
