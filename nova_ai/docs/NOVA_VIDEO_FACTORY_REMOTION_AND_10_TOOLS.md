# NOVA Video Factory: Remotion Integration and 10 Related Tools

Date checked: 2026-10-26

## Goal

Prepare a zero-budget-first pipeline for producing vertical videos for YouTube Shorts, TikTok, and Instagram. This document is a researched implementation plan, not a claim that a renderer has already been integrated or that videos are being generated.

## Architecture decision

- Keep the NOVA Android app in Flutter.
- Run video rendering as a separate Node.js/React worker or a local development/CI job; do not attempt to embed Remotion directly into Flutter.
- Use Remotion for parameterized scenes, animated captions, transitions, charts, and MP4 rendering.
- Use FFmpeg for media inspection, trimming, mixing, and post-render validation.
- Use optional local speech recognition/TTS only when the host machine has enough resources.
- Treat Android-only rendering as out of scope for the first slice. A phone UI can submit a brief and display job state/output; rendering runs on a compatible machine or service.
- Never call a video "generated" until the render process exits successfully, the output file exists, and basic media validation passes.
- No paid API keys, cloud GPU, or subscriptions by default. Cloud providers require explicit cost approval. Free stock assets must be license-checked.

## Remotion

Repository: https://github.com/remotion-dev/remotion  
Documentation: https://www.remotion.dev/docs  
Purpose: programmatic video composition in React, parameterized templates, motion graphics, audio and captions.

License note: Remotion uses its own license, not an OSI-approved open-source license. Individuals and eligible small teams may qualify for the free license; verify current eligibility before using it commercially. Rendering infrastructure is self-hosted unless separately provisioned.

Integration sequence:
1. Add a separate `nova_ai/video_factory/remotion_worker/` project only after confirming repository conventions and CI resource limits.
2. Start with one deterministic 9:16 template: hook, 3–5 scenes, captions, end card, audio track optional.
3. Accept a validated JSON brief (title, language, narration text, scene text, asset references, duration, aspect ratio).
4. Reject external generation providers unless explicitly configured; no secret keys in Flutter or source control.
5. Render a sample in CI and validate output with FFprobe/FFmpeg.
6. Add Flutter job submission/status only after the worker has a stable, tested interface.

## Ten related GitHub projects

These are complementary components, not ten interchangeable Remotion replacements. Their current maintenance, license, hardware needs, and API requirements must be rechecked before adoption.

| # | Project | Repository | Potential use for NOVA | Zero-budget caveat |
|---|---|---|---|---|
| 1 | OpenMontage | https://github.com/calesthio/OpenMontage | Agent-oriented video workflow combining research, script, assets, Remotion/FFmpeg and quality checks | Full pipeline is substantial; some provider paths require paid API keys. Review AGPL-3.0 obligations before adapting code. |
| 2 | HyperFrames | https://github.com/tjebastin/HyperFrames | HTML/CSS/GSAP motion-graphics rendering alternative for kinetic text and promo layouts | Confirm repository owner, setup, version and license before adoption; keep as an evaluated alternative, not a dependency yet. |
| 3 | FFmpeg | https://github.com/FFmpeg/FFmpeg | Convert, trim, mux audio, burn subtitles, inspect and validate media | Free to run locally; codec/build licensing varies. |
| 4 | whisper.cpp | https://github.com/ggml-org/whisper.cpp | Local transcription and subtitle timing from existing audio/video | Needs model files and CPU/RAM; model license and language quality should be checked. |
| 5 | Kokoro | https://github.com/hexgrad/Kokoro-82M | Local text-to-speech voice generation for narration | Check model weights license, runtime and Arabic voice support; do not assume Sudanese Arabic quality. |
| 6 | Piper | https://github.com/rhasspy/piper | Offline text-to-speech option for narration | Original repository status and voice/model licenses vary; validate the current maintained fork and Arabic voices. |
| 7 | ComfyUI | https://github.com/comfyanonymous/ComfyUI | Node-based local image-generation workflow for scene artwork | Practical image generation usually needs a capable GPU and model downloads; zero cash does not mean zero hardware cost. |
| 8 | Activepieces | https://github.com/activepieces/activepieces | Orchestrate repeatable research → script → render → review workflows | Self-hosting needs a running machine; individual connectors and services may require credentials. |
| 9 | Postiz | https://github.com/gitroomhq/postiz-app | Social publishing calendar and multi-platform scheduling layer | Self-hosting and platform developer/API permissions are required; automated publishing is not guaranteed for every platform/account. |
| 10 | Crawl4AI | https://github.com/unclecode/crawl4ai | Collect public web pages into structured research notes for scripts | Self-hosted crawler is free software, but obey website terms, robots rules, copyright and rate limits; hosted cloud is a separate paid/free-quota service. |

## Recommended first implementation (MVP)

1. Remotion-only template with text, locally supplied images, optional supplied audio, and vertical 1080x1920 output.
2. Render queue with states: draft → approved → rendering → validating → ready/failed.
3. FFprobe validation for file existence, duration, dimensions, audio stream, and non-zero size.
4. Save logs and failure reason; no false green status.
5. Export the final MP4 for manual review and upload first. Do not automate publishing until platform OAuth, scopes, and posting behavior are separately tested.

## Acceptance criteria

- A sample render produces a playable MP4 at the requested dimensions and duration.
- Invalid JSON or missing assets fail clearly before rendering.
- A failed render cannot be marked ready.
- No secret keys are stored in the Flutter client or committed to Git.
- CI tests the worker without paid APIs and without downloading large AI model weights.
- The app states that generation runs on a compatible worker, not silently on the Android phone.

## Current status

Research and integration plan only. Remotion has NOT yet been installed in NOVA, no worker has been deployed, and no sample video has been rendered by this repository.
