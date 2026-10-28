# NOVA Comedy Studio v1 — implementation specification

## Product identity
- Working name: NOVA Comedy Studio (brand name for the public page remains to be chosen).
- Independent comedy brand inside the NOVA network; never present it as an AUREN page.
- Audience: Arabic + English, global.
- Formats: original memes/images, jokes/text, short videos, multi-image posts.
- Inspiration is limited to the broad genre of viral sarcasm pages. Do not copy another page's name, logo, posts, media, or distinctive creative work.

## Current implementation in this branch
- A Flutter screen is wired into the existing NOVA dashboard menu.
- Arabic and English captions, format, language, notes, and status can be saved as local drafts.
- Drafts are stored in SharedPreferences under `nova.comedy_studio.queue.v1`.
- The UI explicitly states that no Facebook Page was created, no account was connected, and nothing was published.
- The publishing toggle is a request/status affordance only; it cannot enable publishing until a verified integration exists.
- No API tokens or account credentials are stored by this screen.

## Content lifecycle
`idea → trend evidence → original draft → language / rights / safety review → owner policy gate → scheduled → published / failed → performance review`

The current screen implements local draft capture and simple draft status changes only. The rest of the lifecycle is planned, not claimed as implemented.

## Publishing architecture (next phase)
1. Define a `PublishingPlatformAdapter` interface and a no-op/dry-run implementation first.
2. Connect Facebook Pages only through official Meta APIs and the minimum supported permissions granted by the owner. Never request a Facebook password or bypass review/rate limits.
3. Keep OAuth secrets and long-lived credentials server-side in a secrets manager; do not store them in SharedPreferences or source control.
4. Verify the actual Page identity, Page role, granted scopes, token validity, API review status, and media format constraints before allowing a publish job.
5. Require owner approval for the first real test post. Automatic publishing may start only after the connection and test are verified, with an emergency stop, daily caps, idempotency keys, bounded retries, and audit events.
6. When permission or platform support is absent, keep content in draft and show a concrete blocker. Never imply a post was published unless the platform returns a verifiable post ID/URL.

## Quality and safety gates
- Original content and documented media rights.
- No impersonation of Asa7be or other pages.
- Language quality checks for Arabic and English.
- Policy checks for targeted harassment, private information, and dangerous or illegal content.
- Sensitive topics and ambiguous rights cases are held for owner review.
- Analytics-based iteration; no guarantees of virality or income.

## Tests and release gate
- Local bilingual draft persistence.
- Empty draft validation.
- Offline/local storage failure behavior.
- Publishing remains unavailable without verified integration.
- Owner pause/stop behavior once a backend queue exists.
- Duplicate job prevention, retry bounds, and audit trail once adapters exist.
- Run Flutter format, analyze, tests, and Android debug build on the actual branch. Do not claim CI success until the current commit's checks are green.

## Dependency
This feature branch is based on `feat/nova-auren-workspace-v1`, where the private NOVA app and workspace exist. That workspace PR is not on `main` at the time of implementation. Keep this work as an unmerged draft PR until the dependency is reviewed; do not merge automatically.
