export const AGENT_LISTING_STATES = Object.freeze(['draft', 'published', 'paused', 'revoked']);
export const PRICING_MODELS = Object.freeze(['free', 'per_action', 'subscription']);

const MAX_CAPABILITIES = 50;
const MAX_AMOUNT_MINOR = Number.MAX_SAFE_INTEGER;

function boundedText(value, fallback, maxLength) {
  if (typeof value !== 'string') return fallback;
  const normalized = value.trim();
  if (!normalized || /[\u0000-\u001f\u007f]/.test(normalized)) return fallback;
  return normalized.slice(0, maxLength);
}

function normalizeCapabilities(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value
    .filter((item) => typeof item === 'string')
    .map((item) => item.trim())
    .filter((item) => /^[a-zA-Z0-9][a-zA-Z0-9._:-]{0,79}$/.test(item)))]
    .slice(0, MAX_CAPABILITIES);
}

export function normalizeListing(input, agent) {
  const amount = input?.pricing?.amountMinor;
  const currency = typeof input?.pricing?.currency === 'string'
    ? input.pricing.currency.trim().toUpperCase()
    : 'USD';
  const model = PRICING_MODELS.includes(input?.pricing?.model)
    ? input.pricing.model
    : 'free';
  const amountMinor = Number.isSafeInteger(amount) && amount >= 0 && amount <= MAX_AMOUNT_MINOR
    ? amount
    : 0;
  return {
    agentId: boundedText(agent?.agentId, '', 128),
    name: boundedText(input?.name, boundedText(agent?.name, 'AUREN Agent', 120), 120),
    description: boundedText(input?.description, '', 1000),
    capabilities: normalizeCapabilities(input?.capabilities),
    version: boundedText(input?.version, boundedText(agent?.version, '1.0', 30), 30),
    state: AGENT_LISTING_STATES.includes(input?.state) ? input.state : 'draft',
    pricing: {
      model,
      currency: /^[A-Z]{3}$/.test(currency) ? currency : 'USD',
      amountMinor: model === 'free' ? 0 : amountMinor,
    },
  };
}

export function validateListingForPublish(listing) {
  if (!listing || typeof listing !== 'object') return false;
  if (typeof listing.agentId !== 'string' || !listing.agentId.trim()) return false;
  if (typeof listing.name !== 'string' || !listing.name.trim() || listing.name.length > 120) return false;
  if (typeof listing.version !== 'string' || !listing.version.trim() || listing.version.length > 30) return false;
  if (listing.state !== 'published' || !AGENT_LISTING_STATES.includes(listing.state)) return false;
  if (!PRICING_MODELS.includes(listing.pricing?.model)) return false;
  if (!/^[A-Z]{3}$/.test(listing.pricing?.currency || '')) return false;
  if (!Number.isSafeInteger(listing.pricing?.amountMinor) || listing.pricing.amountMinor < 0) return false;
  if (listing.pricing.model === 'free' && listing.pricing.amountMinor !== 0) return false;
  if (!Array.isArray(listing.capabilities) || listing.capabilities.length > MAX_CAPABILITIES) return false;
  if (listing.capabilities.some((item) => typeof item !== 'string' || !/^[a-zA-Z0-9][a-zA-Z0-9._:-]{0,79}$/.test(item))) return false;
  return true;
}

export function listingVersionKey(agentId, version) {
  return `${agentId}@${version}`;
}
