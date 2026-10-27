'use strict';

const PROJECTS = Object.freeze([
  {
    id: 'openhands',
    name: 'OpenHands',
    url: 'https://github.com/OpenHands/OpenHands',
    category: 'coding-agent',
    bestFor: 'Build and repair small software products',
    incomeUse: 'Ship narrow paid tools or offer scoped bug-fix/automation services',
    integrationCost: 'medium',
    runtimeCost: 'can be local; hardware and model requirements vary',
    licenseStatus: 'verify-current-license-and-dependencies',
    setupPriority: 1,
    risks: ['needs isolated execution', 'model/runtime may cost money', 'must verify generated code'],
  },
  {
    id: 'hermes-agent',
    name: 'Hermes Agent',
    url: 'https://github.com/NousResearch/hermes-agent',
    category: 'learning-agent',
    bestFor: 'Reusable skills and workflow memory',
    incomeUse: 'Reduce time spent on repeated research and delivery tasks',
    integrationCost: 'medium',
    runtimeCost: 'local or provider-backed depending on setup',
    licenseStatus: 'verify-current-license-and-dependencies',
    setupPriority: 2,
    risks: ['memory needs privacy controls', 'persistent agent needs monitoring'],
  },
  {
    id: 'alphacode-agent',
    name: 'AlphaCode (dragonked2)',
    url: 'https://github.com/dragonked2/alphacode',
    category: 'coding-agent',
    bestFor: 'Plan, edit, test, and review code; project describes browser/desktop tools and resumable agent workflows',
    incomeUse: 'Shorten delivery time for small software tools and scoped bug-fix services',
    integrationCost: 'medium',
    runtimeCost: 'Project documents a built-in free lane; validate its limits and supported machine before relying on it. Other model providers may charge.',
    licenseStatus: 'project reports MIT; re-check the exact revision, dependencies, and release before adoption',
    setupPriority: 3,
    risks: ['not an Android-only agent; needs a supported computer or build runner', 'free model availability and limits may change', 'browser/desktop actions require isolation and explicit approval'],
  },
  {
    id: 'browser-use',
    name: 'Browser Use',
    url: 'https://github.com/browser-use/browser-use',
    category: 'browser-automation',
    bestFor: 'Research and repetitive browser workflows',
    incomeUse: 'Collect public pricing/catalog information and prepare client research reports',
    integrationCost: 'medium',
    runtimeCost: 'browser plus model may require resources or paid API',
    licenseStatus: 'verify-current-license-and-dependencies',
    setupPriority: 3,
    risks: ['website terms and anti-bot limits', 'never bypass login or access controls', 'human approval for submissions'],
  },
  {
    id: 'n8n',
    name: 'n8n',
    url: 'https://github.com/n8n-io/n8n',
    category: 'workflow-automation',
    bestFor: 'Connect services and automate repeatable processes',
    incomeUse: 'Build and maintain small business workflow automations',
    integrationCost: 'medium',
    runtimeCost: 'self-hosting needs a machine and integrations may charge',
    licenseStatus: 'fair-code-review-required',
    setupPriority: 4,
    risks: ['license limits some commercial hosting uses', 'credentials must be stored securely'],
  },
  {
    id: 'moneyprinterturbo',
    name: 'MoneyPrinterTurbo',
    url: 'https://github.com/harry0703/MoneyPrinterTurbo',
    category: 'content-production',
    bestFor: 'Prototype short-video production from a topic',
    incomeUse: 'Create original niche videos to test audience demand and later monetize',
    integrationCost: 'medium',
    runtimeCost: 'media, model and rendering costs vary; not assumed free',
    licenseStatus: 'verify-current-license-and-media-rights',
    setupPriority: 5,
    risks: ['copyright and media licensing', 'platform monetization eligibility', 'generation may need paid services'],
  },
  {
    id: 'firecrawl',
    name: 'Firecrawl',
    url: 'https://github.com/firecrawl/firecrawl',
    category: 'web-research',
    bestFor: 'Turn accessible pages into structured research data',
    incomeUse: 'Produce verified market, product, and competitor research',
    integrationCost: 'medium',
    runtimeCost: 'self-hosting or hosted plans have different costs',
    licenseStatus: 'verify-current-license-and-service-terms',
    setupPriority: 6,
    risks: ['respect robots and website terms', 'source freshness and accuracy need checks'],
  },
  {
    id: 'dify',
    name: 'Dify',
    url: 'https://github.com/langgenius/dify',
    category: 'ai-workflow-builder',
    bestFor: 'Prototype a focused AI workflow or small app',
    incomeUse: 'Validate a niche assistant before investing in a full product',
    integrationCost: 'medium',
    runtimeCost: 'hosting and model calls may cost money',
    licenseStatus: 'verify-current-license-and-dependencies',
    setupPriority: 7,
    risks: ['data handling and deployment security', 'model calls are not automatically free'],
  },
  {
    id: 'agent-reach',
    name: 'Agent-Reach',
    url: 'https://github.com/Panniantong/Agent-Reach',
    category: 'research-connectors',
    bestFor: 'Explore public information across social and content platforms',
    incomeUse: 'Discover questions, trends, and niche demand for original content or tools',
    integrationCost: 'medium',
    runtimeCost: 'source availability and access methods vary',
    licenseStatus: 'verify-current-license-and-dependencies',
    setupPriority: 8,
    risks: ['platform access can break', 'respect privacy, terms, and rate limits'],
  },
]);

const INCOME_EXPERIMENTS = Object.freeze([
  {
    id: 'short-content',
    title: 'English faceless niche content',
    upfrontCostUsd: 0,
    timeToFirstSignalDays: 7,
    firstActionMinutes: 45,
    skillsReuse: 4,
    demandEvidenceNeeded: true,
    risk: 'medium',
    path: 'Publish a small batch of original shorts; measure retention and saves before scaling.',
    monetization: 'Affiliate links or eligible platform monetization only after checking country and account eligibility.',
  },
  {
    id: 'micro-automation-service',
    title: 'Small-business automation service',
    upfrontCostUsd: 0,
    timeToFirstSignalDays: 7,
    firstActionMinutes: 60,
    skillsReuse: 5,
    demandEvidenceNeeded: true,
    risk: 'low-medium',
    path: 'Build one demo that saves a real business time; offer a tightly scoped pilot before building a platform.',
    monetization: 'Fixed-price setup or maintenance after a customer agrees to the scope.',
  },
  {
    id: 'market-research-report',
    title: 'Niche market research reports',
    upfrontCostUsd: 0,
    timeToFirstSignalDays: 5,
    firstActionMinutes: 45,
    skillsReuse: 4,
    demandEvidenceNeeded: true,
    risk: 'low-medium',
    path: 'Choose one niche, gather public sources, verify dates and numbers, and create a sample report.',
    monetization: 'Sell a custom report only after validating a buyer and avoiding unsupported claims.',
  },
  {
    id: 'micro-tool',
    title: 'One-purpose micro-tool',
    upfrontCostUsd: 0,
    timeToFirstSignalDays: 14,
    firstActionMinutes: 90,
    skillsReuse: 5,
    demandEvidenceNeeded: true,
    risk: 'medium',
    path: 'Find one repeated problem, make a tiny local-first prototype, and get user feedback before adding features.',
    monetization: 'One-time purchase, service fee, or subscription only if hosting and payment access are feasible.',
  },
]);

function rankIncomeExperiments(options = {}) {
  const maxUpfrontCostUsd = Number.isFinite(options.maxUpfrontCostUsd) && options.maxUpfrontCostUsd >= 0
    ? options.maxUpfrontCostUsd : 0;
  const availableMinutesPerDay = Number.isFinite(options.availableMinutesPerDay) && options.availableMinutesPerDay > 0
    ? options.availableMinutesPerDay : 120;
  return INCOME_EXPERIMENTS
    .filter((item) => item.upfrontCostUsd <= maxUpfrontCostUsd && item.firstActionMinutes <= availableMinutesPerDay)
    .map((item) => ({
      ...item,
      score: Math.round(
        (item.skillsReuse * 10) +
        (Math.max(0, 21 - item.timeToFirstSignalDays) * 1.5) +
        (item.upfrontCostUsd === 0 ? 15 : 0) -
        (item.risk === 'medium' ? 8 : item.risk === 'low-medium' ? 3 : 0)
      ),
      expectedIncome: null,
      confidence: 'hypothesis-not-validated',
      nextStep: 'Validate demand with a small test before spending money or forecasting revenue.',
    }))
    .sort((a, b) => b.score - a.score || a.firstActionMinutes - b.firstActionMinutes);
}

function rankGithubProjects(options = {}) {
  const priority = options.priority || 'income';
  const maxIntegrationCost = options.maxIntegrationCost || 'medium';
  const allowedCosts = {low: 1, medium: 2, high: 3};
  const max = allowedCosts[maxIntegrationCost] || allowedCosts.medium;
  const incomeBoost = {
    'coding-agent': 18,
    'learning-agent': 13,
    'browser-automation': 15,
    'workflow-automation': 17,
    'content-production': 15,
    'web-research': 14,
    'ai-workflow-builder': 13,
    'research-connectors': 12,
  };
  return PROJECTS
    .filter((project) => (allowedCosts[project.integrationCost] || 3) <= max)
    .map((project) => ({
      ...project,
      score: (incomeBoost[project.category] || 0) + (priority === 'income' ? 20 : priority === 'research' && ['web-research', 'research-connectors'].includes(project.category) ? 20 : 0) + (project.setupPriority <= 3 ? 8 : 0),
      recommendation: 'candidate-only',
      checkedAt: null,
      licenseVerified: false,
      testedInNOVA: false,
    }))
    .sort((a, b) => b.score - a.score || a.setupPriority - b.setupPriority);
}


/**
 * A deliberately small, decision-ready daily plan. This does not browse the web,
 * contact prospects, install projects, or claim that an opportunity is verified.
 */
function buildSimpleOpportunityPlan(options = {}) {
  const minutes = Number.isFinite(options.availableMinutesPerDay) && options.availableMinutesPerDay > 0
    ? Math.min(720, Math.floor(options.availableMinutesPerDay)) : 120;
  const income = rankIncomeExperiments({maxUpfrontCostUsd: 0, availableMinutesPerDay: minutes})[0] || null;
  const projects = rankGithubProjects({priority: 'income', maxIntegrationCost: options.maxIntegrationCost || 'medium'}).slice(0, 3);
  const firstActions = {
    'micro-automation-service': {
      deliverable: 'One short demo showing a repetitive business task before and after automation.',
      firstAction: 'Pick one small business type and describe one repetitive task you can simplify with free tools.',
      successSignal: 'At least one real prospect confirms the problem is worth solving.',
    },
    'market-research-report': {
      deliverable: 'A one-page sample with dated sources, a competitor comparison, and clear unknowns.',
      firstAction: 'Choose one narrow niche and collect five public, dated sources.',
      successSignal: 'A potential buyer says the report answers a real decision they need to make.',
    },
    'short-content': {
      deliverable: 'Three original short-video scripts for one clearly defined audience.',
      firstAction: 'Choose one audience and write three distinct hooks for the same useful topic.',
      successSignal: 'Early audience retention, saves, meaningful replies, or repeat interest—not views alone.',
    },
    'micro-tool': {
      deliverable: 'A tiny clickable or local prototype for one repeated problem.',
      firstAction: 'Write the problem in one sentence and show the proposed solution to one potential user.',
      successSignal: 'A target user agrees to test it and can explain what value it gives them.',
    },
  };
  const detail = income ? firstActions[income.id] : null;
  return {
    budgetUsd: 0,
    availableMinutesPerDay: minutes,
    incomeExperiment: income ? {
      id: income.id, title: income.title, score: income.score,
      expectedIncome: null, confidence: 'hypothesis-not-validated',
      ...(detail || {}),
      validationChecks: [
        'Confirm a real buyer/problem before building more.',
        'Verify the chosen platform accepts users in Sudan and supports a usable payout method.',
        'Check fees, identity requirements, and terms from official sources before spending or signing up.',
      ],
      stopRule: 'Do not spend money or expand the build without a real demand signal.',
    } : null,
    githubCandidates: projects.map((project) => ({
      id: project.id, name: project.name, url: project.url,
      recommendation: 'candidate-only', licenseVerified: false, testedInNOVA: false,
      nextStep: 'Review README, current license, last release, dependency/security status, and hardware/runtime needs before any installation.',
    })),
    today: [
      'Spend the first work block creating the single deliverable above.',
      'Check one official source for platform/payout eligibility and record what is verified versus unknown.',
      'Ask one relevant person for feedback with a personalized message; do not mass-message or auto-send.',
    ],
    limitations: [
      'Ranking is heuristic, not live market proof.',
      'No prospect was contacted, project installed, content published, or money earned.',
      'Third-party AI, hosting, and media services may cost money even when source code is open.',
    ],
  };
}

module.exports = {PROJECTS, INCOME_EXPERIMENTS, rankIncomeExperiments, rankGithubProjects, buildSimpleOpportunityPlan};
