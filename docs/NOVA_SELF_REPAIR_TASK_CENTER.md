# NOVA Self-Repair — Task Center integration

## Flow

1. A failed GitHub Actions or CircleCI task is eligible only when it belongs to the signed-in owner, has a verified 40-character source commit, and contains bounded failure evidence.
2. NOVA submits a repair proposal with a summary and 1–5 complete replacement text files. The policy engine enforces the NOVA path allowlist, expected blob SHAs, 64 KiB total limit, and credential checks.
3. The proposal is stored under `users/{uid}/nova_repair_proposals/{proposalId}` with state `awaiting_approval`.
4. The owner explicitly invokes `approveAndApplyNovaRepair`. Only then does the backend verify every source blob SHA, create a Git tree and one commit, and push a new `nova/repairs/{proposalId}` branch.
5. `checkNovaRepairValidation` checks the exact pushed commit against all five required CircleCI contexts. A repair is not verified while any check is missing, pending, or failed.

## Callable API

- `createNovaRepairProposal({taskId, summary, files})`
- `approveAndApplyNovaRepair({proposalId})` — explicit owner approval and isolated branch push; does not open or merge a PR.
- `checkNovaRepairValidation({proposalId})`

The Task Center client must show the complete proposed file paths, reasons, summary, source commit, and patch before invoking approval. Do not silently approve or apply proposals.

## Required secret

Create a separate GitHub token with access only to `kdot101kwb-cyber/Auren`, repository Contents read/write, and commit status read. Store it in Firebase Secret Manager as `NOVA_GITHUB_REPAIR_TOKEN` using the local Firebase CLI prompt. Never paste it into chat, app code, Firestore, or task prompts.

This change does not set secrets, deploy functions, open PRs, merge code, or touch the default branch. GitHub Actions/CircleCI must validate the pushed repair commit before NOVA can mark it verified.
