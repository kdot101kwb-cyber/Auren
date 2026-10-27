# NOVA Grok Bot: unified agent strategy

## Decision

Keep **one user-facing NOVA Grok Bot** and treat model providers, research tools, and coding workers as separate adapters behind it. Do not ship terminal agents inside the Flutter APK.

### Candidate assessment (checked 2026-10-27)

| Project | Best use | NOVA decision | Important constraint |
|---|---|---|---|
| [xAI TypeScript SDK](https://github.com/xai-org/xai-sdk-ts) | Official server-side Grok API integration | Use as the Grok API integration reference | Requires a server-side xAI API key; usage may cost money |
| [OpenHands](https://github.com/OpenHands/OpenHands) | Model-agnostic coding-agent orchestration and self-hosted Agent Server/Canvas | Highest-priority external coding-worker candidate | Requires a separate runtime/host and sandbox; not Android-native and not connected yet |
| [grok-cli](https://github.com/superagent-ai/grok-cli) | Grok-native coding, subagents, terminal workflows | Candidate for a sandboxed coding worker | Community project, requires Grok API access, terminal runtime, and license review at a pinned revision |
| [OpenAI Codex CLI](https://github.com/openai/codex) | Alternative coding worker | Optional comparison candidate | Provider access, execution environment, and pricing depend on setup |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Alternative coding worker | Optional comparison candidate | Provider access, execution environment, and pricing depend on setup |
| [Goose](https://github.com/block/goose) | General-purpose tool-using agent | Optional comparison candidate | Must be isolated and granted only task-specific capabilities |

OpenHands is the strongest candidate for the **agent orchestration layer** in this shortlist because its Agent Server/Canvas can manage multiple backends and model providers. It is not inherently a better language model than Grok. For Grok-specific reasoning/search, use the Grok API; for controlled repository work, evaluate OpenHands and grok-cli in a separate sandbox.

## Current implementation boundary

- `functions/nova_grok_bot.js` remains the only live Grok model adapter.
- `functions/nova_grok_agent_registry.js` lists candidate engines and fails closed for all candidates that are not actually connected.
- No agent candidate is installed, launched, or granted repository access by this catalog.
- Grok Bot may draft plans and code suggestions, but does not edit GitHub, publish content, send messages, spend money, or run shell commands.
- A future worker needs a separate authenticated service, isolated workspaces, resource/network limits, explicit user approval for writes and external side effects, audit events, and CI/test evidence.
- Never put provider keys in Flutter, `--dart-define`, the repository, or logs. Configure `XAI_API_KEY` only in Firebase Secret Manager for the callable.
- A free/open-source repository does not make model inference, hosting, or remote execution free.

## Verification

Run from `functions/`:

```sh
node --check nova_grok_agent_registry.js
node --test nova_grok_agent_registry.test.js
node --check nova_grok_bot.js
node --test nova_grok_bot_core.test.js
```

These checks verify the local registry policy and Grok Bot normalization tests; they do not prove that xAI credentials are configured, that an external agent is deployed, or that an end-to-end model request succeeds.
