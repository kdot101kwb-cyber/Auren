# AUREN Agent Marketplace & SDK Foundation

Agents publish versioned listings with capabilities and pricing. Marketplace reads are public only for published listings; writes remain trusted-backend operations.

## Lifecycle
draft -> published -> paused -> revoked

## Pricing
free, per_action, subscription. Amounts are integer minor units and currency is ISO-like 3-letter.

## Reputation
Completions and user reviews feed a separate reputation record. Reviews are user-scoped and server-created.

## Runtime
Plugin manifests remain policy-validated. The current sandbox policy is deny-by-default and is not an OS/container isolation boundary.

## Production SDK roadmap
- signed plugin packages
- package provenance and dependency lockfiles
- malware/dependency scanning
- isolated runtime/container
- quotas and metering
- API version negotiation
- automated rollback
- admin review and emergency revocation
