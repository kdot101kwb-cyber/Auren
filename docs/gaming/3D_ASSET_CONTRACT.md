# AUREN 3D Asset Contract

Every production game asset requires an ownership/license record, quality tier and runtime budget.

## Asset classes
- Characters: rigged, skinned, LOD0/LOD1/LOD2.
- Environments: modular meshes, collision, LODs and streaming cells.
- Props: collision and interaction metadata.
- VFX: mobile-safe particle budgets with quality fallbacks.
- Audio: music, ambience, SFX and spatial cues.
- UI: touch/controller-safe HUD.

## Quality tiers
- Low: low-data/mobile fallback.
- Medium: balanced Android devices.
- High: high-end Android devices.
- Ultra: optional future capability.

## Runtime rule
No single high-resolution asset is mandatory for every device. Runtime selects assets/effects by device capability and memory budget.
