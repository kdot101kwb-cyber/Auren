# NOVA Grok Intelligence Core — learning loop

## Goal
Make Grok Bot the main assistant to NOVA: reduce repeated work, learn from confirmed corrections, research opportunities with evidence, challenge its own assumptions, and improve future outputs.

## Learning from mistakes
1. Compare requested outcome, draft, and observed result.
2. Record the specific failure or successful pattern.
3. Ask the user to confirm whether the lesson should be remembered.
4. Store only the confirmed, non-sensitive lesson under that user's account.
5. Retrieve a small number of relevant lessons for later tasks.
6. Verify improvements with tests, source checks, or outcome evidence.

This is persistent feedback memory, not automatic model-weight training. The initial implementation provides a safe lesson schema and context builder; production storage, retrieval relevance, UI consent, and end-to-end evaluation must be connected and tested before claiming the full loop works.

## Intelligence modes
- **Research radar:** source-backed findings, dates, geography/language, confidence, costs, eligibility, and next verification step.
- **Opportunity triage:** rank by expected value, time, upfront cost (prefer zero), eligibility, payout proof, and risk; never call an opportunity guaranteed without evidence.
- **Creative challenger:** generate multiple approaches, critique assumptions, select a low-cost experiment, and define success metrics.
- **Work compressor:** summarize intent, break work into steps, reuse prior context, batch independent tasks, and return a short action list.
- **Error clinic:** explain the cause, evidence, fix, regression test, and reusable lesson.
- **Main NOVA assistant:** route coding, research, planning, and content tasks to the relevant workflow; keep real-world actions approval-gated.

## Truth and safety
- No claim of 24/7 monitoring unless a scheduled worker and alert delivery are deployed.
- No claim of offline Grok inference; offline behavior needs an actual local model or verified local tools.
- No agent is considered installed merely because it appears in a registry.
- Do not store passwords, API keys, recovery codes, payment secrets, or unconfirmed personal inferences.
- Repository changes, publishing, messages, purchases, account changes, investments, deletion, and untrusted code execution require explicit approval.
- A source link is not proof of payout; independently verify eligibility, withdrawal fees, and recent payment evidence.

## Implementation status
The learning helper and tests are added on this branch. They do not by themselves establish a deployed persistent memory loop, live web monitoring, multiple independent council models, offline inference, or measured time savings. CI and APK build still need actual results.
