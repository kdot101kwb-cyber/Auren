# AUREN deployment

The repository now builds and publishes two runtime images to GitHub Container Registry on pushes to `main`:

- `ghcr.io/kdot101kwb-cyber/auren-plugin-worker`
- `ghcr.io/kdot101kwb-cyber/auren-action-executor`

This is image publishing, not proof of a live production deployment.

## Required production services

Run the Action Executor and Plugin Worker on a private Docker-capable host/network. The Worker must not be public.

### Action Executor environment

- `FIREBASE_SERVICE_ACCOUNT_JSON` (Render secret; JSON for the Firebase service account)
- `AUREN_PLUGIN_SIGNING_SECRET` (Render generates this automatically)
- `AUREN_PLUGIN_WORKER_URL` (wired automatically from the private worker)
- `AUREN_PLUGIN_WORKER_SECRET` (wired automatically from the worker secret)
- `PORT=8080`

### Plugin Worker environment

- `WORKER_SHARED_SECRET` (Render generates this automatically)
- `PLUGIN_TIMEOUT_MS=5000`

Keep Worker network access disabled unless a plugin capability explicitly requires an allowlisted destination. Do not put provider API keys in plugin environments.

## Deployment status

No public production endpoint is currently configured in this repository. A real deployment requires a connected hosting target and its credentials/secrets.
