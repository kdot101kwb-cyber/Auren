# AUREN CI Failure Triage

## Purpose

This read-only follow-up workflow creates a compact, sanitized signal summary when **AUREN Flutter CI** or **AUREN Backend CI** completes. It is intended to help developers locate relevant diagnostic artifacts faster, not to diagnose or repair code automatically.

## Behavior

- Runs on `workflow_run.completed` for the two named CI workflows.
- Downloads artifacts from the completed run and scans only `.log` and `.txt` files.
- Counts known Flutter/Dart, Node test, Gradle, dependency, Firebase permission, network timeout, and missing-plugin patterns.
- Publishes counts and artifact-relative file names to the triage workflow's step summary.
- Does not execute downloaded artifacts, print raw log lines, write to pull requests, change the original CI conclusion, or modify application files.

## Permissions and trust boundaries

The workflow requests only `actions: read` and `contents: read`. It checks out the trusted default-branch version of the classifier. Artifact content is treated as untrusted data and is read only as text. No pull-request code from the triggering run is executed.

## Limitations

- Pattern counts are clues, not root-cause analysis; counts can include secondary or cascading errors.
- The report may be incomplete if artifact download fails or a workflow did not upload logs.
- Unknown error signatures will not be classified.
- The workflow does not replace reviewing the original run, source changes, or test context.
- Because `workflow_run` workflows use the default branch version, this workflow becomes active for future completed runs only after its change reaches the default branch.
