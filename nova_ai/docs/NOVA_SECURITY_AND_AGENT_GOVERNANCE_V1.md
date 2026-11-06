# NOVA Security & Agent Governance — v1

## Purpose
This document defines the security baseline and operating model for NOVA's specialist teams. It is an implementation plan with a small verified enforcement increment; it does not claim that every control or agent is already operational.

## Current verified foundation
- NOVA callable task endpoints inspected in this branch require Firebase Authentication and Firebase App Check.
- Task records are stored under the authenticated user's namespace; the worker uses an explicit task-type allowlist.
- Debate requests have a per-user rate limit.
- Provider credentials are declared as Firebase Secret Manager parameters in the worker; secrets must never be shipped in the Android client.
- Repository workflows include CodeQL, dependency review, and SPDX SBOM generation. Their trigger scopes differ, so a passing NOVA Android build is not a security scan.
- The current shared task contract records audit events with a strict detail allowlist.

## Newly added exact-action approval control
For owner-approved video-generation tasks:
1. The server calculates a SHA-256 approval scope over schema version, task ID, owner UID, task type, prompt, metadata, and approval requirement.
2. The approval record stores the scope hash, approver UID, and a 30-minute expiry.
3. The worker verifies the owner, required approval, scope hash, and unexpired timestamp before claiming execution.
4. Any change to the prompt, metadata, owner, task identity, or task type invalidates the approval.
5. Legacy approvals without a scope hash and expiry fail closed and must be approved again.

This is not a general authorization system for every NOVA capability. It currently protects the existing video-generation execution path; other external side effects remain blocked unless a dedicated adapter and exact-action approval are implemented.

## Security architecture

### 1. Identity and access
- Require authenticated identity and App Check on callable endpoints.
- Apply least privilege per service and per agent; deny unknown capabilities by default.
- Keep user-owned task and audit records isolated by UID.
- Never put provider keys, GitHub tokens, signing keys, or private credentials in Flutter assets, source, logs, prompts, or task results.
- Use separate development/staging/production identities and revoke unused credentials.

### 2. Approval and execution gates
- Classify every action as read-only, local reversible, external side effect, financial, destructive, or production-sensitive.
- Require approval for publishing, sending messages, purchases, paid APIs, permission expansion, production secrets, deployments, destructive operations, and data migrations.
- Bind approval to the exact action, target, input/commit, provider, estimated cost, and expiry.
- Re-check authorization immediately before execution, not only when a task is submitted.
- Support cancellation and revocation; a stale or changed approval must fail closed.

### 3. Application and supply-chain security
- Run secret scanning, dependency vulnerability review, CodeQL, and SBOM generation on the relevant NOVA paths and pull requests.
- Pin third-party GitHub Actions to reviewed immutable versions/SHA where practical.
- Review dependency licenses and transitive packages before adoption.
- Validate input size, type, URI scheme, path, and output size at every trust boundary.
- Keep CI artifacts short-lived and avoid uploading secrets or private user data.

### 4. Data protection and privacy
- Minimize collected data; separate public research signals from private user/project data.
- Encrypt data in transit and rely on managed encryption at rest; protect key material through server-side secret management.
- Redact credentials, tokens, personal data, and prompt contents from logs unless strictly required.
- Give the owner export, retention, deletion, and recovery controls with explicit confirmation for destructive actions.
- Do not send private repository contents to external AI providers unless the owner has enabled that specific data flow and the security checks pass.

### 5. Isolated build and tool execution
- Run future App Builder/repair work in disposable isolated workspaces.
- Enforce repository and path allowlists, read-only inspection first, network egress restrictions, resource/time limits, and no ambient secrets.
- Generate a plan and diff before writing; run format/analyze/tests/build; preserve logs and artifact hashes.
- Produce draft PRs only. No automatic merge, release, deploy, or production mutation.

### 6. Detection, response, and recovery
- Record append-only audit events for task submission, approval, denial, claim, execution, retries, cancellation, and completion.
- Alert on repeated failures, unusual volume, privilege changes, unexpected provider usage, and suspicious access.
- Provide an emergency stop that prevents new claims and disables external adapters.
- Back up task metadata and project configuration; test restoration, not merely backup creation.
- Preserve incident evidence and require owner review before reopening a quarantined adapter.

## Agent organization target

The following are planned departments. A role card or prompt is not proof of an operational agent; each department becomes operational only after it has a registered capability, least-privilege identity, task adapter, tests, audit events, and an end-to-end evidence run.

1. Executive Manager / NOVA CEO — priorities, delegation, status, and owner reports.
2. Engineering — Flutter, backend, AI integration, data, and app architecture.
3. Security & Privacy — threat modeling, code/dependency review, access policy, incident response.
4. Global Market Intelligence — permitted source monitoring, regional demand, provenance, and opportunity ranking.
5. Revenue & Finance — halal income research, payout eligibility, unit economics, budgets, and risk; no autonomous spending.
6. Marketing & Content — research, scripts, creative briefs, campaign analytics; publishing requires approval.
7. Game Studio — game discovery, design, prototyping, testing, and store-policy review.
8. Quality Engineering — tests, regression analysis, device/build validation, and release acceptance.
9. DevOps & Reliability — CI health, artifacts, observability, rollback preparation, and approved infrastructure changes.
10. Debate & Strategy Council — independent viewpoints, adversarial review, trade-offs, and evidence-based recommendations.
11. Operations & Customer Care — inbox triage and draft responses; sending external messages requires approval.
12. Research & Memory — source verification, project knowledge, decision history, and checkpoint continuity.

## Council rules
- The Executive Manager coordinates; it cannot override security policy or owner approval.
- The Security reviewer may block an unsafe action and must explain the evidence.
- The independent challenger searches for failure modes and conflicts of interest.
- Finance reviews cost and payout assumptions; Quality reviews acceptance evidence.
- Consensus is a recommendation, not authorization. Owner approval remains the final gate for sensitive actions.
- Agents may not grant themselves permissions, create hidden credentials, or approve their own high-risk actions.

## Implementation sequence
- P0: exact-action approval scope and expiry for the existing approved video task path — implemented in this branch; tests added.
- P1: shared action-risk registry and approval/revocation service for all side-effect adapters.
- P2: security dashboard with scan status, open findings, access inventory, audit history, and emergency stop.
- P3: isolated App Builder runner with path/network/resource restrictions and artifact provenance.
- P4: agent capability registry and task adapters for the twelve departments, introduced incrementally.
- P5: end-to-end drills for approval expiry, task tampering, secret leakage, worker crash, cancellation, and restore.

## Explicit non-goals and safety limits
- No production Firebase deployment, secret rotation, GitHub permission expansion, repository merge, external publishing, purchase, or paid service is authorized by this work.
- No agent is represented as autonomous or connected unless a real adapter and end-to-end evidence prove it.
- Zero-cost defaults remain in force. A free-tier quota or provider outage must not trigger a paid fallback.
