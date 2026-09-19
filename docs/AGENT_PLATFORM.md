# AUREN Agent Platform
AUREN now has the foundation for agent identity, agent-bound credentials, marketplace discovery and AUREN-A2A.
## Marketplace
Listings expose name, description, version, capabilities, pricing and state: draft/published/paused/revoked.
## AUREN-A2A
Messages use protocol/version/messageId/senderAgentId/recipientAgentId/type/payload. Production delivery must be mediated by the trusted backend with identity, capability, permission and replay checks.
## Security
Provider secrets remain server-side. Client-writable agent messages are not a production trust boundary. Future layers include signed envelopes, nonce/timestamp replay protection, capability tokens, trust/reputation, commerce settlement and disputes.
