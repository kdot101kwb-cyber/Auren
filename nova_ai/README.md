# NOVA AI Android

Arabic-first Flutter control-center starter for NOVA AI agents and AUREN project management.

## Current scope
- Dashboard and local task checklist
- Planned agent roles (not yet autonomous)
- AUREN repository and roadmap shortcuts
- Activity/status page with explicit prototype limitations

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
