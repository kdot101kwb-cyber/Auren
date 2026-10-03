# AUREN: Lost World — 3D AAA Vertical Slice

## Purpose
First production 3D title and reference implementation for AUREN's permanent AAA game standard.

## Game identity
Original AUREN IP: a living world built around exploration, survival, discovery and cooperation. It is not an adaptation of Jumanji or another existing property.

## Vertical slice
- one polished 3D environment
- one original playable hero
- third-person camera
- touch movement and camera controls
- sprint, jump and interact
- traversal route
- environmental puzzle
- enemy archetype with navigation AI
- combat loop
- health, stamina and damage
- inventory and usable items
- quest objective and reward
- day/night transition
- ambient and action audio
- interaction/combat VFX
- checkpoint and resume
- performance telemetry

## Runtime contract
Flutter owns the AUREN shell. The 3D runtime owns rendering, animation, physics, navigation, combat, world streaming, VFX, audio and frame pacing.

Method channel: com.auren.games/3d_runtime
Event channel: com.auren.games/3d_runtime/events

## Quality gates
1. Launches through AUREN shell.
2. Saves and resumes checkpoint.
3. Touch controls work on Android.
4. Gameplay is testable and deterministic where required.
5. Critical results report to backend.
6. No placeholder asset is presented as final AAA content.
7. Performance is measured on target Android devices.
