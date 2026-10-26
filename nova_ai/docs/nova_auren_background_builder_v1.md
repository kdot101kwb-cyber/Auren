# NOVA to AUREN Background Builder

NOVA is the personal Android control surface for the ongoing AUREN project. The first workspace records ideas, defects, market opportunities, and standalone-app candidates on the device.

## Safe execution stages

1. Read the AUREN source, blueprint, issues, pull requests, and failed workflow logs.
2. Deduplicate the backlog and rank tasks by user value, evidence, implementation cost, and risk.
3. Record market findings only with source URL, observed timestamp, geography/language, confidence, and an explanation of why the opportunity belongs in AUREN or merits a separate app.
4. Create one isolated feature branch per implementation task and keep credentials out of the Android app and generated code.
5. Run format, Flutter analyze, tests, and Android debug build. Attach real logs and artifact URLs to the task.
6. Permit bounded repair attempts; after repeated failure mark the task blocked and report the exact failing check.
7. Require owner approval for merges, production deployments, public releases, external publishing, financial actions, or permission changes.

## Background behavior boundary

A scheduled GitHub Actions worker can continue checks while the phone app is closed. The Android app itself cannot guarantee continuous work when closed. True autonomous coding and market scanning need a deployed backend/scheduler, a durable task queue, authorized repository access, source adapters, and a sandboxed implementation worker.

## Evidence standard

Do not claim a task is complete without a real commit/PR and successful checks. Do not claim revenue, market demand, or a successful device installation without evidence. An APK artifact from CI is a debug build, not a signed release and not proof of installation.
