# AUREN deployment

The repository now builds and publishes two runtime images to GitHub Container Registry on pushes to `main`:

- `ghcr.io/kdot101kwb-cyber/auren-plugin-worker`
- `ghcr.io/kdot101kwb-cyber/auren-action-executor`

This is image publishing, not proof of a live production deployment.

## Required production services

Run the Action Executor and Plugin Worker on a private Docker-capable host/network. The Worker must not be public.

### Action Executor environment

- `GOOGLE_APPLICATION_CREDENTIALS` or workload identity for Firebase Admin
- `AUREN_PLUGIN_SIGNING_SECRET`
- `AUREN_PLUGIN_WORKER_URL`
- `AUREN_PLUGIN_WORKER_SECRET`
- `PORT=8080`

### Plugin Worker environment

- `WORKER_SHARED_SECRET`
- `PLUGIN_TIMEOUT_MS=5000`

Keep Worker network access disabled unless a plugin capability explicitly requires an allowlisted destination. Do not put provider API keys in plugin environments.

## Deployment status

No public production endpoint is currently configured in this repository. A real deployment requires a connected hosting target and its credentials/secrets.
