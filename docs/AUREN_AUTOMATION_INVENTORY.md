# AUREN Automation Inventory & Safety Audit

This read-only developer tool inventories declared GitHub Actions workflows and exported Firebase Cloud Functions that use `onSchedule`. It emits Markdown for CI summaries or JSON for downstream tooling.

## Run locally

```bash
node scripts/auren_automation_inventory.js
node scripts/auren_automation_inventory.js --format json
node --test scripts/auren_automation_inventory.test.js
```

## Safety checks

- Every statically detected Firebase CLI deployment command must include an explicit `--project` target; relying on `.firebaserc` defaults is rejected.
- A workflow identified as staging-only must target `auren-staging` for Firebase deployment commands.
- Missing explicit workflow permissions and missing concurrency on scheduled workflows are surfaced as review warnings, not hard failures, to avoid silently changing existing workflow behavior.
- The report contains static metadata only. It does not execute jobs, contact external providers, read environment variable values, or prove runtime availability.

## Limits

The inventory is a lightweight static scan, not a full YAML parser or runtime observability system. Commands assembled across multiple shell lines, dynamic schedule expressions, and indirect wrappers may require manual review. Runtime checks and deployment approvals remain separate controls.
