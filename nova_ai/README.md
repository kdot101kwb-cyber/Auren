# NOVA AI Android

Arabic-first Flutter control-center starter for NOVA AI agents and AUREN project management.

## Current scope
- Dashboard and local task checklist
- Planned agent roles (not yet autonomous)
- AUREN repository and roadmap shortcuts
- Activity/status page with explicit prototype limitations

## Strategic debate and opposition
The private AUREN management dashboard includes a strategic review screen backed by the Firebase callable `novaStrategicDebate`. The meeting agenda covers engineering, quality, cybersecurity/privacy, growth and user acquisition, global market/competitor research, legal/compliance/governance, and cost/performance. It asks for objections, alternatives, evidence gaps, and day/week/month plans with measurable success criteria. These are structured perspectives from one model call, not independent agents, and the model does not automatically fetch live market evidence unless source data is supplied.

- Strategy is fixed to strategic trade-off analysis; execution policy is agreement-first.
- Requests require Firebase Authentication and are rate-limited. Debate records and approval audit entries are stored under the authenticated user's private Firestore path.
- Configure the Firebase Secret Manager value `OPENROUTER_API_KEY` before deploying the callable. The key is never sent to the mobile app.
- The dashboard now exposes an explicit **Approve proposed plan** control and calls `novaApproveDebatePlan`; the backend records the decision and an audit entry. **Approval is not execution**: the safe repository-editing executor, diff validation, and post-change CI verification still need to be connected. The UI states this limitation rather than pretending work ran.
- AI-generated objections and estimates are suggestions, not verified facts. Supply concrete logs, repository evidence, and test results in the context field when available.

## Creative studio and NOVA Game Studio
The creative studio includes a first local game-starter generator. Given a game idea, NOVA creates text for three Godot 4 starter files (`project.godot`, `main.tscn`, and `main.gd`) and lets the user copy each file. It also lists ten curated free/open-source game-development tools and opens their GitHub repositories.

**Important boundary:** this is starter-code generation, not autonomous end-to-end game production. The Flutter app does not currently install or run Godot/Blender, create full art/audio assets, execute playtests, or export an Android APK. To reach that goal, the next stages are a sandboxed project workspace, a compatible local/remote Godot build runner, generated asset pipelines, automated test/playtest feedback, and artifact delivery. Any runner must use explicit permissions, resource limits, logs, and user approval before external actions. The current generator is local and does not require a paid AI API, but it is a deterministic starter template rather than an AI model that understands arbitrary game designs.

## Global multilingual opportunity radar

The home dashboard and all-sections menu now open **NOVA Global Opportunity Radar**. It searches public listings from Remotive and Arbeitnow, supports Unicode queries and multilingual keyword presets, ranks recent/remote listings, and stores saved leads locally on the phone.

- Current sources are limited to these public job APIs; this is not an exhaustive global job index or a full translation engine.
- Search filters are discovery aids only. Every listing must be checked at its original source for country eligibility, language, identity requirements, payment method, deadlines, and fees—especially before applying from Sudan.
- The feature does not apply for jobs, create accounts, contact employers, or pay fees.
- Network access is required for fresh searches. Saved listings remain available locally when offline.

## Important limitations
The app is currently a UI prototype. It does not yet execute GitHub changes, run builds remotely, manage email/social accounts, or synchronize task state. Those capabilities require a secure backend, official OAuth/API integrations, least-privilege access, and audit logs. Do not place GitHub tokens or provider API secrets in the mobile app.

## Offline-first AI and GitHub research
The architecture plan and curated review of 20 related open-source projects are in [offline-first research](docs/offline_first_and_20_projects.md). This is research and a delivery plan, not a claim that all projects or their features have been integrated. Current prototype limitations still apply.


## Firebase configuration for Android builds

The Android workflow passes Firebase configuration into Flutter with `--dart-define`; it does not embed provider AI secrets. To configure Firebase-backed screens, a repository maintainer must add these GitHub Actions **Variables** under **Settings → Secrets and variables → Actions → Variables**:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- Optional: `FIREBASE_STORAGE_BUCKET`

Use the values for the registered Android app in the intended Firebase project. These are app configuration values, not a substitute for Firebase Security Rules, Authentication, App Check, or server authorization. The workflow warns but still builds if the required variables are missing; in that case the app intentionally shows that Firebase is not configured and cloud-backed revenue/signal features cannot run.

Before using the revenue engine, the Firebase project owner must also:
1. Enable **Anonymous Authentication** if this app continues to use anonymous sign-in.
2. Register/configure Android App Check for the app's actual distribution method and verify App Check enforcement is compatible with testing; do not disable enforcement in production merely to bypass errors.
3. Deploy the Cloud Functions from the repository's `functions` directory after reviewing the target project and required APIs.
4. Set `OPENROUTER_API_KEY` in Firebase Secret Manager for the server-side revenue functions. Never put this provider key in GitHub source, `--dart-define`, or the APK.
5. Confirm Firestore rules and billing/quota limits before enabling the daily scheduler.

**Deployment is not automatic from the Android build.** A green APK workflow proves the app compiled and tests passed; it does not prove Firebase is configured or deployed, that the AI provider key exists, or that a daily report can be generated. Do not enable the scheduled engine until those checks pass.

## Build and install on Android
The repository workflow **NOVA Android Build** runs dependency resolution, static analysis, Flutter tests, and creates a debug APK. When the workflow succeeds:
1. Open [NOVA Android Build workflow runs](https://github.com/kdot101kwb-cyber/Auren/actions/workflows/nova-android-build.yml).
2. Open the latest successful run for branch `feat/nova-ai-android-app`.
3. In **Artifacts**, download `nova-ai-debug-apk` and extract the ZIP.
4. On the Android phone, open `app-debug.apk` and approve installing from that source if Android asks.

A debug APK is for testing, not a signed production release. Do not install an APK unless the build run is successful and its branch/commit is the intended one. The workflow artifact is temporary (14 days).

Build locally from this directory:
```sh
flutter create --platforms=android --org com.kwb86 --project-name nova_ai .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

AUREN repository: https://github.com/kdot101kwb-cyber/Auren
Roadmap: https://github.com/kdot101kwb-cyber/Auren/issues/282
