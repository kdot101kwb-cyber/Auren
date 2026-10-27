# NOVA Grok Bot — signature features

This module adds differentiating product behavior around Grok rather than claiming a different base model.

## Signature capabilities

1. **Challenge Council** — strategist, critical reviewer, security reviewer, and cost guardian roles. These are policy/rubric roles in one response pipeline, not four independently running models.
2. **Evidence Mode** — research mode asks for verifiable source URLs, dates, and explicit uncertainty. The presence of a URL is only a basic signal, not proof that a source is trustworthy.
3. **Quality Gate** — mode-specific checklist for research, coding, planning, and content.
4. **Budget Guardian** — accepts an explicitly configured budget and requires authoritative provider pricing before estimating cost. This module does not invent prices or currently meter live API usage.
5. **Offline Honesty** — when network is unavailable, suggests a local queue/local tools; it never pretends that a remote Grok request ran offline. Local execution must be implemented separately.
6. **Permission Gate** — defaults to proposal-only and lists irreversible/external actions requiring explicit user approval.
7. **Private-by-default memory policy** — treats context as ephemeral unless the user consents to persistence and prohibits saving credentials/secrets.

## Integration boundary

The callable returns a `superpowers` policy payload for the selected mode. This is advisory metadata; it does not start additional model calls, execute tools, enforce a billing quota, create local offline inference, or persist memory. Server enforcement for a real budget ledger, local Android queue, consent UI, and independent reviewer runs must be added and tested separately.

## Validation

Run from `functions/`:

```sh
node --check nova_grok_superpowers.js
node --test nova_grok_superpowers.test.js
```
