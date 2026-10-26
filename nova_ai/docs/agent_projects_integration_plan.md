# NOVA agent projects: integration register

This register covers all ten requested open-source projects. **A catalog entry is not the same as integrating or executing the upstream code.** The Flutter screen exposes the entries and official repository links; upstream code has not been vendored into the APK.

| Project | Intended role | Integration path | Status |
|---|---|---|---|
| [Open Jarvis](https://github.com/tokenarc/open-jarvis) | Android assistant, voice, accessibility skills | Audit upstream license/dependencies and assess isolated Android adapter | Catalogued; not integrated |
| [Local-AI](https://github.com/smartworldarafath/Local-AI) | Local assistant, RAG, local workspace | Audit native Android architecture; reuse only compatible components | Catalogued; not integrated |
| [llama.cpp](https://github.com/ggml-org/llama.cpp) | On-device LLM inference | Add a native Android/FFI bridge, model download/import, quantization and RAM checks | Catalogued; runtime not integrated |
| [LangGraph](https://github.com/langchain-ai/langgraph) | Stateful workflow orchestration and human approval | Use only if a separately secured Python backend is acceptable; not a Flutter library | Catalogued; not integrated |
| [smolagents](https://github.com/huggingface/smolagents) | Tool-using agents | Backend-only candidate; code execution requires real sandboxing | Catalogued; not integrated |
| [OpenHands](https://github.com/OpenHands/OpenHands) | Software-development agent | Isolated build worker with restricted repo permissions and CI validation | Catalogued; not integrated |
| [Browser Use](https://github.com/browser-use/browser-use) | Online web research and browser tasks | Optional network-connected worker; respect site terms and rate limits | Catalogued; not integrated |
| [CrewAI](https://github.com/crewAIInc/crewAI) | Multi-role agent coordination | Alternative to LangGraph; select one orchestrator after a prototype | Catalogued; not integrated |
| [Android Agent](https://github.com/ghost-in-the-droid/android-agent) | Android automation/testing over ADB/MCP | Developer/test harness, not silent production device control | Catalogued; not integrated |
| [Pocket Agents Lab](https://github.com/cbarkinozer/pocket-agents-lab) | Experimental mobile agent patterns | Research only until maintained status, license, security and device fit are verified | Catalogued; not integrated |

## Constraints and staged delivery

1. **Zero-dollar default:** prefer locally runnable components and free tiers; no paid API or hosted runtime is assumed.
2. **Offline:** llama.cpp is the main candidate for local inference. The agent orchestration and browser research candidates above do not automatically run offline.
3. **Device budget:** target a configurable model/storage budget of 2–5 GB, but model weights, RAM use, thermal behavior and latency must be measured on the actual Android device. Do not download a multi-gigabyte model automatically.
4. **Human control:** require explicit approval before publishing, sending messages, changing a repository, running shell commands, making purchases, or granting permissions.
5. **Secrets:** no GitHub tokens or provider keys in Flutter assets, source, or APK. Use narrowly scoped tokens on a protected worker or official OAuth flow.
6. **Execution isolation:** never execute untrusted generated code in the app process. Use disposable isolated workers, strict network/filesystem limits, timeouts, audit logs, and post-change tests.
7. **License review:** verify the current LICENSE and dependency licenses at each upstream repository before copying, packaging, or distributing code. Repository links alone are not license approval.

## Verification checklist before calling a project integrated

- [ ] Pin upstream repository and commit; inspect license and maintenance status.
- [ ] Write a small adapter with an explicit input/output contract.
- [ ] Add unit tests and failure/timeout tests.
- [ ] Run Flutter analyze/tests and Android debug build.
- [ ] Measure APK growth, installed storage, peak RAM, latency, battery and offline behavior on device.
- [ ] Confirm no secrets, unexpected network access, or unapproved actions.
- [ ] Report integration status and limitations in the NOVA UI and CI output.

The current NOVA offline foundation stores tasks and income plans locally; it does not yet provide a local language-model runtime or a general-purpose secure agent executor.
