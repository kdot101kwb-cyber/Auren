# AUREN Entertainment Provider Strategy

The provider pool separates three things that must not be confused:

1. **Free tier** — a provider gives some free inference quota.
2. **Open-source model** — model weights/code may be available without a model license fee.
3. **Free compute** — GPU/CPU execution is actually free. This is the rare part.

For production video, AUREN therefore uses a fallback pool instead of promising
unlimited free generation.

Recommended order for a $0-first deployment:

- Self-hosted/open-source provider when AUREN has genuinely free compute.
- Hugging Face when its available quota is sufficient.
- Other configured low-cost/usage-based providers.
- Gemini/Veo as an explicit paid fallback.

API keys stay server-side. Provider health and cooldowns should be stored in
Firestore, and a production task must keep its deterministic idempotency key
when switching providers.
