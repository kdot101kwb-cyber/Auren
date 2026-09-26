# AUREN Music Concierge v7 — Final Test Checklist

## Session generation
- [ ] Empty source produces a safe empty state.
- [ ] Items without media URLs are excluded.
- [ ] Duration input is clamped to 10–240 minutes.
- [ ] Arabic and English duration phrases are parsed.
- [ ] Activity, mood, context, and content mode can be combined.

## Adaptive playback
- [ ] Adding a generated plan activates adaptive mode.
- [ ] Two or more skips trigger automatic upcoming-content adaptation.
- [ ] Two or more completions trigger automatic adaptation.
- [ ] Adaptation has a 20-second cooldown.
- [ ] Adaptation never replaces the currently playing item.
- [ ] New items are preferred before replaying served items.
- [ ] Recent creators are penalized to improve variety.
- [ ] Mood/context/content preferences influence replacements.

## Queue safety
- [ ] Queue contains no duplicate IDs.
- [ ] Auto-next continues after adaptation.
- [ ] Removing the next item cannot crash playback.
- [ ] Empty/exhausted adaptive pools fall back safely.
- [ ] Queue and history remain persisted after adaptation.

## Playback safety
- [ ] Invalid/empty media URLs fail gracefully.
- [ ] Playback errors do not corrupt queue state.
- [ ] Continue Listening remains restorable.
- [ ] Manual seek does not itself force an adaptive session.

## Release gate
The v7 code path should be smoke-tested on a real Android build with Firebase configured before release. Background playback/notification controls remain dependent on the Android host configuration documented in `docs/ENTERTAINMENT_BACKGROUND_AUDIO.md`.
