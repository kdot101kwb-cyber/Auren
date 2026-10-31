# NOVA Self-Repair — Task Center integration

## Flow

1. A failed GitHub Actions or CircleCI task is eligible only when it belongs to the signed-in owner, has a verified 40-character source commit, and contains bounded failure evidence.
2. Before any AI request, NOVA verifies that the exact source commit has a successful `ci/circleci: gitleaks_scan` status. Missing, pending, failed, or mismatched scan status blocks transfer. NOVA then sends bounded evidence and selected allowlisted source files to OpenRouter's free-model route; files containing credential-like material are rejected before transmission.
3. NOVA generates a repair proposal with a summary and 1–5 complete replacement text files. The policy engine enforces the NOVA path allowlist, expected blob SHAs, 64 KiB total patch limit, and credential checks.
4. The proposal is stored under `users/{uid}/nova_repair_proposals/{proposalId}` with state `awaiting_approval` and displayed in Task Center with the complete patch.
5. The owner explicitly invokes `approveAndApplyNovaRepair`. Only then does the backend verify every source blob SHA, create one Git commit, and push a new `nova/repairs/{proposalId}` branch.
6. `checkNovaRepairValidation` checks the exact pushed commit against all six required CircleCI contexts, including `gitleaks_scan`. Missing or pending checks remain pending; a repair is verified only after all six succeed.

## Callable API

- `generateNovaRepairProposal({taskId, aiDataTransferConsent: true})` — requires an explicit owner consent flag on the server before sending source code and bounded CI evidence to the configured free-model route.
- `listNovaRepairProposals()` — lists the signed-in owner's proposals and patch previews.
- `createNovaRepairProposal({taskId, summary, files})` — lower-level proposal API for a trusted client.
- `approveAndApplyNovaRepair({proposalId})` — explicit owner approval and isolated branch push; does not open or merge a PR.
- `checkNovaRepairValidation({proposalId})`

The Task Center client must show the complete proposed file paths, reasons, summary, source commit, and patch before invoking approval. Do not silently approve or apply proposals.

## Required secret

Create a separate fine-grained GitHub token with access only to `kdot101kwb-cyber/Auren`, repository Contents read/write, and Commit statuses read. Configure the existing OpenRouter key as `OPENROUTER_API_KEY`; model generation uses the `openrouter/free` route. Store it in Firebase Secret Manager as `NOVA_GITHUB_REPAIR_TOKEN` using the local Firebase CLI prompt. Never paste it into chat, app code, Firestore, or task prompts.

A stale `applying` operation is quarantined as `recovery_required` whether or not its branch is visible at the recovery check. A missing branch is not proof that the original worker stopped; NOVA never resets that operation for automatic re-approval or a second push. Manual reconciliation is required.


If a GitHub write is still in flight when recovery is requested, its eventual completion must preserve `recovery_required` and record the observed branch/commit for manual reconciliation. Any ambiguous apply error is also quarantined; do not automatically retry or re-approve it.

The CircleCI `gitleaks_scan` job installs the pinned Gitleaks v8.30.1 release and scans every allowlisted repair source path (`nova_ai/lib`, `nova_ai/test`, and production `functions/nova_*.js`; Functions test files are not repair targets). The same exact-commit scan is required again before an owner-approved GitHub write. The Firestore Emulator integration gate exercises the production completion/recovery transaction helpers under deterministic and concurrent ordering.

This change does not set secrets, deploy functions, open PRs, merge code, or touch the default branch. GitHub Actions/CircleCI must validate the pushed repair commit before NOVA can mark it verified.
