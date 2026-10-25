# NOVA: free AI coding setup

This guide prioritizes free-to-start tools and keeps provider claims honest. Free quotas and model availability can change by account, country, and date; check each provider's current plan before relying on it.

## Recommended free-first stack

1. **GitHub Copilot Free** — inline completions and limited chat/agent usage in supported editors. Good fit for the AUREN GitHub repository.
2. **Google Antigravity** — agent-oriented coding workspace; use only within the currently offered free quota.
3. **Cline** or **OpenCode** — open-source coding agents. The agent software is free, but hosted model calls may cost money. A local model avoids API charges but needs capable hardware.
4. **OpenRouter free models** — optional backend model route for text tasks. Free model availability, rate limits, and quality are not guaranteed. Keep the API key in Firebase Secret Manager; never ship it in the Android app.
5. **NOVA Free Builder Runner** — this repository's GitHub Actions workflow runs allowlisted checks/builds and uploads artifacts. GitHub Actions usage may be subject to account quota.

## Run the repository's free builder checks

1. Open the repository's **Actions** tab.
2. Choose **NOVA Free Builder Runner** and click **Run workflow**.
3. Select one profile:
   - `flutter`: format check, analyzer, tests, debug APK build.
   - `web`: requires `package.json`; runs available lint/test/build scripts and expects `dist/`, `build/`, or `out/`.
   - `static_web`: validates and packages an `index.html` site.
4. Download the artifact from the completed workflow run. Review the workflow conclusion and logs; an artifact alone does not mean tests passed.

The workflow only checks/builds code already present in the selected repository revision. It does **not** generate code, poll the Firestore build queue, deploy a site, publish an app, or merge a PR. It does not execute user-supplied shell commands.

## Error-reduction policy

- Require formatting, static analysis, tests, and build before treating a change as verified.
- Keep retries bounded; capture the first failing log and final result.
- Never claim “zero bugs”; report exact checks and exit statuses.
- Keep API keys in server-side secret storage. Never put provider credentials in Flutter assets, source, or APK.
- Require explicit approval before deployment, publication, production-secret changes, or merging.

## Links

- GitHub Copilot: https://github.com/features/copilot
- Google Antigravity: https://antigravity.google/
- Cline: https://cline.bot/
- OpenCode: https://opencode.ai/
- OpenRouter: https://openrouter.ai/
