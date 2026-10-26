# NOVA Remotion Video Worker (MVP)

This is a separate Node/React rendering worker. It is **not embedded in the Flutter Android app** and does not call paid AI APIs.

## Requirements
- Node.js 20+
- npm
- A compatible machine with browser dependencies for Remotion rendering

## Install and render
```bash
npm ci
npx remotion browser ensure
npm run render:sample
```

The render script uses `public/sample-props.json` and writes `NOVA_SAMPLE.mp4` into this project folder. The template is 1080×1920, 30 fps, with Arabic text and simple animated scenes. It does not generate narration, source images, or platform uploads.

## Validation
Check the file exists and is non-empty, then inspect its stream metadata with FFprobe if installed. Never mark a render as ready unless the command exits successfully and the MP4 is validated.

## Privacy and cost
No API keys are required. Keep secrets out of the mobile client and repository. This MVP uses only locally provided text and should be reviewed for Arabic glyph rendering in the target environment. Check Remotion's current license and commercial eligibility before commercial use.

## Current limitations
- No Flutter-to-worker API yet.
- No speech generation, automatic stock media, AI script generation, scheduling, or posting.
- Rendering requires Node/Chromium support; it is not an Android-native Flutter renderer.
