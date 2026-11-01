# NOVA offline workspace storage

The first offline workspace slice stores lightweight task records on the Android
device through the existing SharedPreferences dependency.

## Guarantees

- Task data remains available after an app restart and without network access.
- Records are keyed by stable IDs; saving an existing ID updates it rather than
  creating a duplicate.
- Invalid JSON and malformed individual records do not crash the workspace.
- The task history is bounded (500 records by default).
- Completion, deletion, and clear operations are explicit and return whether
  storage changed.

## Deliberate limits

This is device-local persistence, not cloud synchronization or encrypted vault
storage. Do not store passwords, access tokens, wallet seed phrases, payment
credentials, or sensitive identity documents in this store. Cloud sync and
conflict resolution require a separately reviewed design and owner approval.

## Validation

The accompanying Flutter tests cover persistence, updates, completion state,
corrupt-data recovery, invalid-record filtering, deletion, clearing, and the
history bound. CI must pass on the exact pull-request head before this batch
is considered verified.
