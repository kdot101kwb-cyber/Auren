# NOVA Viral Distribution Engine — first implementation slice

## Scope
This branch adds a deterministic, testable scoring core for manually supplied trend signals, a reusable original virtual-character concept model, and platform-specific distribution draft guidance.

## Included
- Weighted score using momentum, signal freshness, audience fit, shareability, retention potential, evidence confidence, competition, and production effort.
- Explicit blockers for stale or weak evidence and uncleared media rights.
- Original recurring character concept validation.
- YouTube Shorts, TikTok, Instagram Reels, and X adaptation guidance.
- Approval-required flag on every distribution draft.

## Not implemented yet
- Live trend collection or platform analytics APIs.
- Audience matching from connected accounts.
- Video/image generation, Remotion rendering, or asset licensing automation.
- Publishing, scheduling, account OAuth, or background queues.
- Model-based originality/similarity review.

## Safety and truthfulness
The score is a prioritization heuristic, not a virality probability or reach guarantee. The current first slice accepts manually supplied signals; it does not scrape platforms. No external post is sent. Rights clearance and user approval remain mandatory before production/publishing.

## Integration decision
The existing AUREN Entertainment Shorts, AI Series Studio, and production pipeline are the target surfaces. Keep NOVA as the planning/orchestration control plane; avoid a duplicate Shorts feed or a second entertainment subsystem. The next integration slice should connect NOVA briefs to the existing AUREN series/production models after repository-level contract tests.

## Validation
Flutter unit tests are included. CI must pass before this slice is called verified.
