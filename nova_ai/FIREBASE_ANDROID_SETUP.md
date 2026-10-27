# NOVA Android — Firebase build setup

NOVA can build without Firebase client configuration, but Firebase-backed features will not connect until the Android build receives the matching Firebase app options.

## Configure GitHub Actions

1. Open the repository on GitHub.
2. Go to **Settings → Secrets and variables → Actions**.
3. Add the following repository **Variables** (or Actions secrets if you prefer). Use the values from the Firebase project and the registered **Android app** for NOVA; do not guess or copy values from an unrelated Firebase app.

| Name | Firebase source |
| --- | --- |
| `FIREBASE_API_KEY` | Project settings → General → NOVA Android app |
| `FIREBASE_APP_ID` | Project settings → General → NOVA Android app |
| `FIREBASE_MESSAGING_SENDER_ID` | Project settings → General |
| `FIREBASE_PROJECT_ID` | Exact Firebase project ID |
| `FIREBASE_STORAGE_BUCKET` | Optional; the bucket shown in project settings |

The workflow accepts the first four required values from Actions variables or secrets. If `FIREBASE_PROJECT_ID` is absent, it currently defaults to `auren-90ccc`; explicitly set it if NOVA should target another project. Storage bucket is optional.

4. Open **Actions → NOVA Android Build → Run workflow** (or push a change under `nova_ai/`).
5. Inspect the **Report Firebase build configuration** step. It should report that configuration is complete.
6. Download the `nova-ai-debug-apk` artifact and install it on a test Android device.

## App Check

The current Dart runtime selects the App Check debug provider for debug builds and Play Integrity for non-debug builds. If App Check enforcement is enabled, register the debug token printed by the debug app in Firebase Console → App Check for the correct Android app. Treat that token as sensitive and do not commit it. A production/release build should be tested separately with Play Integrity configured.

## Security notes

- Never commit service-account JSON files, private keys, Admin SDK credentials, or user tokens.
- Firebase client options are app configuration, not a substitute for security. Protect data with Firebase Authentication, least-privilege Firestore/Storage rules, and appropriate App Check enforcement.
- A successful APK build only proves compilation. It does not prove Firebase Authentication, Firestore, Cloud Functions, or App Check works at runtime.
- Do not deploy Firebase rules or functions to production as part of this setup. Validate in staging and review any deployment separately.

## Verification checklist

- [ ] The workflow reports Firebase configuration complete.
- [ ] The artifact is built from the intended commit and Firebase project.
- [ ] App starts on a real Android device.
- [ ] Authentication works for an authorized test account (if enabled).
- [ ] Each Firebase-backed feature is exercised against the intended staging/test project.
- [ ] Firestore rules and App Check behavior are checked; no privileged credentials are embedded in the APK.
