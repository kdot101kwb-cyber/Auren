# AUREN Entertainment Production Engine

AUREN uses a provider-neutral production pipeline.

Engines:
- MoneyPrinterTurbo for automated short-form/script-to-video workflows.
- SkyReels V2/V3 for long-form scene generation and video extension.
- LTX-2 for synchronized audio/video and shot-level production.
- Wan and HunyuanVideo as alternative visual workers.

Long-form flow:
1. Story Bible
2. Film or episode script
3. Scene Planner
4. Shot Planner
5. Worker Queue
6. Continuity checks
7. Voice
8. Music and SFX
9. Assembly
10. AI Review
11. Output Library
12. Publish

A long film is split into scenes and shots so multiple GPU workers can process it in parallel. The mobile app owns job state and controls; GPU workers remain server-side.

Worker contract:
Input: jobId, type, targetMinutes, engine, storyBible, script, shots.
Output: status, progress, outputUrl, error.

Controls:
queued -> planning -> generating -> assembling -> review -> completed.
Failure and cancellation can be retried.

Rights:
Use only footage, voices, music and other assets with appropriate rights. Do not clone a real person's voice or likeness without permission.
