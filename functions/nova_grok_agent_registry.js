'use strict';

// Curated NOVA Grok Bot engine registry.
// Catalog metadata is not proof that a worker is installed, configured, or executable.
// Only the xAI API adapter is currently implemented by novaGrokBot.
const ENGINES = Object.freeze([
  {
    id: 'grok-api',
    name: 'Grok API',
    role: 'conversation-research-planning',
    status: 'implemented-server-adapter',
    repository: 'https://github.com/xai-org/xai-sdk-ts',
    license: 'Apache-2.0',
    requiresNetwork: true,
    mayCostMoney: true,
    enabled: true,
    executionClass: 'model-only-no-external-side-effects',
  },
  {
    id: 'openhands',
    name: 'OpenHands Agent Server / Agent Canvas',
    role: 'coding-orchestration',
    status: 'candidate-not-connected',
    repository: 'https://github.com/OpenHands/OpenHands',
    license: 'MIT',
    requiresNetwork: 'depends-on-deployment',
    mayCostMoney: 'depends-on-model-and-hosting',
    enabled: false,
    executionClass: 'sandboxed-worker-required',
  },
  {
    id: 'grok-cli',
    name: 'grok-cli',
    role: 'grok-native-coding-worker',
    status: 'candidate-not-connected',
    repository: 'https://github.com/superagent-ai/grok-cli',
    license: 'verify-at-pinned-revision',
    requiresNetwork: true,
    mayCostMoney: true,
    enabled: false,
    executionClass: 'sandboxed-worker-required',
  },
  {
    id: 'codex-cli',
    name: 'OpenAI Codex CLI',
    role: 'alternative-coding-worker',
    status: 'candidate-not-connected',
    repository: 'https://github.com/openai/codex',
    license: 'Apache-2.0',
    requiresNetwork: 'depends-on-provider',
    mayCostMoney: 'depends-on-provider',
    enabled: false,
    executionClass: 'sandboxed-worker-required',
  },
  {
    id: 'gemini-cli',
    name: 'Gemini CLI',
    role: 'alternative-coding-worker',
    status: 'candidate-not-connected',
    repository: 'https://github.com/google-gemini/gemini-cli',
    license: 'Apache-2.0',
    requiresNetwork: 'depends-on-provider',
    mayCostMoney: 'depends-on-provider',
    enabled: false,
    executionClass: 'sandboxed-worker-required',
  },
  {
    id: 'goose',
    name: 'Goose',
    role: 'general-tool-using-agent',
    status: 'candidate-not-connected',
    repository: 'https://github.com/block/goose',
    license: 'Apache-2.0',
    requiresNetwork: 'depends-on-provider',
    mayCostMoney: 'depends-on-provider',
    enabled: false,
    executionClass: 'sandboxed-worker-required',
  },
]);

function listGrokBotEngines() {
  return ENGINES.map((engine) => ({...engine}));
}

function getGrokBotEngine(id) {
  const engine = ENGINES.find((item) => item.id === id);
  return engine ? {...engine} : null;
}

// Deliberately fail closed: the callable may only dispatch the model-only Grok API
// path. Candidate coding agents are catalog entries, not runnable integrations.
function resolveGrokBotEngine(id) {
  const engine = ENGINES.find((item) => item.id === id);
  if (!engine || !engine.enabled || engine.id !== 'grok-api') {
    return {ok: false, reason: 'engine-not-connected', engine: engine ? {...engine} : null};
  }
  return {ok: true, engine: {...engine}};
}

module.exports = {listGrokBotEngines, getGrokBotEngine, resolveGrokBotEngine};
