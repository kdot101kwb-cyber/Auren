# NOVA — 60 integration candidates (zero-budget-first)
Branch: `feat/nova-ai-android-app`
Purpose: shortlist for implementation planning. This is **not a claim that all 60 are connected today**.

## Selection rules
- Prefer documented APIs, OAuth, webhooks, MCP, or self-hostable open-source software.
- Free tier/availability can change; check current limits, regional access, commercial-use terms, and required billing before enabling.
- Never put provider secrets in the Android app. Store them in a trusted backend/secret manager.
- Status labels: **API/OAuth** = integration path exists, still needs implementation and authorization; **self-host** = user must run/deploy the service; **limited** = API access or free quota may be restricted.
- Initial priority: implement GitHub + CI first, then workflow automation, then content and research sources.

## A. Development, repositories and CI (10)
1. **GitHub** — API + GitHub App/OAuth/webhooks; issues, PRs, commits, Actions status. **P0**
2. **GitLab** — REST API + OAuth/webhooks; repositories and pipelines. API/OAuth
3. **Bitbucket** — REST API + OAuth/webhooks; repositories and pipelines. API/OAuth
4. **Codeberg / Forgejo** — Forgejo API; repositories/issues where enabled. API; verify instance
5. **GitHub Actions** — workflow dispatch + run/status/artifacts via GitHub API. **P0**
6. **CircleCI** — API/webhooks for pipeline status. API/OAuth
7. **Buildkite** — API/webhooks for build status. API/key
8. **Sentry** — API/webhooks for error and issue monitoring. API/OAuth
9. **SonarQube** — Web API; self-hosted Community Edition option. API/self-host
10. **OpenHands** — coding-agent workflows and GitHub integration; deployment/model requirements apply. API/self-host; review gates required

## B. Workflow automation and app connectors (10)
11. **n8n** — broad app integrations, webhooks, API; self-host option. **P0**
12. **Activepieces** — open-source workflow automation; API/webhooks and self-host option. **P1**
13. **Node-RED** — flow-based automation, HTTP/MQTT nodes; self-host. Self-host
14. **Pipedream** — API workflows and OAuth connectors; free tier/limits apply. API/limited
15. **Make** — scenario automation and webhooks; plan limits apply. API/limited
16. **Zapier** — app automation and webhooks; plan limits apply. API/limited
17. **Windmill** — scripts, jobs and workflows; self-host option. API/self-host
18. **Kestra** — event-driven workflows and schedules; self-host option. API/self-host
19. **Trigger.dev** — background jobs and event workflows; plan limits apply. API/limited
20. **Huginn** — open-source agents for monitoring feeds and web events; self-host. Self-host

## C. Backend, data and workspace (10)
21. **Firebase** — Auth, Firestore, Cloud Functions, App Check; existing AUREN stack. **P0**
22. **Supabase** — Postgres, Auth, Storage, Edge Functions; free-tier limits apply. API/OAuth
23. **Appwrite** — Auth, database, storage and functions; cloud or self-host. API/self-host
24. **PocketBase** — lightweight backend with REST API; self-host. API/self-host
25. **NocoDB** — database-to-app/API layer; self-host option. API/self-host
26. **Baserow** — database API; cloud/self-host options. API/self-host
27. **Airtable** — REST API and OAuth/personal access token; quotas apply. API/limited
28. **Google Sheets** — Sheets API + Google OAuth; quotas and consent setup apply. API/OAuth
29. **Notion** — public API + OAuth integration; user must authorize workspace. API/OAuth
30. **Trello** — REST API + OAuth/keys; user authorization required. API/OAuth

## D. AI models, search and agent runtimes (10)
31. **Google Gemini API** — API key/server-side calls; free quotas and model availability vary. API/limited
32. **OpenRouter** — unified model API; free models/quotas may change. API/limited
33. **Groq** — inference API; rate limits apply. API/limited
34. **Hugging Face** — Hub/API and hosted inference; quotas/model terms vary. API/limited
35. **Ollama** — local model API; needs a reachable machine/server with sufficient resources. Self-host
36. **OpenAI API** — API; do not assume free credits. Paid usage may be required. API/billing
37. **Anthropic API** — API; paid usage may be required. API/billing
38. **Mistral AI API** — API; tier and quotas vary. API/limited
39. **Cloudflare Workers AI** — API through Cloudflare account; limits/plan apply. API/limited
40. **Dify** — LLM app/workflow platform with API; cloud or self-host; model provider costs may apply. API/self-host

## E. Media, images, video and creative assets (10)
41. **Canva** — official developer/platform integrations exist for supported use cases; approval and scopes vary. API/OAuth; verify endpoint eligibility
42. **Pexels** — photo/video API; key and rate limits apply. API/limited
43. **Pixabay** — image/video API; key and rate limits apply. API/limited
44. **Unsplash** — image API; key, rate limits and usage guidelines apply. API/limited
45. **Wikimedia Commons** — media discovery via public APIs; respect attribution/licensing. API
46. **Pollinations** — image-generation endpoint availability and limits can change; validate before production. API/limited
47. **ComfyUI** — local/server workflow API; requires hosted GPU/compute for many models. Self-host
48. **Replicate** — model API; generally usage-based after any trial credits. API/billing
49. **fal.ai** — media-model APIs; usage-based/limited credits may apply. API/billing
50. **Stability AI** — image API; check current pricing and model terms before enabling. API/billing

## F. Publishing, messaging, market and public data (10)
51. **YouTube Data API** — OAuth/API; quota and channel permissions apply. API/OAuth
52. **Instagram Graph API** — Meta app/account eligibility and permissions required; supported publishing flows only. API/OAuth
53. **TikTok for Developers** — OAuth and approved scopes; posting permissions are not automatic. API/OAuth/approval
54. **X API** — API access tiers and pricing can apply; do not assume free posting. API/limited
55. **Buffer** — supported API/partner options vary; confirm access for the required publishing actions. API/eligibility
56. **Telegram Bot API** — bot token and user-initiated setup; good for NOVA notifications. API
57. **Discord** — bot/webhook API; permissions required. API
58. **Alpha Vantage** — market-data API; free quota and delayed/real-time coverage vary. API/limited
59. **CoinGecko API** — crypto market data; rate limits and plan terms apply. API/limited
60. **World Bank API** — public economic indicators; useful for country-level research. API

## Recommended implementation order
1. **P0 now:** GitHub + GitHub Actions + Firebase (already in the project stack).
2. **P1:** n8n or Activepieces, Telegram notifications, Sentry, Google Sheets, Notion.
3. **Content:** YouTube first; then Instagram/TikTok only after permissions and account eligibility are confirmed.
4. **Research:** World Bank + Alpha Vantage/CoinGecko with timestamps, source links and clear “not financial advice” labels.
5. **Creative generation:** begin with a configurable provider adapter; never label a web link as a live integration. Add each provider only after a successful API smoke test.

## What “direct connection” means
The app needs a real adapter, authorization flow, secure backend secret storage, error handling, quotas, and tests. Opening a website is **not** a connection. OAuth approval, API keys, paid quotas, regional restrictions, and provider terms may still be required. Do not promise that all 60 are free or available in Sudan. No production integration is considered complete until its authorization and a real test call succeed.
