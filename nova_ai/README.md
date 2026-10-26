# NOVA AI Android

Arabic-first Flutter control-center starter for NOVA AI agents and AUREN project management.

## Current scope
- Dashboard and local task checklist
- Planned agent roles (not yet autonomous)
- AUREN repository and roadmap shortcuts
- Activity/status page with explicit prototype limitations

## Strategic debate and opposition
The agents hub includes a strategic review screen backed by the Firebase callable `novaStrategicDebate`. It asks the server-side AI provider to review a decision through engineering, quality, security/privacy, and cost/performance perspectives, and returns bounded objections, alternatives, risks, missing evidence, and a plan with verification criteria. These are four perspectives from one model call, not four independent agents.

- Strategy is fixed to strategic trade-off analysis; execution policy is agreement-first.
- Requests require Firebase Authentication and are rate-limited. Debate records and approval audit entries are stored under the authenticated user's private Firestore path.
- Configure the Firebase Secret Manager value `OPENROUTER_API_KEY` before deploying the callable. The key is never sent to the mobile app.
- A user can explicitly approve a proposed plan; the backend records that approval. **This first slice does not execute repository changes**: the safe repository-editing executor, diff validation, and post-change CI verification still need to be connected. The UI reports this limitation rather than pretending work ran.
- AI-generated objections and estimates are suggestions, not verified facts. Supply concrete logs, repository evidence, and test results in the context field when available.

## Creative studio
The app now includes a UI for preparing image, video, and game-generation requests. This is a front-end flow only: it does not generate media or compile games yet. Real output requires a server-side provider adapter, secure credentials, asynchronous job tracking, file storage, and cost/abuse controls. “Unlimited” can mean no app-imposed daily cap, but provider and infrastructure limits still apply.

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
