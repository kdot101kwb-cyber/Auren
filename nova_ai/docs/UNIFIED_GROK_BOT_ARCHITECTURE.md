# NOVA Unified Grok Bot — Architecture and Project Selection

## Goal

Provide one assistant surface in NOVA with distinct task modes while keeping provider credentials on the server, costs explicit, and real-world side effects behind human approval.

## Why these projects were selected

| Project | Useful capability | How NOVA uses it | Why its full code is not embedded in the Android app |
|---|---|---|---|
| [xAI TypeScript SDK](https://github.com/xai-org/xai-sdk-ts) | Official typed access to the xAI API, tools, streaming, and media endpoints | The current callable uses the official xAI Responses API over server-side fetch, avoiding a new runtime dependency. The SDK can replace the transport after version and cost review. | API use can cost money; secrets must remain server-side. |
| [Grok Build](https://github.com/xai-org/grok-build) | Coding-agent harness with repository tools, skills, hooks, MCP, and subagents | Future coding-worker design reference. | It is a Rust terminal application, not a Flutter library. Repository writes and shell commands belong in an isolated worker, not a callable that handles chat. |
| [LangGraph](https://github.com/langchain-ai/langgraph) | Stateful orchestration, persistence, durable execution, and human-in-the-loop workflows | Architectural reference for future task graphs and resumable jobs. | A framework is not needed for the initial small callable. Add a graph runtime only when there is a tested multi-step worker and a clear operational need. |
| [PydanticAI](https://github.com/pydantic/pydantic-ai) | Typed agent outputs and model-provider abstraction | Design reference for schema validation and provider separation. | It is Python-based; the current NOVA backend is Node.js and Flutter. Avoid running a second service solely to parse chat responses. |
| [OpenHands](https://github.com/All-Hands-AI/OpenHands) | Full software-development agent with a larger execution environment | Candidate for a later isolated coding-worker evaluation. | Too much infrastructure and security surface for the initial $0-first mobile build. |

## Current implementation

- One Flutter screen: chat, research, coding guidance, planning, and content planning.
- One authenticated Firebase callable: **novaGrokBot**.
- xAI Responses API called from the server; **XAI_API_KEY** is never included in Flutter.
- User input is bounded; the callable requires authentication and App Check and rate-limits requests.
- Requests use store=false; the audit record stores mode, model, approval flag, status, and timestamp—not the user's prompt or context.
- Output is normalized to a small JSON contract. A model-generated proposal cannot override the server's approval rule.
- No tool execution is connected yet. This is intentional: the current bot proposes work but does not run shell commands, edit GitHub, publish content, contact people, make purchases, or trade.

## Safe next phases

1. Configure XAI_API_KEY in Firebase Secret Manager only after deciding whether API charges are acceptable. Without it, the callable stays unavailable.
2. Validate the callable against the actual xAI account/model, including JSON output, rate limits, timeouts, and cost limits.
3. Add a provider-neutral task-plan schema and store proposals in NOVA's existing task/approval workflow.
4. Build a separate restricted coding worker for GitHub checkout, diffs, tests, and CI evidence. Require approval before writing/pushing and never auto-merge.
5. Consider LangGraph or another orchestrator only when the worker needs resumable multi-step state; benchmark before adding dependencies.
6. Add local/offline model routing separately. Grok API itself is not an offline model.

## Deployment

From the functions directory, configure the secret with Firebase Secret Manager:

~~~bash
firebase functions:secrets:set XAI_API_KEY
~~~

Then deploy the novaGrokBot callable using the repository's approved deployment workflow. Do not paste the secret into source code, chat, Flutter build arguments, or committed environment files.

## Validation

Run from the functions directory:

~~~bash
node --check nova_grok_bot_core.js
node --test nova_grok_bot_core.test.js
node --check nova_grok_bot.js
~~~

A green core unit test does not prove the deployed xAI API key, account model access, App Check configuration, or full Flutter build is working. Confirm CI and a controlled integration test before claiming production readiness.
