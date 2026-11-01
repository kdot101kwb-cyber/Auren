# NOVA Local Workspace Backup

The manual backup feature exports only the task workspace as versioned JSON.

- Schema version is validated before restore.
- The import is bounded to 1 MiB and at most 500 tasks.
- Invalid records and duplicate task IDs reject the entire restore before storage is changed.
- Export does not include approval records, audit events, Firebase identity, wallet details, or secrets.
- Copy/paste is manual; no cloud upload or external file transfer is performed.

Focused tests: `flutter test test/core/offline/nova_local_workspace_backup_service_test.dart`.
