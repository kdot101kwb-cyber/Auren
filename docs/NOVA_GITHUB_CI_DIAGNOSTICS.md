# NOVA GitHub Actions diagnostics

NOVA's CI diagnostics are read-only. They verify that a failed job belongs to the submitted AUREN workflow run, download that job's log, and retain only a small set of redacted error lines. Full logs and credentials are never written to Firestore.

## Required secret

The private AUREN repository requires a GitHub token with the minimum repository access needed to read Actions jobs and logs:

- Repository access: `kdot101kwb-cyber/Auren`
- Repository permission: Actions — Read-only
- Metadata: Read-only (GitHub's required repository metadata access)

Configure it in the Firebase project used by NOVA Functions:

```bash
firebase functions:secrets:set NOVA_GITHUB_TOKEN
```

Paste the token only into the Firebase CLI secret prompt. Do not place it in source code, app configuration, Firestore, task prompts, or chat messages.

Then deploy the NOVA Functions that use this secret through the project's normal reviewed deployment process. This change does not deploy functions or change Firebase project state.

## What NOVA stores

For each failed job, NOVA stores at most five job summaries, up to ten failed step names per job, and up to twelve short redacted evidence lines per job. It does not store the full downloaded log.

The feature does not retry jobs, edit files, push commits, open pull requests, or merge code. Diagnosis is read-only; any later repair workflow must be separately reviewed and explicitly approved by the owner.

If the secret is not configured or GitHub denies log access, the task reports diagnostics as unavailable and preserves the original CI result.
