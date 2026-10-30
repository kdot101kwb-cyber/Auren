# NOVA Self-Repair Engine — Safety Contract

This first implementation is a policy and validation foundation. It does not yet write to GitHub, create commits, run tests, or deploy Firebase functions.

## Flow

1. Consume a **verified** failed GitHub Actions or CircleCI result.
2. Build a proposal from at most 12 bounded evidence lines and at most 5 text files.
3. Restrict paths to NOVA source/tests under `nova_ai/lib`, `nova_ai/test`, or `functions/nova_*.js`.
4. Require each file's current 40-character blob SHA to prevent blind overwrites.
5. Require explicit approval by the owning user.
6. Permit application only to an isolated `nova/repairs/<slug>` branch.
7. Mark a repair verified only when every required check succeeds on the exact commit SHA.

## Hard boundaries

- No main/default branch writes, PR merge, release, or Firebase deployment.
- No edits to secrets, credentials, Firebase/Storage rules, lockfiles, or deployment configuration.
- Maximum 5 files and 64 KiB total patch content.
- No raw CI logs or credentials are stored in proposals.
- Failed or incomplete checks never count as success.
- This module is not connected to a worker or UI yet; GitHub write credentials and test execution remain deliberately unimplemented pending a separately reviewed integration.

## Next integration stage

Connect proposal creation to the existing read-only CI diagnostics, add an owner approval action, and implement a narrowly scoped GitHub branch writer using expected blob SHAs. Then run repository CI on the exact pushed commit and surface the results in NOVA Task Center. Keep PR creation and merge as separate approval gates.
