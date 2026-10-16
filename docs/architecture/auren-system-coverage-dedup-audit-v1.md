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
