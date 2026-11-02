# NOVA Operations — final hardening

Batch 6 connects owner decisions to the device-local audit timeline.

- Explicitly confirmed approvals are recorded as `owner_approval` audit events.
- Rejections are recorded as `owner_rejection` events, including the owner's reason.
- A decision is only a recorded permission decision; it does not claim to execute the proposed action.
- The audit ledger applies its existing metadata redaction and local retention rules.
- The audit history remains device-local and is not tamper-proof or cloud-synchronized.

Automated tests cover approval, rejection with reason, and the absence of a decision when explicit owner confirmation is false.
