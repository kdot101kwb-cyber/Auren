# AUREN Agent Developer Platform

## Plugin manifest
An agent/plugin declares a stable pluginId, name, version, capabilities and entrypoint.

## Capability model
Capabilities are allowlisted. Unknown capabilities are rejected. The client never receives provider secrets.

## Sandbox
The initial sandbox policy is deny-by-default for network and secrets, ephemeral filesystem and a 5-second execution budget. This is a policy foundation, not yet an OS/container isolation implementation.

## Publishing lifecycle
Draft -> validation -> review -> published -> paused/revoked.

## Required production controls
Signed packages, dependency scanning, malware scanning, isolated runtime/container, resource quotas, provenance, reviewer workflow, version rollback and emergency revocation.
