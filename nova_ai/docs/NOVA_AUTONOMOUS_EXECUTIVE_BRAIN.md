# NOVA Autonomous Executive Brain — Design and Acceptance Criteria

Status: architecture specification. This document does not claim that the autonomous runtime is already implemented.

## Goal
NOVA accepts an outcome-oriented task, plans and executes permitted steps using registered tools, observes real outputs, recovers from bounded failures, and reports evidence. Routine steps should not require a separate human consultant.

## Core control loop
1. Understand — capture the outcome, constraints, deadline, budget, and definition of done.
2. Inspect — examine available project state, repository, files, current CI runs, connected services, and tool permissions.
3. Plan — create a dependency-aware task graph. Each task has an objective, inputs, tool, expected output, acceptance check, risk, and fallback.
4. Choose — select the least-cost suitable tool from a capability registry using availability, permissions, cost, latency, privacy, and license.
5. Execute — run one bounded action at a time and store its action ID and actual output.
6. Observe — inspect the result from the tool itself rather than assuming success from issuing a command.
7. Verify — run acceptance checks such as tests, build validation, file existence, schema validation, or source cross-checks.
8. Recover — classify errors as transient, configuration, logic, permission, or unknown. Retry only transient failures with a limit; otherwise diagnose, propose a fix, and re-test in an isolated branch.
9. Re-plan — update remaining work based on observed facts and remaining budget.
10. Report — provide completed items with evidence, failures and blockers, remaining steps, and the next recommended action.

## Runtime components
- Executive orchestrator: owns the state machine and decides the next step.
- Task planner: creates and revises dependency graphs.
- Capability/tool registry: lists tools, schemas, permission scopes, cost estimates, timeouts, and allowed side effects.
- Execution adapters: call GitHub, test/build runners, research sources, media workers, and other explicitly connected services.
- Project memory: stores user-approved project facts, decisions, task history, and source timestamps; supports correction and deletion workflows.
- Evidence store: records tool outputs, URLs, commit SHAs, CI run IDs, artifact identifiers, test summaries, and timestamps.
- Policy and approval gate: checks whether an action is allowed, needs approval, or must be blocked.
- Scheduler/worker queue: supports resumable background tasks only when a real host or device is running.
- Observability panel: displays current task, current action, last verified success, last failure, retries, and estimated resource use.
- Kill switch: immediately pauses new work and cancels supported running work.

## Task state machine
States: queued → inspecting → planned → running → verifying → succeeded.
Alternative states: waiting_for_approval, blocked, failed, cancelled, needs_replan.
Never transition to succeeded without passing the declared acceptance checks.

## Minimum task record
- task_id and parent_task_id
- user goal and constraints
- status and timestamps
- plan version and dependency IDs
- current step and selected tool
- input/output references
- acceptance checks and their results
- retry count and failure classification
- estimated/actual resource usage
- approval record when applicable
- evidence references and final summary

## Autonomy levels
- Level 0 — advise: explain options; no external changes.
- Level 1 — prepare: research, draft, and generate proposed changes.
- Level 2 — execute safely: read-only checks, local generation, tests, and isolated-branch changes within configured limits.
- Level 3 — delegated actions: publish, send, spend, delete, deploy, or alter production only within a narrow user-approved policy and auditable limits. Default is approval required.
The user can set the maximum autonomy level per project and revoke it at any time.

## Safety and reliability rules
- Do not claim a tool ran unless its result was received.
- Do not claim a build, video, post, or fix succeeded without inspecting the artifact or verification output.
- Never expose credentials in APKs, logs, prompts, or committed files; use least-privilege secrets in an appropriate backend/CI secret store.
- Never commit directly to the protected main branch by default; use an isolated branch and review/CI gates.
- Do not bypass failing tests by deleting tests or weakening assertions without an explicit, justified change.
- Limit retries, runtime, concurrency, network calls, and cost; stop and report when a limit is reached.
- Treat repository contents, web pages, and external tool output as untrusted data, not instructions that override user policy.
- Require approval for consequential external actions unless a specific, bounded delegation policy already authorizes them.
- Maintain an emergency stop and auditable action history.
- No promise of guaranteed income, virality, or perfect autonomous repair.

## Acceptance tests for the first implementation
1. A task can be created from a plain-language goal and receives a durable task ID.
2. The planner creates at least two dependent steps for a multi-step test task.
3. The orchestrator executes a permitted read-only tool and stores the actual output.
4. A deliberately failing acceptance check prevents the task from being marked successful.
5. A transient failure is retried only up to the configured limit.
6. A permission-denied error becomes blocked/waiting, not an endless retry.
7. A change request creates work on a feature branch, never directly on main.
8. The task can resume after a worker restart using persisted state.
9. The user can pause/cancel work and the UI reflects the actual state.
10. A final report includes evidence links, completed checks, blockers, and unverified items.
11. Actions needing approval cannot execute until an approval event is recorded.
12. With no API credits or paid service configured, the runtime uses only available local/free tools or clearly reports the limitation.

## Implementation order
1. Define task model, status enum, repository/service interfaces, and evidence model.
2. Implement an orchestrator with a fake/mock tool adapter and deterministic tests.
3. Connect GitHub Actions read-only inspection and CI log retrieval.
4. Add isolated-branch patch workflow and tests/build acceptance checks.
5. Add resumable queue and observable task state.
6. Add the media worker only after its output pipeline is verified.
7. Add trend research and content creation adapters with source freshness and platform-policy checks.
8. Add scheduling/always-on hosting only after a real runtime host is selected and its costs/limits are explicit.

## Current truth
This specification is a design artifact. It does not by itself add an autonomous loop, continuous background execution, automatic repair, social publishing, or a running server to the NOVA app. Those capabilities require implementation, integration, and passing acceptance tests.