'use strict';

/**
 * AUREN Entertainment Provider Registry
 *
 * This module contains provider selection policy only. It never stores API keys
 * and never claims that an open-source model or a free quota means unlimited
 * free compute.
 */

const PROVIDERS = Object.freeze([
  {
    id: 'local_open_source',
    label: 'Self-hosted / Open-source',
    capabilities: ['text', 'image', 'video', 'audio', 'music', 'qc'],
    freeTier: true,
    requiresCredentials: true,
    costClass: 'compute-only',
    priority: 10,
  },
  {
    id: 'huggingface',
    label: 'Hugging Face Inference Providers',
    capabilities: ['text', 'image', 'audio', 'qc'],
    freeTier: true,
    requiresCredentials: true,
    costClass: 'free-limited',
    priority: 20,
  },
  {
    id: 'cloudflare_workers_ai',
    label: 'Cloudflare Workers AI',
    capabilities: ['text', 'image', 'embedding', 'qc'],
    freeTier: false,
    requiresCredentials: true,
    costClass: 'usage-based',
    priority: 30,
  },
  {
    id: 'openrouter',
    label: 'OpenRouter',
    capabilities: ['text', 'vision', 'qc'],
    freeTier: true,
    requiresCredentials: true,
    costClass: 'free-models-limited',
    priority: 40,
  },
  {
    id: 'gemini_veo',
    label: 'Google Gemini / Veo',
    capabilities: ['video', 'image', 'audio', 'qc'],
    freeTier: false,
    requiresCredentials: true,
    costClass: 'paid-video',
    priority: 50,
  },
  {
    id: 'auren_external',
    label: 'AUREN external provider adapter',
    capabilities: ['text', 'image', 'video', 'audio', 'music', 'qc'],
    freeTier: false,
    requiresCredentials: true,
    costClass: 'external',
    priority: 60,
  },
]);

const PROVIDER_MAP = new Map(PROVIDERS.map((provider) => [provider.id, provider]));

function listAurenEntertainmentProviders(capability) {
  const wanted = String(capability || '').trim().toLowerCase();
  return PROVIDERS
    .filter((provider) => !wanted || provider.capabilities.includes(wanted))
    .sort((a, b) => a.priority - b.priority)
    .map((provider) => ({...provider, capabilities: [...provider.capabilities]}));
}

function chooseAurenEntertainmentProvider({
  capability = 'video',
  configured = [],
  disabled = [],
  health = {},
  preferFree = true,
} = {}) {
  const configuredSet = new Set(configured.map((id) => String(id)));
  const disabledSet = new Set(disabled.map((id) => String(id)));

  const candidates = listAurenEntertainmentProviders(capability)
    .filter((provider) => configuredSet.has(provider.id))
    .filter((provider) => !disabledSet.has(provider.id))
    .filter((provider) => health[provider.id]?.available !== false);

  candidates.sort((a, b) => {
    if (preferFree && a.freeTier !== b.freeTier) return a.freeTier ? -1 : 1;
    return a.priority - b.priority;
  });

  return candidates[0] || null;
}

function buildAurenProviderAttemptOrder({
  capability = 'video',
  configured = [],
  disabled = [],
  health = {},
  preferFree = true,
} = {}) {
  return listAurenEntertainmentProviders(capability)
    .filter((provider) => configured.includes(provider.id))
    .filter((provider) => !disabled.includes(provider.id))
    .filter((provider) => health[provider.id]?.available !== false)
    .sort((a, b) => {
      if (preferFree && a.freeTier !== b.freeTier) return a.freeTier ? -1 : 1;
      return a.priority - b.priority;
    })
    .map((provider) => provider.id);
}

function getAurenEntertainmentProvider(id) {
  return PROVIDER_MAP.get(String(id || '')) || null;
}

module.exports = {
  PROVIDERS,
  listAurenEntertainmentProviders,
  chooseAurenEntertainmentProvider,
  buildAurenProviderAttemptOrder,
  getAurenEntertainmentProvider,
};
