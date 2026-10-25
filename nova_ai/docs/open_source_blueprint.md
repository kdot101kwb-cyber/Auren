# NOVA AI — Open-source project research and implementation plan

Research date: 2026-10-25. The projects below are references for architecture and capabilities, not integrations already completed. Review the exact license of every selected version before copying code or redistributing it.

## Best candidates

| Purpose | Repository | Useful ideas for NOVA | Recommendation |
|---|---|---|---|
| Stateful multi-agent orchestration | https://github.com/langchain-ai/langgraph | Explicit task states, checkpoints, retries, pause/resume and approval gates | Preferred backend orchestration candidate |
| Visual AI workflows and RAG | https://github.com/langgenius/dify | Workflow builder, provider abstraction, knowledge retrieval and observability | Evaluate as optional self-hosted admin service; review license conditions |
| Software development agent | https://github.com/All-Hands-AI/OpenHands | Sandboxed edits, test feedback loops and visible task sessions | Separate isolated worker, not embedded in Android |
| Browser automation | https://github.com/browser-use/browser-use | Browser tasks with explicit allowlists and user confirmation | Optional backend worker |
| Working examples | https://github.com/Shubhamsaboo/awesome-llm-apps | Patterns for RAG, agents and provider integrations | Reference library, not a runtime dependency |
| Ecosystem discovery | https://github.com/awesome-llms-labs/awesome-ai-agents | Find memory, evaluation, security and observability components | Research index; verify maintenance and licenses individually |

Do not deploy every platform at once. A single secure backend with clear interfaces is cheaper and easier to maintain than several overlapping agent platforms.

## Target architecture

1. **Flutter Android app:** Arabic-first interface, sign-in, task queue, live status, approvals and activity history. Never bundle provider secrets or GitHub tokens in the APK.
2. **NOVA API:** authenticated requests, per-user authorization, validation, rate limits and short-lived sessions.
3. **Orchestrator:** durable task states, checkpoints, bounded retries, timeouts, cancellation and human-approval states.
4. **Specialist workers:** AUREN development, QA and security; content planning; email drafting; and browser tasks. Give each worker only task-scoped permissions.
5. **Connectors:** GitHub App with least-privilege permissions first; add email and social providers later through official OAuth/API flows.
6. **Isolated execution:** disposable CI jobs or sandboxed containers for builds and tests; never execute untrusted repository code inside the API process.
7. **Persistence and audit:** task database, append-only activity events, redacted logs, cost/usage metrics and retention controls.
8. **Approval policy:** require user confirmation before merging code, publishing content, sending messages, deleting data or changing security settings.

## Delivery phases

### Phase 0 — Reliable APK
- Keep `flutter analyze`, widget tests and Android debug build as required CI gates.
- Upload the APK only after every gate passes.
- Report a build as successful only when the workflow and artifact confirm it.

### Phase 1 — Real AUREN status
- Add a backend endpoint that reads repository and CI status.
- Start with read-only GitHub permissions.
- Show actual run IDs, statuses, failure summaries and artifact links in NOVA.
- Add write operations only after read-only integration and audit logging are tested.

### Phase 2 — Safe agents
- Start with one supervisor and two workers: repository triage and QA.
- Use structured inputs/outputs, checkpoints, timeouts, idempotency and bounded retries.
- Require approval for code writes and PR merges.

### Phase 3 — Business workflows
- Start with draft-only social posts and email replies.
- Add sending/publishing only through official APIs with preview, approval and audit records.
- Track model usage and hosting cost; open-source software does not make model inference or hosting automatically free.

## Security and licensing checklist

- Inspect the exact license and third-party notices before commercial use or redistribution.
- Pin dependency versions, scan vulnerabilities and generate an SBOM.
- Store secrets server-side, not in source control or Flutter assets.
- Apply minimum permissions, short-lived credentials and per-action authorization.
- Treat repository issues, code, web pages and browser content as untrusted input.
- Test prompt injection, unauthorized writes, duplicate task execution and recovery after failed jobs.

## Current status

The `nova_ai` application is still a front-end prototype. This document records the recommended building blocks and implementation order; it does not claim that these projects, GitHub write access, email, or social accounts are connected.
