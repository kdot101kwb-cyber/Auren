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
- Users can also copy a spreadsheet-ready CSV table containing price, currency, shipping/fees, estimated total, status, validity, minimum order, lead time, payment terms, notes, and capture date. Cells are quoted and embedded quotes/newlines are escaped.
- CSV cells that begin with spreadsheet formula characters (including after leading whitespace) are prefixed as text to reduce formula-injection risk when opening the export in spreadsheet software.
- The comparison view highlights repeated supplier labels after trimming, case-folding, and collapsing whitespace. This is only a duplicate-name hint, not proof that two records represent the same legal business.
- Each offer warns when minimum order, lead time, payment terms, or validity is missing, so users can request the missing terms before choosing. These are advisory warnings and do not block editing or export.
- If the validity field is entered as a real `YYYY-MM-DD` calendar date, the screen shows whether it has expired, expires today, or expires within seven calendar days. Free-form validity notes remain supported but are not interpreted as dates; no notification is sent.
- The summary shows counts of expired and soon-to-expire offers. A separate validity filter can show expired, due today, due within seven days, valid beyond seven days, or unknown/free-form validity. The copied summary includes the entered validity and any calculated warning.

## Persistence and trust boundaries

- Data is saved in SharedPreferences on the current device, using a key scoped to the current Firebase UID (or `guest` when signed out).
- Signed-in users can explicitly save the comparison to `users/{uid}/supplier_offer_comparisons/active_draft` and restore it on another device. The cloud document is owner-scoped by Firestore rules and limited to 10 validated offers.
- Local autosaves remain on this device; cloud changes are not silently uploaded. Use **Save to my account** after changes.
- Switching accounts resets the visible list and reloads that account's local key.
- Supplier identities, documents, quotations, and payment details are not verified by AUREN.
- Changing an offer to “tentatively selected” is not contract acceptance and does not send a purchase order or external message.

## Follow-up work

- Add automated Firestore rules integration tests for cross-user access denial and malformed offer payloads.
- Add structured verification evidence and quote attachments.
- Add delivered-quantity / tax / duty / insurance comparisons and explicit FX rates with timestamps.
- Add automated widget tests for sorting, status filtering, and account switching.

## Supplier request lifecycle screen

- The trade-deal screen links to **Supplier Requests**, which lists the signed-in user's contact and RFQ drafts and supports filtering by status.
- Callable endpoints provide list/detail/cancel/retry/status updates. Document IDs and request types returned to the client are taken from Firestore document identity, not mutable payload fields.
- Retry is limited to five attempts and resets the request to a draft for review. It does not resend the request.
- The UI only offers response-related transitions when the request records `externalDispatch: true`; the backend independently enforces this precondition and validates every transition.
- A draft, cancellation, or retry is local workflow bookkeeping. The current integration does not send email, SMS, chat messages, purchase orders, or RFQs to suppliers.
- Status and list data are loaded from the authenticated user's own request subcollections through callable functions; the server checks ownership before changing any shared mirror document.
