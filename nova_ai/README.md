# NOVA AI Android

Arabic-first Flutter control-center starter for NOVA AI agents and AUREN project management.

## Current scope
- Dashboard and local task checklist
- Planned agent roles (not yet autonomous)
- AUREN repository and roadmap shortcuts
- Activity/status page with explicit prototype limitations

## Creative studio
The app now includes a UI for preparing image, video, and game-generation requests. This is a front-end flow only: it does not generate media or compile games yet. Real output requires a server-side provider adapter, secure credentials, asynchronous job tracking, file storage, and cost/abuse controls. “Unlimited” can mean no app-imposed daily cap, but provider and infrastructure limits still apply.

## Important limitations
The app is currently a UI prototype. It does not yet execute GitHub changes, run builds remotely, manage email/social accounts, or synchronize task state. Those capabilities require a secure backend, official OAuth/API integrations, least-privilege access, and audit logs. Do not place GitHub tokens or provider API secrets in the mobile app.

## Build
From this directory with Flutter stable installed:
```sh
flutter create --platforms=android --org com.kwb86 --project-name nova_ai .
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The repository workflow creates the Android host, runs analysis and tests, builds a debug APK, and uploads it as a GitHub Actions artifact. A debug APK is for testing, not a signed production release.

AUREN repository: https://github.com/kdot101kwb-cyber/Auren
Roadmap: https://github.com/kdot101kwb-cyber/Auren/issues/282
