# NOVA Creative Toolkit — 20 Open-Source Projects

> Research catalog for the NOVA AI creative studio. These are upstream projects and model families to evaluate/integrate; they are **not bundled into the Android APK** and this catalog does not mean NOVA can generate media yet. Confirm each project's current license, model-weight license, hardware requirements, and commercial-use terms before deployment.

## Images, illustration, and design

1. **ComfyUI** — node-based workflow engine for image/video/audio generation; best candidate for a server-side generation worker. https://github.com/comfyanonymous/ComfyUI
2. **InvokeAI** — image generation and canvas-oriented editing workflow. https://github.com/invoke-ai/InvokeAI
3. **AUTOMATIC1111 Stable Diffusion WebUI** — extensible Stable Diffusion interface; check AGPL obligations before embedding or modifying. https://github.com/AUTOMATIC1111/stable-diffusion-webui
4. **Fooocus** — simplified SDXL image-generation experience; project maintenance/model-family limitations should be reviewed before choosing it for a long-lived product. https://github.com/lllyasviel/Fooocus
5. **Hugging Face Diffusers** — Python pipelines for image and video diffusion models; a useful backend abstraction rather than a mobile runtime. https://github.com/huggingface/diffusers
6. **Krita** — professional painting application and artist workflow reference; not an Android generation API. https://github.com/KDE/krita
7. **Blender** — 3D creation, rendering, materials, animation, and asset preparation. https://github.com/blender/blender

## Video, animation, and motion

8. **Wan** — text/image-to-video model family; verify the exact checkpoint and license before use. https://github.com/Wan-Video/Wan2.2
9. **LTX-Video** — video generation and editing research/model tooling; evaluate hardware and model-license terms. https://github.com/Lightricks/LTX-Video
10. **HunyuanVideo** — open-weight video generation family with substantial compute needs. https://github.com/Tencent/HunyuanVideo
11. **CogVideoX** — text/image-to-video model family with multiple checkpoint sizes and model-specific requirements. https://github.com/THUDM/CogVideo
12. **Open-Sora** — open video-generation research and pipeline. https://github.com/hpcaitech/Open-Sora
13. **LivePortrait** — portrait animation/re-enactment research; review consent, face-use, and model license safeguards. https://github.com/KwaiVGI/LivePortrait
14. **FFmpeg** — production-grade media conversion, trimming, muxing, and rendering pipeline; useful for post-processing generated clips. https://github.com/FFmpeg/FFmpeg

## Games, 3D assets, and interactive experiences

15. **Godot Engine** — open-source 2D/3D game engine; strong candidate for exporting small playable prototypes. https://github.com/godotengine/godot
16. **GDevelop** — visual, cross-platform game creation engine with a low-code workflow. https://github.com/4ian/GDevelop
17. **Phaser** — HTML5 2D game framework suitable for lightweight web-playable prototypes. https://github.com/phaserjs/phaser
18. **Three.js** — JavaScript 3D rendering library for interactive scenes and browser-based experiences. https://github.com/mrdoob/three.js
19. **Bevy** — data-driven game engine in Rust for more technical 2D/3D prototypes. https://github.com/bevyengine/bevy
20. **Blender MCP (community project)** — agent-to-Blender workflow integration candidate; community-maintained and not an official Blender component. https://github.com/ahujasid/mcp-for-blender

## Recommended NOVA integration architecture

- **Android client:** prompt editor, project gallery, job queue, progress, preview, save/share, and clear online/local status.
- **Creative API:** authenticated backend endpoint that validates input, enforces quotas, and returns a job ID. Never ship provider API keys in the APK.
- **Worker queues:** separate image, video, 3D/game, and media-processing workers so heavy GPU tasks do not block the mobile app.
- **Generation adapters:** normalize each provider's capabilities, model ID, license, output format, estimated cost, and failure states.
- **Asset storage:** private object storage with signed upload/download URLs, retention controls, and user deletion.
- **Safety and rights:** prompt/content checks, consent safeguards for likeness/voice, license metadata, provenance, and user confirmation before publishing.
- **Honest UX:** display queued/running/failed/completed states from the server. Do not show a completed badge or fake preview before an actual output file exists.
- **Offline behavior:** allow prompt drafting, saved projects, and local assets offline. Full-quality video/image generation is generally a server/GPU task; offline generation only works when a compatible model is installed locally and the device can run it.

## Practical rollout order

1. Ship the creative catalog and saved prompt drafts in the Flutter app.
2. Implement backend job API + private storage + job-status polling.
3. Integrate one image provider/worker and verify actual output files end-to-end.
4. Add FFmpeg post-processing and video worker after image jobs are stable.
5. Add game-project scaffolding (Godot/Phaser) as downloadable project files; do not claim the app itself is a game engine.
6. Add provider/model selection, cost visibility, rate limits, retries, and deletion/export controls.
7. Run Android CI, inspect the APK artifact, and test a real generation job before marking any capability complete.

## Selection notes

- “Open source” does not automatically mean the model weights have the same license as the code or that commercial use is unrestricted.
- Heavy video models usually need a desktop/server GPU and are not realistic to bundle into a typical Android phone.
- A no-per-generation-fee path is possible with self-hosted open models, but hardware, electricity, storage, and operations still cost money; hosted services may impose quotas or fees.
