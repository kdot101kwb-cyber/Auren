# AUREN Connect Mesh — Architecture and Delivery Plan

## Status

Foundation specification only. This document does not claim that offline transport, multi-hop relaying, or calling has been implemented or tested. Implement in small, testable phases and integrate with the existing Messenger rather than creating a second messaging product.

## Product goal

Enable AUREN users to exchange encrypted messages and files without internet when compatible nearby devices can form a path. Support store-carry-forward relaying over multiple devices where the Android platform and available peer links permit it. Add voice notes before attempting live voice over multiple hops.

## Non-goals and guarantees

- Mesh does not provide global reach by itself. Delivery requires a sequence of available peer contacts or another transport.
- No guarantee of delivery time or eventual delivery when no path forms.
- Live voice over multi-hop links is experimental; latency, jitter, battery, background restrictions, and route changes may make it unusable.
- Do not claim continuous background discovery on Android.
- A nearby transport library is not itself a multi-hop routing protocol.
- No paid relay backend is required for local peer transfer; cloud synchronization remains optional and is used only when internet is available.

## Architecture boundaries

Keep Flutter UI and existing Messenger integration. Isolate platform transports and the relay protocol behind interfaces so transport choices can change without changing chat UI.

Suggested modules (adapt to repository conventions before implementation):

- `OfflineMessageStore`: durable local queue, delivery state, expiry, and retry metadata.
- `PeerTransport`: discover/connect/send/receive and report link capabilities. Initial adapter may use Google Play services Nearby Connections where available.
- `AndroidPeerTransport`: platform-specific fallback experiments using Bluetooth and Wi-Fi Direct where supported; do not assume a single fallback works on every device.
- `MeshRelayEngine`: store-carry-forward queue, duplicate suppression, hop limit, expiry, quotas, scheduling, and route recovery.
- `MessageEnvelope`: versioned encrypted payload metadata, message ID, destination key ID, expiry, hop budget, payload type, and integrity protection.
- `TransferManager`: chunked file transfer, resumability, integrity checks, and quotas.
- `VoiceNoteService`: record, encrypt, chunk, transfer, and play voice notes.
- `MeshPolicy`: user opt-in, battery threshold, charging-only mode, data/storage quotas, contact/group permissions, and stop switch.
- `DeliveryReceipt`: distinguish queued locally, handed to a peer, and acknowledged by recipient.
- `Diagnostics`: privacy-preserving counters and explicit user-visible troubleshooting without collecting location trails or message content.

Names are proposed interfaces, not a claim that these files/classes already exist.

## Transport strategy

1. Prefer a supported nearby-device API for initial Android-to-Android connectivity after checking dependency, device, permission, and Google Play services requirements.
2. Prototype Bluetooth/BLE discovery and Wi-Fi Direct transfer as separate adapters only where needed. Test coexistence, reconnection, permissions, and device compatibility.
3. The relay engine must be transport-agnostic. Each peer link carries an encrypted envelope; the relay engine—not the transport library—decides whether and when to forward it.
4. For devices without Google Play services, validate the direct Android APIs on real devices before promising support.
5. Internet/Firebase synchronization is a separate transport and must never be required for local delivery.

## Relay protocol

- Use cryptographically random message IDs and authenticated, versioned envelopes.
- Encrypt content end-to-end for recipient(s); relays should not possess decryption keys.
- Validate size, format, hop budget, expiry, and storage quota before accepting an envelope.
- Deduplicate by message ID and payload digest; make retries idempotent.
- Apply bounded store-carry-forward: maximum hop count, TTL, queue size, per-peer quota, and retry/backoff limits.
- Do not flood every message to every peer. Start with controlled forwarding to approved peers and evaluate a bounded epidemic-routing policy only with abuse controls.
- Receipts must be authenticated. A peer accepting a message is not proof that the final recipient received it.
- Delete relay copies after authenticated delivery acknowledgement or expiry according to a documented retention policy.
- Protect against malicious relays that drop, delay, replay, or selectively forward messages; encryption does not solve availability or metadata leakage.
- Group membership changes and revocation require an explicit key-management design; a device offline during revocation may retain previously received content.

## Content types and rollout

### Phase 0 — Repository and Messenger integration audit
- Inspect current chat models, storage, dependencies, Android manifest, permission handling, and CI.
- Reuse existing message IDs, identity, and delivery UI where appropriate.
- Document conflicts and do not modify unrelated systems.

### Phase 1 — Offline-first text foundation
- Persist outgoing messages locally and expose queued/sending/delivered/expired states.
- Keep current online sync behavior when internet returns.
- Unit-test queue transitions and idempotent sync before adding peer transport.

### Phase 2 — Direct peer transport
- Connect two compatible Android devices without internet.
- Exchange one encrypted text envelope and authenticated receipt.
- Include permission denial, disconnect, app restart, duplicate, and malformed-envelope cases.

### Phase 3 — Multi-hop relay
- Test A → B → C with no direct A-to-C link.
- Persist envelopes across process restarts and forward only when a permitted link becomes available.
- Enforce TTL, hop count, storage limits, deduplication, and opt-in relay policy.
- Test changing and unavailable paths. Do not advertise distant delivery until real-device tests pass.

### Phase 4 — Files and voice notes
- Transfer small files first; then chunk and resume larger files.
- Verify each chunk and whole-file digest; reject unexpected content and enforce quotas.
- Add encrypted voice notes using the same transfer pipeline.

### Phase 5 — Live voice experiments
- First validate a direct local voice call between two devices.
- Measure latency, jitter, packet loss, route stability, reconnection, and battery.
- Multi-hop live voice remains experimental until performance gates are met; store-and-forward voice notes are the reliable offline baseline.

### Phase 6 — Community and convenience features
- Local community bulletin and emergency alerts with source, timestamp, anti-spam limits, and clear unverified status.
- QR/contact key pairing with short authentication code.
- Local-only language assistance only if a suitable model runs within target device memory and storage.
- Optional relay contribution settings and transparent battery/storage controls.
- Local connection-quality estimates must not become user location tracking.

## Android constraints and permissions

- Confirm minimum/target SDK and current Flutter/Gradle versions before selecting APIs or dependencies.
- Request only the Bluetooth, nearby Wi-Fi, microphone, and notification permissions required by the selected APIs and OS versions.
- Respect Android background execution and foreground-service restrictions. Show clear controls and notifications where required.
- Handle Doze, battery optimization, process death, reboot, permission revocation, and vendor-specific task killing.
- No microphone use until the user starts a voice feature; no hidden continuous recording.
- Keep network and battery use bounded and visible.

## Security requirements

- End-to-end encryption with authenticated recipient identity and a reviewed key lifecycle.
- Android Keystore protection for local key material where applicable.
- Encrypted local message storage; exclude secrets and plaintext content from logs.
- Do not share a user's contact list, location history, or message content with relays.
- Safe payload limits, rate limits, file-type validation, and spam/abuse controls.
- Threat-model malicious peers, replay, impersonation, storage exhaustion, traffic analysis, and denial of service before production release.
- Use established cryptographic libraries/protocols; do not invent custom cryptography.

## Test and acceptance plan

1. Unit tests: queue transitions, TTL, hop budget, deduplication, retries, quotas, and receipt validation.
2. Integration tests: transport disconnect/reconnect, malformed packets, duplicate packets, interrupted chunks, and restart recovery.
3. Security tests: unauthorized recipient cannot decrypt; replayed envelopes are not delivered twice; corrupt chunks fail integrity checks; oversized payloads are rejected.
4. Real-device matrix: at least three physical Android devices for A → B → C relay, with internet disabled and Bluetooth/Wi-Fi state recorded.
5. Lifecycle matrix: screen off, process killed, app restarted, battery saver, permission denied/revoked, and device reboot.
6. Performance measurements: message delivery success across repeated trials, delivery delay, file throughput, storage growth, and battery drain.
7. CI: Flutter analyze, unit tests, Android debug build, and transport-specific tests where runners support them. Hardware-dependent tests must be reported separately and never marked passed without execution.

### Initial acceptance gates

- Two-device offline text exchange succeeds on documented compatible devices.
- Three-device A → B → C store-carry-forward succeeds without a direct A-to-C connection.
- No duplicate user-visible message under retry/replay tests.
- Relay cannot decrypt private content.
- File transfer resumes and integrity verification rejects corrupted data.
- Battery/storage/permission behavior is documented from physical-device tests.
- Existing Messenger tests and Android build remain green.

## Feature backlog

- Living Mesh: route selection and recovery based on link availability, not hidden tracking.
- Message Capsules: encrypted, versioned, bounded envelopes.
- Smart Power Mesh: opt-in charging-only and battery threshold policies.
- Split & Resume: chunked resumable files.
- Community Alert: signed/source-labelled local announcements and abuse controls.
- Mesh Walkie-Talkie: direct local push-to-talk experiment.
- Local World: offline community bulletin board, later synchronized online.
- Trust Pairing: QR and short-code key verification.
- Offline Language Bridge: optional on-device translation when feasible.
- Personal Offline Space: local notes, drafts, trusted contacts, and files.
- Smart Route Recovery: bounded retry and alternate-path selection.
- Community Relay Rewards: future optional feature only after anti-fraud and privacy review; never required to relay.

## Release policy

Do not merge or declare completion until the owner approves the change and CI evidence is reviewed. Do not claim a feature is implemented merely because this specification exists.
