# NOVA Offline-Phone Autonomy and Social Publishing Plan

Status: implementation plan, not a claim that unattended publishing is already active.

## User outcome
The owner may be offline or have the phone switched off while NOVA continues pre-authorized work. The phone is a control/monitoring client; it must not be the only runtime for jobs expected to continue.

## Required architecture
1. **Control app (Flutter):** create tasks, set schedules and publishing policy, view evidence, pause/cancel work, and receive a summary on reconnect.
2. **Durable cloud queue:** persist task ID, schedule, state, attempts, dependencies, owner, policy version, and evidence references. Queue state must survive app closure and worker restarts.
3. **Cloud worker/scheduler:** claim due tasks with a lease, execute one bounded step at a time, heartbeat progress, retry transient failures with backoff, and stop on permission/configuration failures. Prevent duplicate posts with idempotency keys.
4. **Media worker:** produce script, captions, assets, voiceover where a configured free/authorized tool supports it, render MP4, and validate codec, duration, dimensions, audio and non-zero file size before marking ready.
5. **Publisher adapters:** use official platform APIs or an authorized scheduler integration. Store OAuth tokens in backend secret storage, never in Flutter source, APK, logs, or committed files. Refresh/revoke tokens safely and report expired permissions.
6. **Evidence and reporting:** persist post ID/permalink, platform response, publish time, media validation results, retry history, and any rejection. A queued task is not a published task.
7. **Safety and policy:** rate limits, per-platform content rules, duplicate detection, audit log, emergency pause, budget cap, and configurable approval rules.

## Social channels in scope
- Instagram account/brand: KWB86.
- TikTok handle: khaliedwalied403.
- YouTube channel: Khalied Walied.
- Buffer was previously discussed as a possible free scheduler. Its current availability and channel permissions must be checked at setup time; a free tier's queue limits mean it cannot be assumed to cover a two-month daily schedule.
- Prior connection visibility in analytics tools does not prove organic publishing permission. Re-check actual publish capabilities and authorization before enabling automatic posting.

## Workflows
### Daily content pipeline
1. Research a topic and capture source URLs and timestamps.
2. Draft platform-specific script, post, title, description, tags and captions.
3. Run safety, originality, factuality and platform-format checks.
4. Render the video and validate the MP4 artifact.
5. If policy permits, schedule/publish through an authorized adapter.
6. Verify the platform returned a real post/video ID or permalink.
7. Record the result and metrics; prepare a daily summary.

### Comments and replies
- Prefer helpful, context-relevant replies to comments on the owner's own content.
- Never mass-post generic comments, fabricate engagement, impersonate people, or bypass platform rate limits.
- Start in draft/review mode. Enable unattended replies only for narrowly defined, low-risk reply classes with a rate cap, blocked-topic list, duplicate detection, and a stop condition. Escalate complaints, sensitive topics, sponsorship/legal issues, and uncertain cases to the owner.

### Other delegated work
Use task-specific adapters and least-privilege permissions. Research, draft, analyze, run tests and build artifacts can often be autonomous. Sending messages, deleting data, spending money, deploying to production, or publishing outside the approved content policy requires explicit authorization or a previously configured narrow rule.

## Zero-budget constraints
- Do not add paid services or spend credits without explicit approval.
- GitHub Actions can run scheduled jobs but is not a guaranteed always-on worker; schedules may be delayed and quotas apply.
- Firebase scheduled/background processing may require a billing-enabled project depending on the chosen services. Confirm actual project configuration and quotas before implementing it.
- A genuinely unattended system needs a reachable worker/host and valid platform authorization. If no eligible free host or official publishing permission is available, prepare content and report the blocker rather than claiming it was published.
- A mobile-only implementation cannot keep working while the phone is off.

## Delivery sequence and acceptance criteria
1. Inspect current Firebase project/configuration and deployment permissions; do not expose secrets.
2. Define durable queue/task/evidence models and test state transitions.
3. Implement worker claiming, lease expiry, retries, cancellation, idempotency and restart recovery.
4. Connect one safe, read-only tool adapter and verify its real output.
5. Connect media rendering; require an actual validated MP4 artifact.
6. Connect one authorized social publishing path; test on a user-approved post and verify the real permalink.
7. Add remaining platforms individually after permissions are verified.
8. Add comment drafting/reply policies and limited automation.
9. Add phone-offline end-to-end tests, daily reports, alerts on failure, and a kill switch.

## Honest status
This document describes the target. It does not create a deployed cloud worker, authorize social accounts, produce a video, or publish/comment on any platform. Those actions require implementing and deploying the worker, configuring secure credentials, and verifying each integration.
