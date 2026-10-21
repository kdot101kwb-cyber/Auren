# AUREN Developer Environment Preflight

## Purpose

A small, dependency-free local check to identify missing developer commands before running the full repository CI workflow.

## Checks

Required: Git, Node.js (major version 22 or newer recommended), Flutter, and Dart.
Optional: Firebase CLI and Java. Optional tools may be needed for particular backend or Android tasks but do not make the preflight fail.

## Run

```sh
node scripts/auren_developer_preflight.js
node --test scripts/auren_developer_preflight.test.js
```

## Safety and limitations

- Runs version commands only; does not install or update tools or modify project files.
- Does not print environment variable values or inspect credentials.
- Version strings differ across platforms; an unparseable version is marked unverified rather than assumed valid.
- A successful preflight does not replace Flutter analysis, tests, Android builds, or backend CI.
