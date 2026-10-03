# AUREN 3D AAA Runtime Implementation

## Runtime boundary
Flutter calls MethodChannel `com.auren.games/3d_runtime`.

Required methods:
- `isAvailable`
- `launch`
- `command`
- `pause`
- `resume`
- `close`

Required event channel:
- `com.auren.games/3d_runtime/events`

## Launch payload
```json
{
  "gameId": "lost_world",
  "quality": "adaptive",
  "saveId": "optional"
}
```

## Runtime responsibilities
- 3D rendering
- third-person camera
- touch input
- player controller
- animation state machine
- physics/collision
- navigation AI
- combat
- VFX
- spatial audio
- world streaming
- checkpoints
- performance telemetry

## Android quality tiers
The runtime must support adaptive quality rather than assuming flagship hardware:
- low
- medium
- high
- ultra

Quality selection must consider memory, GPU capability, resolution and thermal state.

## Lost World first slice
The first real runtime build must contain:
1. original hero
2. playable 3D environment
3. traversal route
4. puzzle interaction
5. enemy AI
6. combat
7. health/stamina
8. inventory
9. quest/reward
10. checkpoint save/resume

No placeholder Flutter canvas implementation can satisfy this contract.
