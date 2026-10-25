# NOVA AI — Higgsfield video provider

This is the first integration layer for Higgsfield's asynchronous generation API. It does not imply that Content Factory's complete UI workflow is exposed by API; model endpoints and request payloads are model-specific.

## Credentials and configuration

1. Create an API account at https://open.higgsfield.ai/ and configure billing there. API billing is separate from a Higgsfield website subscription.
2. Store credentials only in Firebase Secret Manager as `HIGGSFIELD_API_KEY_ID` and `HIGGSFIELD_API_KEY_SECRET`. Never place credentials in Flutter, app configuration, Firestore task metadata, or source control.
3. Set `HIGGSFIELD_VIDEO_ENDPOINT` to a documented video model endpoint from https://docs.higgsfield.ai/. The adapter rejects endpoints not hosted on `https://api.higgsfield.ai`.
4. Confirm the endpoint's required payload and estimate the generation cost before enabling production requests.

The official API uses `Authorization: Key <key-id>:<key-secret>`, returns a request ID, and exposes request status at `/requests/{request_id}/status`. Generated files may only remain available for at least seven days, so production rollout should download outputs to durable storage.

## Safety and current rollout state

Video generation is a paid external side effect and must remain approval-gated. Do not automatically retry a generation POST after an ambiguous network timeout: the provider may have accepted the first request. Status polling is safe to retry. Keep provider request IDs and status in the task record and log status transitions without logging credentials.

The NOVA queue worker now accepts approved `video_generation` tasks, submits them to the configured endpoint, records the provider request ID, and polls the status every minute. The task center exposes the video task type and displays a returned video URL. This is code-level integration only: it will fail closed until the two Firebase secrets and `HIGGSFIELD_VIDEO_ENDPOINT` are configured, the exact model endpoint/payload is confirmed, and Firebase Functions are deployed. The repository CI status must be checked after the latest commit; do not treat this as a live generation test.
