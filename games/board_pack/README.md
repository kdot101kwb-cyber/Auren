# AUREN Board Pack

Step 2 foundation for Ludo, Dominoes, and UNO.

## Shared rules contract

Each game exposes the same lifecycle:

- lobby -> match -> turn -> result
- deterministic match id
- player slots and turn order
- legal move validation
- score/result recording
- reconnect-safe state snapshots
- local practice mode without requiring a server

## Games

### Ludo
- 2-4 players
- dice state
- token positions
- turn rotation
- home/finish state
- capture events

### Dominoes
- 2-4 players
- shuffled deck/hand state
- legal placement validation
- turn rotation
- round scoring
- round/match result

### UNO
- 2-4 players
- deck/discard state
- hand state
- legal card validation
- color selection state
- draw/skip/reverse/wild actions
- win/result state

The gameplay implementations can be added independently while preserving these shared contracts.
