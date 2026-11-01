# NOVA Local Workspace

The Workspace screen provides a device-local task list backed by
`NovaLocalWorkspaceStore`.

- Add, complete, refresh, and delete tasks.
- Shows total, completed, and remaining counts.
- Uses SharedPreferences through the existing store.
- Does not start agents, call external services, or claim cloud sync.
- Do not store passwords, wallet seeds, private keys, or payment credentials.

Run the focused test:

```sh
cd nova_ai
flutter test test/features/workspace/nova_workspace_screen_test.dart
```
