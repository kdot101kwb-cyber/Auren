# NOVA Open-Source Agent Integration Audit

Status: source audit completed; no third-party project has been embedded or deployed.
Branch: `feat/nova-ai-android-app`
Budget assumption: USD 0; no trials, paid APIs, paid hosting, or credit consumption without explicit owner approval.

## Decision summary

| Project | Intended role | License observed | Zero-budget reality | Decision |
|---|---|---|---|---|
| Postiz | Social scheduling and publishing UI/API | AGPL-3.0 | Hosted service is paid after its trial. Self-hosting still needs a reachable server plus PostgreSQL, Redis, Temporal/workers, storage and approved social-platform developer apps. | Do not deploy or embed yet. Consider only if a genuinely available host and required platform approvals are confirmed; review AGPL obligations before combining code. |
| OpenClaw | Personal assistant / tool gateway | MIT | The code is permissively licensed, but a running machine and a model/provider are still required. A local model requires suitable compute; a cloud model may cost money. | Study architecture and security boundaries; do not replace NOVA's existing execution policy wholesale. |
| OpenHands | Coding agent | Not yet verified in this audit | A coding-agent runtime generally needs a sandbox/container and model access; these can consume resources or paid API quota. | Defer adoption until repository license, sandbox model, supported runtime, and no-cost execution path are verified. |

Sources checked:
- Postiz repository: https://github.com/gitroomhq/postiz-app
- Postiz official self-host configuration: https://github.com/gitroomhq/postiz-docs/blob/main/self-host/configuration/reference.mdx
- Postiz official pricing and hosted-service details: https://postiz.com/pricing
- OpenClaw repository and MIT license: https://github.com/openclaw/openclaw

## Existing NOVA safeguards verified

- `functions/nova_task_worker_policy.js` allows safe text/drafting task types, including `social_content_draft`.
- `social_publish` is not included in the safe autonomous task allowlist.
- `functions/nova_social_platform_policy.js` fails closed unless a platform is enabled, an adapter is configured, authorization and publish scopes are verified, and applicable cost/owner gates pass.
- These checks are policy code, not proof that any account is connected or that a publishing adapter is deployed.

## Recommended implementation order

1. Keep drafting and content planning available without social-platform credentials.
2. Build a backend-only Postiz connector behind an explicit feature flag, only after the owner supplies a reachable Postiz base URL and a secret stored server-side. Never put API credentials in Flutter, the APK, source control, or logs.
3. Start with read-only health/channel discovery where the documented API supports it; add draft creation next. Publishing stays disabled until OAuth scopes, account/channel identity, cost gates, duplicate protection, and real post-ID/permalink verification are tested.
4. Add contract tests with mocked HTTP responses for missing configuration, authentication failures, rate limits, timeouts, duplicate requests, malformed responses, and successful evidence capture.
5. Separately assess whether an always-on worker can run on already-available infrastructure. GitHub Actions is useful for bounded CI or scheduled tasks but must not be described as a guaranteed always-on service.
6. Revisit OpenClaw only as a separately sandboxed adapter/runtime experiment. Keep owner approval for code writes, deployments, spending, and publishing.

## Acceptance criteria before enabling social publishing

- No credentials in client code, committed files, or logs.
- Official API/authorized integration and exact scopes documented per platform.
- Owner explicitly enables each target account and approves any cost-bearing platform.
- Idempotency prevents duplicate posts after retries.
- Test suite covers denied and failure paths.
- A successful state requires a real platform post ID or permalink; queued/drafted is never reported as published.
- Pause/cancel and an auditable result record are available.
