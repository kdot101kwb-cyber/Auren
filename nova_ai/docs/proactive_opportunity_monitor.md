# NOVA proactive opportunity monitor

## What is implemented
- A scheduled Firebase Cloud Function scans every six hours.
- It scores source-attributed opportunity records using demand, trend, monetization path, evidence strength, source trust, competition, execution cost, and freshness.
- It refuses alerts when evidence/source trust is weak or the signal is older than 14 days.
- It filters by each authenticated user's optional topic/region preferences and score threshold.
- Alerts are deduplicated per user and source signal in `users/{uid}/proactive_opportunities`.
- `saveOpportunityMonitorSettings` stores an authenticated user's monitoring preferences.

## Important limits
This is a proactive **monitoring and ranking pipeline**, not yet a connected global crawler. A trusted ingestion adapter must populate `market_opportunity_signals` with `monitoringEligible: true`, title, HTTPS sourceUrl, observedAt, demand, trend, monetization, evidenceStrength, competition, executionCost, and sourceTrust. Records without verifiable provenance are excluded. No source API keys belong in the mobile app.

The current NOVA Flutter shell does not yet include Firebase Authentication/Cloud Functions/Firestore dependencies or a live alerts inbox, so the user-facing enable/alerts workflow must be wired before this is usable end-to-end. The scheduled function must be deployed to Firebase; a Git commit or passing CI does not deploy it. Push notifications also require an approved FCM token flow.

## Next production steps
1. Choose and configure licensed market/search sources in server-side secret storage.
2. Build ingestion adapters with source URL, timestamp, provenance and rate limits.
3. Connect NOVA authentication and invoke `saveOpportunityMonitorSettings`.
4. Add a Firestore alerts inbox and optional FCM notifications.
5. Deploy functions, run integration tests, and verify one real source-backed alert end-to-end.

No alert guarantees income. The monitor recommends small, measured experiments; it must not spend money, publish content, or contact prospects without separate user authorization.
