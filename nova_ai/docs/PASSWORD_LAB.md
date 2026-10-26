# NOVA Password Lab

Android-first, safety-oriented security utility in the NOVA Flutter app.

## Included in this iteration
- Opens official Google, Facebook, Microsoft and Apple account recovery pages.
- Provides a Wi-Fi router hardening checklist; does not attempt to reveal Wi-Fi credentials or join networks.
- Performs a single HTTPS HEAD request against a public hostname after the user confirms authorization. Reports a small set of response security headers. Redirects are not followed automatically; request timeout is 10 seconds.
- No password guessing, credential harvesting, exploit attempts, port scans, or bypassing authentication.

## Current limitations
- Recovery is delegated to each provider's official process; the app cannot recover or display a provider's existing password.
- Wi-Fi guidance is currently a checklist, not a radio scan. Native Wi-Fi scanning needs Android-specific permissions, runtime consent, handling for OS-version restrictions, and careful privacy disclosure.
- The web check is a lightweight header review, not a comprehensive penetration test. A missing header is not by itself proof of a vulnerability.
- No online scanning backend is configured. The mobile app makes only the explicit request described above and does not send passwords or store target history.

## Verify
From the nova_ai directory:
- flutter pub get
- flutter analyze
- flutter test
- flutter build apk --debug
