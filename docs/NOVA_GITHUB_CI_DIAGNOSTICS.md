# NOVA GitHub Actions diagnostics

NOVA's CI diagnostics are read-only for both GitHub Actions and CircleCI. They verify job/run identity, download only failed-step output, and retain a small set of redacted error lines. Full logs and credentials are never written to Firestore.

## Required secrets

### GitHub Actions

The private AUREN repository requires a GitHub token with the minimum repository access needed to read Actions jobs and logs:

- Repository access: `kdot101kwb-cyber/Auren`
- Repository permission: Actions — Read-only
- Metadata: Read-only (GitHub's required repository metadata access)

Configure it in the Firebase project used by NOVA Functions:

```bash
firebase functions:secrets:set NOVA_GITHUB_TOKEN
```

Paste the token only into the Firebase CLI secret prompt. Do not place it in source code, app configuration, Firestore, task prompts, or chat messages.

### CircleCI

CircleCI job output uses its API token and short-lived signed step-output URLs. Configure a CircleCI personal API token in Firebase Secret Manager:

```bash
firebase functions:secrets:set CIRCLECI_TOKEN
```

Paste the token only into the Firebase CLI secret prompt. Do not place it in source code, app configuration, Firestore, task prompts, or chat messages.

Then deploy the NOVA Functions that use these secrets through the project's normal reviewed deployment process. This change does not deploy functions or change Firebase project state.

## What NOVA stores

For GitHub Actions, NOVA stores at most five failed-job summaries, up to ten failed step names per job, and up to twelve short redacted evidence lines per job. For CircleCI, it inspects at most eight failed steps and retains up to twelve short redacted evidence lines per step. It does not store the full downloaded log.

The feature does not retry jobs, edit files, push commits, open pull requests, or merge code. Diagnosis is read-only; any later repair workflow must be separately reviewed and explicitly approved by the owner.

If either secret is not configured or the provider denies log access, the task reports diagnostics as unavailable and preserves the original CI result.
