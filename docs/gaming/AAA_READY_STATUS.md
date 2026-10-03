# AUREN Gaming — AAA Readiness Status

## Production rule
Every AUREN game is 3D-first. A game is not marked AAA-ready until the real 3D runtime, original assets, animation, gameplay, audio/VFX, performance, save state, and required online systems are integrated and tested on Android.

## Current flagship
AUREN: Lost World

## Implemented foundation
- AAA game manifest and quality gates
- 3D runtime bridge boundary
- Lost World vertical-slice production contract
- 3D asset contract
- Flutter shell/runtime separation
- Firebase backend boundary for identity, results, ranking, achievements and cloud saves

## Not falsely marked complete
The Flutter prototype screens are not treated as the finished 3D game.

## Release gates
1. Real 3D runtime launches from AUREN.
2. Third-person player controller works on touch.
3. Original 3D environment and character assets are integrated.
4. Animation, physics, camera, AI and combat are functional.
5. Audio and VFX are integrated.
6. Checkpoint/save/resume works.
7. Performance targets pass on supported Android tiers.
8. Crash/error telemetry is wired.
9. Multiplayer/ranked backend is implemented where required.
10. End-to-end Android build and smoke test passes.

Only after all applicable gates pass may Lost World be labeled AAA-ready.
