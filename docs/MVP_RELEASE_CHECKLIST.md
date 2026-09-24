# AUREN MVP release checklist

## Product foundation
- [x] Android-first Flutter shell
- [x] Home / Pulse / Discover / Messenger / Profile navigation
- [x] Firebase initialization with setup fallback
- [x] Global Flutter error surface
- [x] Personal AI context (goals + enabled memory)
- [x] Approval-gated AUREN Actions

## Social & communication
- [x] Profiles
- [x] Follow graph
- [x] Posts / timeline foundation
- [x] Messenger conversation foundation
- [x] Presence heartbeat
- [x] Notifications foundation

## Trust & agent security
- [x] Server-controlled action lifecycle
- [x] Server-controlled agent lifecycle
- [x] Server-controlled permission ledger
- [x] Action audit / trust records
- [x] Explicit approval + separate execution confirmation
- [x] Cancellation and recovery paths
- [x] Plugin capability validation
- [x] Plugin payload / artifact bounds
- [x] Plugin daily quota (10,000 invocations)
- [x] Isolated plugin worker with non-root container
- [x] Deterministic action side effects and execution records

## CI / verification
- [x] Flutter format gate
- [x] Flutter analyze gate
- [x] Flutter test gate
- [x] Android debug build gate
- [x] Functions syntax + tests
- [x] Action Executor tests
- [x] Plugin Worker tests
- [x] Plugin Worker Docker build

## Before public production
- [ ] Run the complete CI workflow on GitHub and resolve any environment-specific failures
- [ ] Configure Firebase production project and deploy Functions / Rules
- [ ] Configure App Check and production authentication providers
- [ ] Configure crash/error monitoring
- [ ] Configure analytics with privacy controls
- [ ] Perform device testing on supported Android versions
- [ ] Verify offline / low-data behavior on real networks
- [ ] Load-test feeds, messaging and backend callables
- [ ] Complete legal/privacy/terms review
- [ ] Produce signed release APK/AAB

> This checklist separates code already present in the repository from deployment and operational work that requires the actual Firebase/Google Play environments.
