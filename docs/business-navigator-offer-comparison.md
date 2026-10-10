# Supplier offer comparison

The Business Navigator offer comparison screen is a local-first helper for recording quotes the user has actually received.

## Captured fields

- Supplier name, quoted amount, currency, shipping/fees
- Minimum order, lead time, payment terms, offer validity, notes
- Date the offer was recorded
- Lifecycle status: received, needs verification, shortlisted, tentatively selected, rejected

## Comparison behavior

- Offers are sorted by currency first and then by recorded price plus recorded shipping/fees.
- The lowest-cost label is only applied among offers in the same currency with parseable non-negative amounts.
- Blank or invalid numeric values are not ranked.
- Currency conversion, tax/duty estimation, product-spec normalization, and exchange-rate lookup are not performed.
- Users can filter by lifecycle status, edit/delete offers, and copy a plain-text summary.

## Persistence and trust boundaries

- Data is saved in SharedPreferences on the current device, using a key scoped to the current Firebase UID (or `guest` when signed out).
- These offer records are not synced to Firestore or another device in this version.
- Switching accounts resets the visible list and reloads that account's local key.
- Supplier identities, documents, quotations, and payment details are not verified by AUREN.
- Changing an offer to “tentatively selected” is not contract acceptance and does not send a purchase order or external message.

## Follow-up work

- Add owner-scoped cloud persistence and Firestore rules.
- Add structured verification evidence and quote attachments.
- Add delivered-quantity / tax / duty / insurance comparisons and explicit FX rates with timestamps.
- Add automated widget tests for sorting, status filtering, and account switching.
