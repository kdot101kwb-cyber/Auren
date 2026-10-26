# NOVA Creative Media Tool Catalog

This catalog is a curated directory of open-source projects that NOVA can help the user install, configure, or launch. Listing a project here does **not** mean it is installed, hosted, or runnable inside the Android app. Heavy diffusion/video models generally need a compatible computer or GPU server; NOVA Android is the control panel.

## Recommended integration order for a $0-budget workflow

1. **MoneyPrinterTurbo** — automated short-video assembly from a topic/script. Good first workflow to evaluate, but external LLM/TTS/media APIs may require credentials or incur costs.
2. **MoviePy** — Python video editing, captions, audio mixing, trimming, and final assembly. Lightweight compared with generative video models; requires a Python runtime outside the Flutter app.
3. **ComfyUI** — node-based workflow interface and API for connecting image/video generation models. Best orchestration layer when a compatible host exists.
4. **AnimateDiff** — animation workflows based on compatible diffusion models; hardware and model compatibility vary.
5. **LTX-Video** — text/image-to-video model family; check the specific model's VRAM, license, and runtime requirements before downloading.
6. **Wan** — video generation model family; substantial GPU/model-storage requirements for many variants.
7. **HunyuanVideo** — high-quality video generation; typically resource intensive.
8. **VideoCrafter** — research video-generation project; check current maintenance, model availability, and license before adopting.
9. **Open-Sora** — open video-generation research ecosystem; verify the selected release's dependencies and license.
10. **Blender** — 3D creation, animation, and rendering; suitable for offline workflows on a capable computer, not as an Android-native rendering engine.
11. **Nerfstudio** — 3D reconstruction / NeRF research and visualization; specialized workflow, usually needs a capable workstation/GPU.

## Official project links

| Project | Repository / official page | Intended role in NOVA |
|---|---|---|
| MoneyPrinterTurbo | https://github.com/harry0703/MoneyPrinterTurbo | Topic-to-short-video workflow |
| ComfyUI | https://github.com/Comfy-Org/ComfyUI | Visual workflow orchestration; API client |
| Wan | https://github.com/Wan-Video/Wan2.1 | Generative video backend |
| LTX-Video | https://github.com/Lightricks/LTX-Video | Generative video backend |
| AnimateDiff | https://github.com/guoyww/AnimateDiff | Animation workflow |
| VideoCrafter | https://github.com/AILab-CVC/VideoCrafter | Research video generation |
| Open-Sora | https://github.com/hpcaitech/Open-Sora | Open video-generation research |
| HunyuanVideo | https://github.com/Tencent-Hunyuan/HunyuanVideo | Generative video backend |
| MoviePy | https://github.com/Zulko/moviepy | Video editing and compositing |
| Blender | https://www.blender.org/ | 3D production and rendering |
| Nerfstudio | https://github.com/nerfstudio-project/nerfstudio | 3D reconstruction / NeRF |

## Character, cartoon, and animation tools

- OpenToonz: https://opentoonz.github.io/e/
- Pencil2D: https://www.pencil2d.org
- Synfig Studio: https://www.synfig.org
- Tahoma2D: https://tahoma2d.org
- Blender Grease Pencil: https://www.blender.org
- Krita: https://krita.org
- Live2D Cubism: https://www.live2d.com/en/
- VRoid Studio: https://vroid.com/en/studio
- Mixamo: https://www.mixamo.com
- AccuRIG: https://actorcore.reallusion.com/auto-rig
- Cascadeur: https://cascadeur.com
- MakeHuman: https://www.makehumancommunity.org

Use these for 2D cartoons, character design, rigging, and animation. Some products have free-tier limits or restrictions on commercial use; 3D character and animation workflows usually need a computer.

## Audio, voice, music, and sound effects

- Audacity: https://www.audacityteam.org
- Ardour: https://ardour.org
- LMMS: https://lmms.io
- MuseScore: https://musescore.org
- BandLab: https://www.bandlab.com
- Suno: https://suno.com
- Udio: https://www.udio.com
- Stable Audio tools: https://github.com/Stability-AI/stable-audio-tools
- AudioCraft / MusicGen: https://github.com/facebookresearch/audiocraft
- Piper TTS: https://github.com/rhasspy/piper
- Coqui TTS: https://github.com/coqui-ai/TTS
- OpenVoice: https://github.com/myshell-ai/OpenVoice
- Whisper: https://github.com/openai/whisper
- whisper.cpp: https://github.com/ggml-org/whisper.cpp
- RVC WebUI: https://github.com/RVC-Project/Retrieval-based-Voice-Conversion-WebUI
- Bark: https://github.com/suno-ai/bark
- Freesound: https://freesound.org
- Pixabay Music: https://pixabay.com/music/
- BBC Sound Effects: https://sound-effects.bbcrewind.co.uk

Voice cloning/conversion must only use your own voice or voices for which you have explicit permission. Check each model, voice, music, and sound file's license separately before commercial use. Free access and quotas can change.

## Safe implementation requirements

- Show each item as a **tool directory entry** with official link, category, hardware needs, license/model-license notes, and integration status.
- Separate **Open project**, **Run locally**, and **Connect to a configured host** actions. Do not imply a link click installs software.
- Do not download multi-gigabyte model weights automatically. Ask for explicit approval and show estimated storage first.
- Do not embed API keys, access tokens, or credentials in the Flutter app. Use a secure backend or local host configuration.
- For a $0 setup, prioritize tools that can run on the user's existing computer and standard non-generative editing; cloud GPU providers and third-party APIs may cost money and are not guaranteed free.
- Provide graceful fallback: script + storyboard + captions + MoviePy assembly if a video-generation model is unavailable.
- Keep output rights and licensing visible. Repository code licenses and model-weight licenses can differ; check the current official terms before commercial use.

## Integration status

**Directory / research only.** These projects have not been installed, connected to a runtime, or verified as executable by this document. Actual integration requires a selected host environment, compatible dependencies, model files, and a successful end-to-end test.
