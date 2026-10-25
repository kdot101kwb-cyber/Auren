# NOVA Social Media Operator — Product and Integration Specification

## Goal

NOVA should become a supervised social-media operator that can research the market, propose and create image/video assets, prepare platform-specific posts, publish through authorized official integrations, monitor comments, draft or send replies according to user-configured rules, and learn from performance analytics.

**Current status:** this document defines the implementation contract. It does not grant permissions, connect social accounts, generate media, publish posts, or reply to comments by itself.

## Target accounts and existing workflow context

- Instagram: account/brand `KWB86`; Instagram was visible in Windsor.ai, but current publishing permission must be verified against the official integration.
- TikTok: `khaliedwalied403`; account was visible in Windsor.ai; direct organic publishing permission was not confirmed.
- YouTube: `Khalied Walied` / `@khaliedwalied-j1y`; analytics were visible in vidIQ/Windsor.ai; direct upload/comment-reply permissions must be verified.
- Buffer was considered as a scheduler, but an active account connection and posting permission are not assumed.
- A prior plan was to publish twice daily for two months. Actual publishing must not start until the channels are connected, permissions tested, and a queue is approved.

## Required capabilities

### 1. Market intelligence
- Collect authorized account analytics, platform trend/search signals, public competitor content, comments, and topic demand.
- Score opportunities by audience fit, trend momentum, competition, production effort, likely retention/click-through, and brand fit.
- Distinguish measured facts from hypotheses; attach source, observation time, and confidence to recommendations.
- Produce a daily brief: what to publish, why now, proposed hook, target audience, format, and success metric.
- Avoid claiming predictive certainty. Re-score from actual performance data.

### 2. Content planning and creation
- Maintain a content calendar and reusable campaign briefs.
- Generate image concepts, thumbnails, captions, scripts, hooks, and platform-specific variants.
- Generate actual image/video files only through a connected model/provider or a compatible self-hosted worker. Store job status, provider/model, output file, rights/licensing metadata, and error details.
- Create one master vertical video and adapt aspect ratio, safe areas, duration, captions, title, and description for Reels, TikTok, and Shorts where each platform's requirements allow.
- Never mark a job completed unless an actual output asset exists and can be opened.

### 3. Publishing
- Prefer official platform APIs or a verified scheduler such as Buffer where the connected account and selected post format are supported.
- Support draft, scheduled, publish, retry, cancel, and audit history.
- Respect each platform's API permissions, review requirements, rate limits, format rules, and music/copyright restrictions.
- If direct publishing is unsupported, clearly say so and provide a ready-to-publish export; never simulate a successful post.
- Start with an approved queue; allow the owner to pause all scheduled publishing immediately.

### 4. Comment and inbox handling
- Read comments/messages only through authorized APIs and within granted scopes.
- Classify as question, praise, complaint, spam, sales lead, safety issue, or other.
- Draft replies in the brand voice, using Arabic and other configured languages.
- Auto-reply only to low-risk, high-confidence categories explicitly enabled by the owner. Require review for complaints, refunds, personal data, legal/medical matters, harassment, controversy, and uncertain answers.
- Respect platform messaging policies and user privacy; never mass-message or spam.
- Log the source comment, classification, draft, approval/automation rule, sent result, and timestamp.

### 5. Learning and optimization
- Track impressions/views, watch time/retention when available, engagement rate, shares, saves, click-through, follower change, and conversions where connected.
- Compare each post against the account's own historical baseline and comparable formats, not vanity metrics alone.
- Recommend changes to hooks, duration, thumbnails, posting windows, topics, and calls to action.
- Use controlled experiments; do not claim a change caused improvement without adequate evidence.
- Provide weekly review and a ranked next-week plan.

## Safe architecture

1. **Flutter client:** dashboard, calendar, media previews, approvals, analytics, comment inbox, and kill switch.
2. **Backend API:** authenticates owner and client, validates every action, enforces scopes and per-channel quotas.
3. **Integration service:** OAuth for each platform/provider, encrypted server-side token storage, refresh/revocation, minimum scopes, and connection health checks.
4. **Media workers:** separate image/video pipelines and FFmpeg post-processing; store outputs in private object storage.
5. **Job queue:** durable states `draft → approved → queued → running → published/failed/cancelled`.
6. **Analytics store:** platform metrics with provenance, timestamps, retention limits, and deletion/export controls.
7. **Audit log:** actor, channel, operation, approval, result, and timestamp.

Never embed OAuth client secrets, API keys, long-lived access tokens, or service credentials in the APK or repository. Use official OAuth flows and server-side secret management.

## Permission model

- **Read analytics:** separate opt-in for each account and data scope.
- **Read comments:** separate opt-in; never infer permission from analytics access.
- **Reply to comments:** explicit permission and owner-selected auto-reply policy.
- **Upload/publish/schedule:** explicit publishing scope for each channel; user approval by default.
- **Create media:** separate provider connection/model license checks; media generation does not imply publishing permission.
- **Account administration/deletion:** owner-only, confirmation required.
- **Emergency stop:** immediately pause queued and future actions; in-flight platform calls may need to finish or be reconciled.

## Rollout gates

1. Connect one channel using official OAuth and verify read-only analytics.
2. Test creating a draft without publishing.
3. Verify upload/publish on a private, unlisted, or test destination where the platform supports it.
4. Implement one approved publish flow with visible status and audit log.
5. Add comment reading and draft replies.
6. Enable narrow auto-replies only after tests and explicit owner configuration.
7. Add market scoring and weekly performance feedback.
8. Expand channel-by-channel only after each integration passes permissions and failure tests.

## Operational target

A proposed starting schedule is two posts per day for 60 days, subject to owner approval, platform limits, content quality, and available generation capacity. NOVA should prioritize relevance and quality over forcing a post when market signals or asset quality are weak. No system can guarantee viral reach or literally unlimited free media generation.
