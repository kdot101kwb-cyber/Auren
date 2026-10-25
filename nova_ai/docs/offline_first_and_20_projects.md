# NOVA AI — Offline-first engine and 20-project research

Research snapshot: 2026-10-25. This is a shortlist of public repositories to evaluate, not a claim that their code has been imported or their features are already integrated. Check each repository's current license, model license, Android support, maintenance and hardware requirements before adopting code.

## Product target

NOVA should be offline-first and connection-aware:
- **Offline mode:** local quantized LLM, local chat history, local document search/RAG, cached project notes and local utility tools. It must continue working in airplane mode after the model and required data have been downloaded.
- **Online research mode:** fetch current pages, public repository metadata, issues, commits and CI status; show citations, timestamps and failures. Never claim web freshness when offline.
- **GitHub mode:** use official GitHub App/OAuth with minimal repository permissions on a trusted backend. Start read-only. Writes, PR creation, merging, release publishing, deletion and workflow dispatch require scoped authorization, audit trail and explicit approval where consequential.
- **Fast answers:** stream tokens; use a small model for simple tasks, local lexical/vector retrieval before generation, cached summaries, short context windows and cancellable requests. Larger models improve some answers but use more RAM and may be slower.
- **Honest limits:** internet research cannot work without internet. Local model quality/speed depends on phone RAM, chipset, thermal state and model quantization. Download models once and keep them available offline.

## Recommended implementation shape

1. Flutter app: chat, local/online/auto mode indicator, source cards, model manager, document import, local task queue and clear offline fallback.
2. Local inference adapter: start with one Android-supported runtime (evaluate `flutter_mind_local`/llama.cpp or LiteRT-LM); keep an interface so another engine can be added later. Do not embed a multi-gigabyte model into the APK; download a user-selected licensed model once and verify its checksum.
3. Local knowledge: SQLite FTS for dependable lexical search first; optional on-device embeddings/vector index when performance and package maintenance are verified. Store source/title/URL/date and show citations for retrieved passages.
4. Online retrieval service: server-side fetch/search with domain allowlists, timeouts, caching, content-size limits and prompt-injection defenses. Treat retrieved pages as untrusted data, never as executable instructions.
5. GitHub connector: backend holds OAuth/GitHub App credentials in secret storage; app holds only short-lived user sessions. Expose typed operations such as list repos/issues, read files, inspect workflow runs and artifacts. Separate read and write scopes.
6. Coding worker: execute tests/builds in isolated disposable CI jobs, not in the mobile app or API process. Return logs, exit codes and artifacts. Require approval before merge or deployment.
7. Security and privacy: local chat remains local by default; clearly label anything sent to a server; redact secrets from logs; add cancellation, request budgets, retries and user-controlled deletion.
8. Verification gates: offline airplane-mode test; model-load and first-token timing on target devices; source/citation tests; GitHub least-privilege tests; Flutter analyze/test; Android debug APK artifact.

## 20 GitHub projects to study

| # | Project | What to learn from it | Fit / caution |
|---:|---|---|---|
| 1 | [Loki LLM / loxi_llm](https://github.com/LucknowAI/loxi_llm) | Flutter + llama.cpp, offline chat, RAG and bounded tools | Very close product reference; review current API and license before reuse |
| 2 | [Airgap](https://github.com/skmdroid/airgap) | Offline Flutter assistant, cited local RAG, verification | Useful offline-first and citation reference |
| 3 | [PocketClaw](https://github.com/ManojRakshu/pocketclaw) | Android voice, vision, documents and device actions | New/fast-moving; verify target-device requirements |
| 4 | [Offline AI Assistant](https://github.com/its-hazratbilal/offline-ai-assistant) | Android GGUF model manager and llama.cpp integration | Kotlin implementation; useful native reference |
| 5 | [flutter_mind_local](https://github.com/MohamedOsama26/flutter_mind_local) | Flutter local GGUF inference adapter | Evaluate package stability, native build and supported devices |
| 6 | [llama.cpp](https://github.com/ggml-org/llama.cpp) | Quantized local inference and GGUF runtime | Strong runtime candidate; native integration is engineering work |
| 7 | [Ollama](https://github.com/ollama/ollama) | Local model runtime and API patterns | Better for desktop/server than directly inside Android |
| 8 | [MLC LLM](https://github.com/mlc-ai/mlc-llm) | Compiled model deployment and device acceleration | Check model/device compatibility and build complexity |
| 9 | [LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM) | On-device LLM inference for supported mobile hardware | Evaluate Android API maturity and Flutter bridge requirements |
| 10 | [ONNX Runtime GenAI](https://github.com/microsoft/onnxruntime-genai) | Token generation loop and model execution APIs | Native Android integration and model compatibility must be tested |
| 11 | [Aider](https://github.com/Aider-AI/aider) | Git-aware coding, diffs and iterative test/fix loop | Server/desktop worker reference, not an Android runtime |
| 12 | [OpenHands](https://github.com/OpenHands/OpenHands) | Agent sessions and sandboxed software engineering | Run in isolated backend workers; resource intensive |
| 13 | [Continue](https://github.com/continuedev/continue) | Model/provider adapters and codebase context | Study connector patterns; its editor UX is not the mobile app |
| 14 | [Cline](https://github.com/cline/cline) | Tool-use flow, plans, approvals and checkpoints | Use safety patterns; inspect license and dependency fit |
| 15 | [OpenCode](https://github.com/anomalyco/opencode) | Coding agent engine, providers and session APIs | Backend/desktop reference; not a direct Flutter dependency |
| 16 | [SWE-agent](https://github.com/SWE-agent/SWE-agent) | Repository issue solving and reproducible task runs | Research/worker reference; isolate repository execution |
| 17 | [Goose](https://github.com/block/goose) | Extensible tools and MCP integration | Useful connector patterns; desktop-first |
| 18 | [LangGraph](https://github.com/langchain-ai/langgraph) | Durable state, checkpoints, retries and human approval | Orchestration framework, not an on-device model |
| 19 | [Model Context Protocol servers](https://github.com/modelcontextprotocol/servers) | Standardized tools/connectors | Treat every server as privileged; allowlist tools and permissions |
| 20 | [AnythingLLM](https://github.com/Mintplex-Labs/anything-llm) | RAG workspaces, documents and provider abstraction | Self-hosted service reference; review license and resource needs |

## Other useful references

- [Open WebUI](https://github.com/open-webui/open-webui) — local/self-hosted model interface.
- [Dify](https://github.com/langgenius/dify) — workflows, RAG and provider orchestration.
- [Qdrant](https://github.com/qdrant/qdrant) — vector database, likely server-side rather than on-device.
- [Chroma](https://github.com/chroma-core/chroma) — vector search and RAG reference.
- [sqlite-vec](https://github.com/asg017/sqlite-vec) — SQLite vector search; verify Android packaging and performance.
- [browser-use](https://github.com/browser-use/browser-use) — browser automation; restrict domains and require approval for consequential actions.
- [awesome-llm-apps](https://github.com/Shubhamsaboo/awesome-llm-apps) — additional architecture examples.

## Delivery order

**P0 — Reliable app:** fix and pass analysis/tests/build, publish a real APK artifact.
**P1 — Offline assistant:** add local model lifecycle, streaming response, chat persistence and offline document search; measure on target Android hardware.
**P2 — Online research:** add source-backed retrieval and cache, with explicit online/offline indicator.
**P3 — GitHub read-only:** connect OAuth/GitHub App securely; display repos, issues, source files, CI runs, logs and artifacts.
**P4 — Approved coding actions:** issue triage, patch proposals, CI runs and PR creation in a sandbox; add explicit approval before merge/deploy.
**P5 — Further tools:** MCP connectors and additional providers only after permissions, logs, tests and recovery are in place.

Do not copy all 20 projects into NOVA. Select a small number of components behind stable interfaces; copying entire products would bloat the app, duplicate dependencies and create license/security/maintenance risks.
