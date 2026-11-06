# NOVA Android APK build evidence

The `NOVA Android Build` workflow generates the Flutter Android host inside `nova_ai/`, installs dependencies, analyzes the Dart package, runs Flutter tests, and builds a debug APK.

The pull-request trigger now covers every base branch, including stacked NOVA feature branches. The APK step verifies that the output exists and is non-empty, then publishes a SHA-256 checksum beside the APK artifact.

## Artifact retrieval

Open the successful GitHub Actions run for the exact commit and download the `nova-ai-debug-apk` artifact. The artifact is temporary and has a 14-day retention period.

## What a green build proves

It proves that the generated Android host compiled for that commit and that the configured analysis/tests passed. It does not prove that Firebase Functions are deployed, Firebase credentials are configured, owner authentication is provisioned, or every remote feature is operational. If Firebase build configuration is absent, the APK may still build while cloud-backed features remain unavailable.

This workflow creates an unsigned debug APK for testing, not a Play Store release or a production-signed installer.
