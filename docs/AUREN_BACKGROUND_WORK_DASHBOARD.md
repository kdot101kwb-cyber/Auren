# AUREN Background Work Dashboard

This page is the human-readable control point for ongoing AUREN engineering. It is intentionally separate from the NOVA Android app.

## Current work lanes

| Lane | Scope | Evidence required to mark complete |
|---|---|---|
| Flutter quality | Analyze, test, format diagnostics | Green CI run plus test report |
| Android delivery | Debug APK build and artifact upload | Successful workflow run and downloadable artifact |
| Feature delivery | Fix one coherent feature area at a time | Focused tests, full CI where practical, reviewed pull request |
| Reliability | Track flaky/failing tests and regressions | Reproducible issue, fix commit, passing regression test |
| Security | Review Firebase rules, secrets handling, and AI gateway boundaries | Tests/review; never expose secrets in logs or APK |
| Product planning | Prioritize user-facing systems and dependencies | Issue/PR with acceptance criteria |

## Working rules

1. Keep NOVA and AUREN scopes distinct. NOVA may link to AUREN but must not copy AUREN source into the NOVA APK.
2. Work on a feature branch and use pull requests. Do not push unreviewed changes directly to `main`.
3. A task is not complete because files were edited. Require tests/build evidence and a concise report.
4. Preserve failures as actionable diagnostics; never hide a failing test just to get a green status.
5. Do not store credentials or production secrets in source, workflow logs, or mobile assets.
6. Background automation validates and reports. It does not autonomously redesign product scope, merge pull requests, deploy production, or make irreversible changes.
7. For a failing run, inspect the failed job and logs, isolate the first actionable failure, add/fix a regression test, then rerun.

## Status fields to update during each engineering batch

- **Active area:** feature or subsystem being worked on.
- **Branch / PR:** exact branch and pull request link.
- **Analyze:** pass/fail/not run.
- **Tests:** pass/fail/not run, with failing test names.
- **Android build:** pass/fail/not run; artifact link if available.
- **Blockers:** specific issue and required action.
- **Next batch:** one bounded engineering task.

## Background CI

The scheduled workflow `.github/workflows/auren-background-maintenance.yml` runs Flutter dependency resolution, static analysis, and tests on a schedule and on manual request. It uploads logs even when checks fail. Android APK delivery remains verified through the Android build workflow.

## Initial known blocker

The NOVA Android starter pull request is still a prototype and its latest observed CI run failed in the test step, so an APK artifact must not be described as ready until a later run succeeds.
