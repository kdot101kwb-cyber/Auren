# NOVA Builder: background AUREN development

## Purpose
NOVA is a separate personal Android control plane that coordinates the ongoing completion of AUREN. It must use the actual repository, tests, CI logs, feature ideas, and sourced market research—not local checkbox state or invented progress.

## Continuous loop
1. Read repository state, open pull requests, issues, recent CI runs, and project backlog.
2. Run a daily/manual health check: Flutter analyze, tests, and Android debug build; retain logs and artifact links.
3. Rank failing tests, security issues, broken user journeys, and validated market opportunities.
4. Create an isolated feature branch and implement one bounded change with regression tests.
5. Run checks and record commit, logs, test results, and build artifact.
6. Open a pull request for human review. Never auto-merge, deploy, publish, or spend money.
7. Store market findings with source URL, observation time, geography/language, confidence, expected user value, build effort, and free-tier constraints.

## Background execution
The Android app itself cannot guarantee continuous work while closed. Scheduled GitHub Actions or a backend scheduler must own recurring jobs. The app displays their real run states and reports. Device-only offline mode can manage cached tasks and project files, but cannot perform fresh global market research or remote repository changes without connectivity.

## Security and cost
- $0-first: use existing GitHub Actions free quota and local/offline capabilities where possible; never assume unlimited free execution.
- Store credentials in GitHub secrets or a secure backend, never in Flutter source or APK.
- Use least-privilege access, redacted logs, bounded retries, idempotency, and an audit record.
- Require approval for merge, release, production changes, external publishing, account permission changes, and financial commitments.

## Verification gates
A feature is complete only when code exists in the repository, tests pass, CI results are visible, and the expected artifact or behavior has been verified. A UI or written plan alone is not completion.