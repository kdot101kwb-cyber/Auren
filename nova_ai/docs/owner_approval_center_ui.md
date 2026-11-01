# NOVA Owner Approval Center

This screen lets the owner review and approve or reject queued proposals.

- Every proposal entered here is marked as requiring owner approval.
- Approval requires a separate confirmation dialog.
- Rejection requires a non-empty reason.
- The queue records state only; it has no action executor.
- A green approval state must never be interpreted as a completed external action.

Focused test: `flutter test test/features/approvals/nova_approval_center_screen_test.dart`.
