# AUREN: Lost World — 3D Runtime

## Current playable vertical slice

The first AUREN 3D game slice now has a complete gameplay loop for the current procedural build:

- third-person 3D world, lighting, fog and camera
- Android touch movement/look
- touch + keyboard jump, sprint, attack and interact
- stamina drain/recovery
- enemy pursuit and melee damage
- enemy health, hit feedback and defeat feedback
- combat cooldown and hit detection
- combo chain with timed reset
- combo reward/healing loop
- four persistent reward chests with proximity interaction
- loot rewards and loot VFX
- gate objective and checkpoint completion
- death/respawn at checkpoint
- persistent checkpoint, health, enemy count, loot and opened-chest state
- day/night lighting cycle
- procedural combat/reward particles
- spatial audio runtime node
- performance telemetry
- mobile-compatible renderer target

## Honest production status

This repository build is **playable and feature-complete as a procedural vertical slice**, but it is **not being labeled final AAA art**.

The remaining production gates are external content/runtime work:
- original authored character and environment art
- authored character animation set
- final VFX and spatial audio assets
- authored level art and environmental storytelling
- Android packaging/signing and device QA
- measured performance budgets across target Android devices
- backend/server-authoritative competitive results for online modes

Those gates require real production assets, engine packaging and device/runtime testing; they are not claimed as complete merely because the gameplay code exists.
