# NOVA Audit Timeline

The audit timeline is a read-only viewer for `NovaLocalAuditLedger`.

- Displays bounded device-local events.
- Opens event details with metadata already sanitized by the ledger.
- Does not edit, delete, or claim tamper-proof audit history.
- Sensitive metadata keys are redacted by the underlying ledger; callers must still avoid recording secrets.

Focused test: `flutter test test/features/audit/nova_audit_timeline_screen_test.dart`.
