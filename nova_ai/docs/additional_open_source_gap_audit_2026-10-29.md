# NOVA AI — Gap audit of 20 additional open-source projects

Review date: 2026-10-29. This supplements `docs/offline_first_and_20_projects.md`; it deliberately screens projects **not already named in that shortlist or its “other useful references”**. A repository being listed is not an assertion that NOVA has integrated, tested, or adopted it.

## Selection rules

1. Solve a documented NOVA gap: durable work, agent coordination, memory, evidence-backed research, safe browser use, or measurable quality.
2. Prefer permissive open-source licenses and code that can be self-hosted; verify the current repository and model licenses before use.
3. Fit the existing Android-first Flutter app and its JavaScript/TypeScript Firebase Functions boundary. Python-only systems are backend/isolated-worker references, not Flutter dependencies.
4. Keep $0-start constraints: no mandatory paid hosted control plane, API, GPU, or browser service. Free software does not make model inference or hosting free.
5. Reuse capabilities already present; do not add a second orchestrator, memory store, scheduler, or gateway without a measured reason.

## Twenty additional candidates screened

| # | Project | Best NOVA use | Fit decision |
|---:|---|---|---|
| 1 | [Deep Agents](https://github.com/langchain-ai/deepagents) | Long-running plans, subagents, file/task workflows | **Study** for durable multi-step task design; don't replace existing planner until benchmarked |
| 2 | [Open SWE](https://github.com/langchain-ai/open-swe) | Asynchronous coding tasks and isolated execution | **Study** for a future backend coding worker; requires secure runner and model access |
| 3 | [Pydantic AI](https://github.com/pydantic/pydantic-ai) | Typed tool inputs/outputs, validation, model-provider flexibility | **Shortlist** for backend tool contracts; Python runtime means it is not a direct fit for current JS functions |
| 4 | [CrewAI](https://github.com/crewAIInc/crewAI) | Role-based agent teams | **Benchmark only** against NOVA's current department registry; avoid a duplicate team orchestrator |
| 5 | [OpenAI Agents SDK](https://github.com/openai/openai-agents-python) | Tool calling, handoffs, guardrails and tracing | **Shortlist for patterns**, but the Python SDK is not a direct fit for the current JS backend; verify the official TypeScript SDK separately if needed |
| 6 | [Google ADK](https://github.com/google/adk-python) | Agent development and delegation | **Defer**; overlaps with existing agent planning and adds another runtime |
| 7 | [Microsoft Agent Framework](https://github.com/microsoft/agent-framework) | Stateful workflows, approvals and agent orchestration | **Defer** unless a real .NET/Python service is justified; do not add a second orchestrator by default |
| 8 | [Agno](https://github.com/agno-agi/agno) | Agent runtime, sessions, tools and storage | **Benchmark only** against the existing NOVA engine; Python/backend footprint |
| 9 | [smolagents](https://github.com/huggingface/smolagents) | Lightweight tool/code agents | **Study** for small isolated research workers; code execution must be sandboxed |
| 10 | [Mastra](https://github.com/mastra-ai/mastra) | TypeScript workflows, agent tools and suspend/resume patterns | **Shortlist** because TypeScript fits the backend better; verify license boundaries and hosting needs |
| 11 | [Mem0](https://github.com/mem0ai/mem0) | Long-term memory extraction and retrieval | **Shortlist for a measured adapter experiment**; keep NOVA's current local/task memory authoritative until privacy, storage and deletion tests pass |
| 12 | [Langfuse](https://github.com/langfuse/langfuse) | Trace model/tool calls, costs, latency and failures | **Shortlist** for optional self-hosted observability; protect user content and secrets in traces |
| 13 | [Promptfoo](https://github.com/promptfoo/promptfoo) | Repeatable prompt, model and agent regression/security evaluations | **Shortlist** for CI tests; can be added as a development tool without shipping it in the Android app |
| 14 | [Ragas](https://github.com/explodinggradients/ragas) | Evaluate retrieval-augmented answers and source quality | **Use only when NOVA's RAG exists**; otherwise premature |
| 15 | [n8n](https://github.com/n8n-io/n8n) | External workflow integrations and scheduled automations | **Defer**; self-hosting and license terms need review, and NOVA already has task/worker concepts |
| 16 | [Firecrawl](https://github.com/firecrawl/firecrawl) | Convert web pages into research-ready content | **Shortlist for research architecture**; self-host resource use and hosted API costs must be checked |
| 17 | [Crawl4AI](https://github.com/unclecode/crawl4ai) | Open-source crawling and extraction for research | **Shortlist for a server-side research worker**; never run unrestricted crawling from the phone |
| 18 | [Playwright](https://github.com/microsoft/playwright) | Deterministic browser automation and browser-based tests | **Shortlist for isolated worker tests**, not as an on-device Flutter dependency |
| 19 | [E2B](https://github.com/e2b-dev/infra) | Sandboxed execution environments | **Study security model only**; do not depend on a paid hosted service under the $0 constraint |
| 20 | [AgentOps](https://github.com/AgentOps-AI/agentops) | Agent traces and evaluation signals | **Compare with Langfuse**, do not install both without evidence of a gap |

## Best additions for NOVA — prioritized, not bulk-imported

### P0 — Add to development quality gates
- **Promptfoo**: maintain a small regression suite for planning, refusal of unsafe instructions, tool selection, evidence requirements, and Arabic/English behavior. It must run without exposing production secrets.
- **Playwright**: use only for browser/UI integration tests in a disposable CI worker where browser testing is actually needed.
- **No new runtime dependency is required for these test ideas**; first prove that the repository's existing tests and Android build are green.

### P1 — Evaluate one TypeScript-native workflow layer
- **Mastra** is the first candidate to benchmark because NOVA's backend currently uses JavaScript/TypeScript.
- Compare it against the existing planner, department registry, task worker, retries, and approval policy using the same tasks.
- Adopt only if it demonstrably improves durable resume, observability, or approval handling without duplicating existing code or exceeding free-tier limits.
- Do **not** simultaneously add CrewAI, Google ADK, Agno, Microsoft Agent Framework and another orchestrator.

### P1 — Improve evidence and operational visibility
- **Langfuse**: optional, self-hosted tracing after a privacy review; redact prompts, credentials, personal data and repository secrets.
- **Mem0**: optional adapter experiment only after defining local-first storage, consent, retention, deletion, and conflict-resolution behavior. It must not silently replace NOVA's current task/project records.

### P2 — Research and coding workers
- **Crawl4AI or Firecrawl**: select one only after comparing source freshness, extraction accuracy, rate limits, resource consumption and license. Research results remain untrusted input and require citations.
- **Open SWE or Deep Agents**: evaluate one isolated coding-worker pattern after GitHub read-only access, disposable builds, logs/artifacts, and human approval are working.
- **E2B is not a default dependency** because a hosted sandbox may violate the $0 constraint. A local/container runner still needs strict isolation and must never run untrusted repository code on the production API process.

## Explicitly excluded from direct integration

- Any framework whose main runtime is Python/.NET when NOVA's current execution boundary is JavaScript/TypeScript, unless a separate worker is justified by a benchmark.
- Multiple agent orchestrators that solve the same task-routing problem.
- Paid APIs or hosted services treated as mandatory.
- Browser, shell, GitHub write, social posting, payment, merge, or deployment actions without explicit scoped authorization and an audit trail.
- Copying full applications into the Flutter bundle. Integrate a narrow adapter or adopt a design pattern, not an entire competing product.

## Verification gates before marking an integration complete

1. Repository baseline: `flutter analyze`, `flutter test`, and `flutter build apk --debug` on the intended branch.
2. Contract tests: deterministic inputs, malformed tool output, timeout, cancellation, retry ceiling, and no-evidence failure.
3. Security tests: tool allowlist, prompt-injection fixture, secret redaction, least privilege, and approval gates.
4. Cost tests: no paid service required for the selected baseline; measure optional hosted paths separately.
5. Offline tests: cached project/memory access in airplane mode; clearly disable live search and remote execution while offline.
6. Evidence: CI run URL, exit codes, artifact link, and exact commit. A plan or passing unit test alone does not prove an external integration is deployed.

## Decision summary

The best near-term value is **quality evaluation (Promptfoo), TypeScript workflow benchmarking (Mastra), and optional tracing (Langfuse)**. Memory (Mem0), web extraction (Crawl4AI/Firecrawl), and coding agents (Deep Agents/Open SWE) are later, conditional experiments. This avoids importing 20 projects, duplicating NOVA's existing engine, or creating hidden recurring costs.
