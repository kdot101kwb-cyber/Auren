# AUREN Games — 3D AAA Production Standard

## Permanent rule
AUREN Games is a 3D-first product. A game is not marked **AAA Ready** merely
because its menu or prototype is playable. The current Flutter game shell is
the launcher/prototype layer; production games must pass the 3D quality gates.

## Production architecture
- Flutter/AUREN shell: identity, profile, friends, purchases, achievements,
  notifications, settings and game discovery.
- 3D runtime: world rendering, animation, physics, camera, VFX and gameplay.
- Firebase/backend: authoritative player identity, match results, ranked stats,
  achievements and cloud saves.
- Asset pipeline: original characters, environments, props, materials,
  animation sets, VFX and audio.
- Performance targets: mobile-first quality tiers, adaptive resolution,
  asset streaming and low-data downloads.

## AAA quality gates
1. Original game identity and mechanics.
2. Real 3D environment and characters.
3. Character/environment animation.
4. Game-specific physics and rules.
5. Spatial/production audio.
6. Touch/controller UX.
7. Save/resume and progression.
8. Multiplayer where applicable.
9. Server-authoritative competitive results.
10. Mobile performance profiling before release.

## First production priority
**AUREN: Lost World** is the flagship 3D title. It gets the shared 3D runtime
foundation first, then the same runtime standards are applied to the other
games. The current 50-game catalog remains the product catalog, but each title
must graduate from prototype -> 3D vertical slice -> production build.

## Important
The existing Flutter playable screens are prototypes and must not be described
as finished AAA 3D games. This document is the implementation contract for
finishing them properly.
