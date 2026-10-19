# AUREN WONDERVERSE — Foundation

Status: **Foundation UI only; not a shipped or fully implemented system.**

WONDERVERSE is one parent feature, not 50 separate systems. The first interface exposes six experience portals:
- حضارة في دقيقة (One-Minute Civilization)
- اللغز الذي لا يملكه أحد (Mystery With No Owner)
- تأثير الفراشة (Butterfly Engine)
- مختبر المخلوقات (Creature Lab)
- مصنع الخيال (Wonder Lab)
- العوالم المتوازية (Parallel Worlds)

## Included in this change
- Self-contained Flutter screen and detail view.
- Entry card in the existing More screen.
- Widget tests for the portals and navigation.
- No Firestore writes, remote AI calls, analytics, or multiplayer state.

## Next stages
1. Review the existing feature registry and overlap before expanding experiences.
2. Define typed models, access/privacy rules, and a Firestore schema.
3. Add authenticated repositories and server-side validation before client writes.
4. Implement contribution history, moderation/reporting, and safe collaborative sessions.
5. Run Flutter analyze, widget tests, and Android build in CI.

Do not describe the experiences as live multiplayer until the backend and security rules exist.
