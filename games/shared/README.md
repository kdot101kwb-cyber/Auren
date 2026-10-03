# Shared Game Runtime

All AUREN games should use these shared concepts:

- stable game id from `game_registry.json`
- shared player identity
- shared XP and progression contract
- shared achievements/statistics contract
- shared match/result contract
- shared save namespace per game
- common mobile input and accessibility expectations
- common telemetry and release validation

This layer is intentionally engine-neutral so Godot games can coexist with future lightweight game implementations.
