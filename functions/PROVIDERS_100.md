# AUREN 100 Providers

AUREN now has a catalog of 100 provider options covering text, vision, image,
video, audio, speech, music, search, embeddings and QC.

This catalog is intentionally separate from live adapters. A provider is not
called merely because it appears here. Production Worker v2 may execute only
providers for which AUREN has a real adapter, credentials/configuration and a
tested request/response contract.

The catalog includes free-tier/open-source candidates, but **freeTier does not
mean unlimited free generation**. Open-source video models still require GPU
compute unless AUREN has free compute available.

Hugging Face currently exposes many of these providers through one inference
interface, including Fal AI, Replicate, Together, Fireworks, Groq, DeepInfra,
Novita, Nscale and others. It also exposes text-to-video models such as
Wan, LTX-Video, HunyuanVideo and CogVideoX. See the official documentation
before enabling each adapter.

Next integration rule: $0-first -> free/open-source path -> low-cost path ->
paid fallback, while preserving the task idempotency key.
