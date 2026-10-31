# NOVA Project Portfolio & Decision Control

## Purpose

The portfolio is the owner-controlled registry for projects across NOVA, AUREN, income, content, research, operations, and personal work. It complements the strategic debate service and task center; it does not replace either one.

## Owner-only callable APIs

All endpoints call `requireNovaOwner` before reading or writing private data and require App Check:

- `createNovaProject`: creates a project in `idea` state only.
- `listNovaProjects`: lists up to 50 projects, ordered by computed priority score.
- `updateNovaProjectPriority`: updates strategic value, urgency, confidence, effort, and priority classification.
- `updateNovaProjectStatus`: records a lifecycle decision and its reason.
- `listNovaProjectWorkItems`: lists up to 100 work items for one project.
- `addNovaProjectWorkItem`: adds a backlog item; it never starts execution.
- `updateNovaProjectWorkItem`: records a work-item status change and reason/evidence.

## Data model

Projects are stored at `users/{uid}/novaProjects/{projectId}`. Work items are stored beneath each project at `workItems/{workItemId}`. Audit events are written to `users/{uid}/nova_audit`.

The project score is a deterministic 0–100 ranking:
- Strategic value: 35%
- Urgency: 25%
- Confidence: 20%
- Lower effort: 20%

The score is an ordering aid, not an autonomous decision. The owner can change the inputs at any time.

## Lifecycle policy

Project states: `idea`, `active`, `paused`, `deferred`, `cancelled`, `completed`.

- New projects always start as `idea`.
- Moving to `paused`, `deferred`, `cancelled`, or `completed` requires a written decision note.
- `cancelled` and `completed` are terminal in this first version.
- A deferred project can return to `idea` or `active` only through an explicit owner action.

Work-item states: `backlog`, `planned`, `in_progress`, `blocked`, `deferred`, `cancelled`, `completed`.

Blocking, deferring, cancelling, or completing a work item requires a reason or evidence note. Closed projects cannot accept new work items.

## Safety boundaries

- Every project and work-item API is owner-authenticated.
- Every decision is audit logged with actor UID and before/after state where applicable.
- No callable launches a worker, sends outreach, publishes content, changes GitHub, deploys Firebase, or spends money.
- Creating a project, adding a work item, or approving a debate is not evidence that execution has started.
- Any future execution adapter must have a separate permission and approval gate.

## Android entry point

The screen is available in NOVA under the top-right **كل أقسام NOVA** menu as **محفظة المشاريع ومجلس القرارات**. It requires the verified owner claim and App Check to load private project data.
