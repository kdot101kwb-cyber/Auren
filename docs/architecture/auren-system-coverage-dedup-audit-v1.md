# AUREN System Coverage & Deduplication Audit — v1

## Purpose

Keep the AUREN master blueprint coherent as the product expands. This is a **coverage and deduplication workstream**, not a proposal to create another broad system with a potentially overlapping name.

## Rules for adding or expanding a system

1. Search the existing Flutter feature folders, documentation, open pull requests, and master blueprint before creating a new system.
2. Prefer extending the existing canonical system over creating a second system for the same user outcome.
3. Treat a system name as a product label, not proof that the capability is absent or complete.
4. Keep domain models and business rules independent of UI and external providers where practical.
5. Separate advisory recommendations from consequential actions; require explicit user confirmation for sensitive actions.
6. Keep source attribution, freshness, and editorial verification as distinct concepts for information features.
7. Work on a dedicated branch and pull request. Do not merge automatically.
8. Mark a capability **implemented** only when code and tests demonstrate it; **in progress** when an active PR or partial implementation exists; **planned** when it is only in the blueprint; and **needs audit** when available evidence is insufficient.

## Candidate overlap review

These are previously discussed candidates, not automatically new systems:

| Candidate label | Potential canonical home / overlap to inspect | Initial decision |
| --- | --- | --- |
| AUREN World Intelligence | AUREN AI, Universal Search, Opportunity Radar, information/news, and existing reality/opportunity graph concepts | Do not create a separate broad system until a capability-level gap is demonstrated. |
| AUREN Places / Places Intelligence | Maps, local discovery, business directory, nearby services, and location-aware search | Treat as a connected capability area first; audit existing modules before proposing a standalone system. |
| AUREN Journey OS | Travel planning, maps, mobility, bookings, and local discovery | Treat as a cross-system workflow unless a unique missing domain is identified. |
| AUREN Airport Intelligence | Travel, flight/airport information, and journey planning | Prefer an airport capability within Travel/Journey rather than a duplicate top-level system. |

This overlap review is based on prior AUREN planning discussions and is **not** a claim that every related capability has been verified in the current codebase.

## Initial repository evidence

- The repository already contains a Flutter feature structure under `lib/features/`.
- A culture/news presentation screen exists at `lib/features/culture/presentation/culture_news_screen.dart`; this alone does not prove a complete news domain exists.
- AUREN News & Information is being developed separately in PR #220, with feed ordering proposed in dependent PR #223. Keep these changes separate and verify their CI before calling the work complete.
- This first audit does not certify overall product coverage. It establishes a repeatable rule for checking before adding systems.

## Required next audit pass

For each proposed system, record:

- User outcome and primary jobs-to-be-done
- Existing folders, screens, domain models, tests, docs, and open PRs that already support it
- Capability gaps demonstrated by evidence
- Canonical owning system and integration points
- Explicit exclusions to prevent scope creep
- Acceptance tests and security/privacy considerations
- Status: implemented / in progress / planned / needs audit

## Acceptance criteria for this audit

- No new duplicate product system is created solely from a name in the roadmap.
- Candidate overlaps and their provisional decisions are documented.
- Unverified implementation status is explicitly labelled.
- Changes remain isolated in this documentation-only pull request until reviewed.


## Active workstream review — 2026-10-21

This is a point-in-time review of open pull requests and their reported combined status checks. Open-PR state and checks can change; re-query before merging or declaring completion. Status labels below describe the PR/workstream, not the entire capability in AUREN.

### Priority and overlap findings

| Workstream | Evidence observed | Decision / next action |
| --- | --- | --- |
| PR #259 — PR workstream overlap guard | Dedicated read-only overlap checker; all five combined CI statuses were successful on head `5aa2739d0e1abb5f0e8b61a190d3e2dda460a393`. | Keep as a high-value repository safety tool; human review still required because file overlap is not semantic overlap. |
| PR #255 and PR #254 — automation inventory | Both describe static workflow/schedule/deployment safety inventories and report generation. PR #255 head `eb65b841445c587602b221ba3ae9c78eeb6c093f` had all five combined statuses successful when checked. | Treat as a likely duplicate workstream until changed-file and implementation comparison proves a distinct contract. Do not build a third inventory. |
| PR #258 and PR #256 — Pulse quick replies / reading position | Both describe SNAP REPLY / quick replies and local scroll-position restore; PR #258 head `2489b1df2dcd27be2e9abd2a74af8382ca2f3ca6` had all five combined statuses successful when checked. | Compare changed paths and dependency/base commits before either is merged; likely duplicate/stacked variants of the same user outcome. |
| PR #251 and PR #248 — Knowledge & Information | Both cover Knowledge Hub / Research Desk / Language Bridge and adjacent research workflows; PR #251 head `4febcf139b17495eb5711d813bffb4c35a16a40c` had all five combined statuses successful when checked. | Review dependency and file overlap; define one canonical ownership map rather than treating the PR titles as separate full systems. |
| PR #253 — Information Intelligence tools | Five focused tools are present in service/UI/tests and linked from Culture & News. On head `9c413654f8d7926114c4de9d88c6727a620acb7c`, combined status reported failures for `functions_tests` and `flutter_ci`; other three statuses succeeded. | **Needs validation/fix before considered green.** Inspect failing job logs or CircleCI output before changing code; do not infer the cause from status alone. This is an implementation already in progress, not a reason to create another information system. |
| PR #220 and PR #223 — News & Information | News domain model and feed ordering are separate related PRs; #223 is described as depending on #220. | Preserve dependency order and recheck both heads and CI before merging. |
| PR #221 and PR #222 — AUREN Music | Rap Arena and collaboration brief planning extend the existing Music/Entertainment path. | Keep them as Music capabilities; do not create another parallel music ecosystem. |
| PR #250 — Creation & Production | Reuses Creator Studio, Media Studio, and the existing Music recording/audio-analysis path. All five combined statuses were successful on head `30ee3426817c15a08ef98ee95c4e92015eeade94` when checked. | Maintain the reuse boundary; latest navigation/text-share changes still need review against the exact head and workflow run before declaring release-ready. |
| PR #257 — Personal Finance | Distinct user-entered budget/income/expense foundation; all five combined statuses were successful on head `b036a5e5a5d1ba0948695de559d764117237f924` when checked. | Candidate for focused product review after duplicate/overlap checks; do not treat CI alone as production readiness. |
| PR #224 — this audit | Documentation-only coverage/dedup rules; all five combined statuses were successful on head `46fd0d2f939f793c26517ecbfc6fd378fa84a5dc` when checked. | Continue this audit by recording concrete overlap decisions and explicit unknowns. No application behavior changes. |

### Immediate engineering queue

1. **Resolve duplicate/stacked workstreams first:** compare PR #254 vs #255 and #256 vs #258 changed files, base/head ancestry, and whether one is intended to supersede the other. Do not merge or close any PR automatically.
2. **Triage PR #253:** obtain the failing Flutter and Functions job logs, reproduce the actual failing commands if possible, then make a narrow fix on its own branch and rerun CI. A status failure alone is not enough evidence to edit source.
3. **Keep Knowledge & Information ownership explicit:** compare #248 and #251 paths and dependencies; keep #253 as utility tooling only where its capabilities are not already implemented by the canonical Knowledge Hub / Research Desk / Library flows.
4. **Audit the canonical Master Blueprint:** a repository search has not yet identified a definitive numbered master blueprint file. Until it is found, do not treat an individual addendum, feature registry, PR description, or historic dashboard count as the complete canonical source.
5. **After the overlaps are resolved, choose the next feature batch based on a demonstrated user-facing gap, not on the number of named systems.**

### Evidence limits

- Combined status checks show CI state for the specified commit, not manual UX review, runtime behavior with configured Firebase/App Check, or production readiness.
- The repository connector did not provide CircleCI job logs in this pass, so the root cause of PR #253's two failed statuses remains unknown.
- No PR was merged or closed and no production deployment was performed as part of this review.


### Changed-path overlap check completed — 2026-10-21

The following exact changed-file lists were compared after the initial review:

- **PR #254 vs PR #255:** both change `.github/workflows/automation-inventory.yml`, `scripts/auren_automation_inventory.js`, and `scripts/auren_automation_inventory.test.js`. PR #255 additionally changes `.github/workflows/backend-ci.yml`, `.github/workflows/codeql.yml`, `.github/workflows/publish-images.yml`, and `docs/AUREN_AUTOMATION_INVENTORY.md`. This is confirmed path overlap, not merely similar titles. Inspect diffs and commit ancestry before choosing a canonical PR; do not merge both blindly.
- **PR #256 vs PR #258:** both change `lib/features/social/presentation/timeline_screen.dart`. PR #256 also changes Nebula tokens, create/edit post screens, media-type helper, repository, and media-type tests; PR #258 is limited to the timeline screen in its reported changed-file list. This confirms a shared integration hotspot but does not prove one PR wholly supersedes the other. Review the timeline diffs and base/head ancestry before merge.
- **PR #251 vs PR #248:** no path comparison has yet been completed in this pass. Their descriptions indicate related user journeys, but do not label them duplicates until exact changed paths and dependencies are compared.

The audit document was updated to record these findings; no application source files, PR states, or deployment targets were changed.
