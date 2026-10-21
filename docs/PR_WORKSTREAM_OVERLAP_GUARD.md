# AUREN PR Workstream Overlap Guard

A read-only GitHub Actions check that compares the changed file paths in the current pull request with other open pull requests in the same repository.

## Behavior

- Reads the pull request event payload and lists open pull requests through the GitHub REST API.
- Reads every paginated changed-file list, with a configurable API page-size safety bound in the implementation.
- Reports shared file paths in the GitHub Actions step summary and emits workflow warnings for overlaps.
- Fails the job if the API request, pagination, event parsing, or response validation fails. An incomplete scan is never reported as a clean scan.
- Uses only the workflow-provided token; no personal access token or repository secret is needed.
- Requests only `contents: read` and `pull-requests: read`; it does not edit, approve, close, or merge pull requests.

## Run locally

Requires Node.js 22 or newer. Set `GITHUB_REPOSITORY`, `GITHUB_TOKEN` with read-only pull-request access, and `GITHUB_EVENT_PATH` to a pull-request event JSON file, then run:

```sh
node --check scripts/auren_pr_overlap_guard.js
node --check scripts/pr_overlap_guard_checks.js
node --test scripts/pr_overlap_guard_checks.js
node scripts/auren_pr_overlap_guard.js
```

## Limitations

This is a changed-path overlap detector, not semantic conflict detection. Different files may implement the same behavior, and shared files may be intentional. Findings are advisory and require human review. The audit uses GitHub API data and cannot establish runtime health or prove that a pull request is safe to merge.
