'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/scheduler');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {evaluateOpportunityTiming} = require('./nova_opportunity_timing');

const db = getFirestore();
const REGION = 'us-central1';
const COLLECTION = 'nova_market_watch';
const CACHE_ID = 'latest';
const CACHE_MS = 6 * 60 * 60 * 1000;
const WINDOW_DAYS = 7;

// Market hypotheses are discovery lenses, not pre-declared proof that a market exists.
const WATCH_THEMES = [
  {
    id: 'ai-workflow-automation',
    label: 'AI workflow automation for small businesses',
    query: 'AI automation small business',
    idea: 'A mobile-first workflow helper that turns repetitive business tasks into reusable, human-approved automations.',
    buyer: 'Small businesses and solo operators with repetitive admin work',
    mvp: ['Capture one repetitive workflow and its current time cost', 'Generate a step-by-step automation recipe', 'Run a dry-run with sample data', 'Show before/after time estimate and require approval before external actions'],
    stack: ['Flutter UI', 'Firebase Auth/Firestore already used by NOVA', 'Typed tool adapters with explicit permissions', 'Rule-based scoring before optional AI summaries'],
    validation: 'Interview 5 small businesses, demonstrate one narrow workflow, and ask for a paid pilot only after the problem is confirmed.',
    monetization: 'Illustrative setup service or monthly support; test willingness to pay before building billing.',
    risk: 'Crowded category; generic “AI agent” positioning is weak. Choose one painful workflow and a specific buyer.'
  },
  {
    id: 'offline-first-mobile',
    label: 'Offline-first personal and field-work apps',
    query: 'offline first mobile app sync',
    idea: 'An offline-first field-work notebook with queued actions, conflict-aware sync, and clear last-synced status.',
    buyer: 'Field teams and people working with unreliable connectivity',
    mvp: ['Local records and search', 'Queued edits with retry state', 'Visible sync status and timestamps', 'Conflict preview and user-controlled resolution'],
    stack: ['Flutter', 'SQLite/local persistence adapter', 'Firestore sync adapter behind an interface', 'Deterministic conflict-resolution tests'],
    validation: 'Publish a clickable demo and test airplane-mode workflows with 5 target users before expanding.',
    monetization: 'Paid setup, team customization, or a small team subscription after validating buyer demand.',
    risk: 'Sync correctness is harder than the UI. Do not promise conflict-free sync before stress tests.'
  },
  {
    id: 'creator-repurposing',
    label: 'Creator content repurposing and production tools',
    query: 'creator video repurposing captions AI',
    idea: 'A creator workbench that converts one original idea into a platform-specific production checklist and editable assets.',
    buyer: 'Solo creators and small content teams',
    mvp: ['Content brief and audience goal', 'Editable script, hook, shot list, captions and thumbnail brief', 'Rights/claim checklist', 'Exportable production pack without auto-posting'],
    stack: ['Flutter project workspace', 'Template-driven generation', 'Local drafts and export', 'Optional model adapter with visible source/provider'],
    validation: 'Make 3 sample packs for one niche and ask 5 creators to compare them with their current workflow.',
    monetization: 'Sell niche-specific production packs or a done-for-you content service before building a paid platform.',
    risk: 'Crowded creator market; avoid copyrighted imitation, fake engagement and claims of guaranteed reach.'
  },
  {
    id: 'developer-quality',
    label: 'AI coding-agent quality and regression testing',
    query: 'AI coding agent evaluation testing',
    idea: 'A lightweight evidence dashboard that checks whether coding-agent changes pass tests and records the exact commit, logs and artifacts.',
    buyer: 'Small software teams adopting coding agents',
    mvp: ['Define repeatable task fixtures', 'Collect exit codes and test summaries', 'Compare runs by commit', 'Block “done” status without evidence'],
    stack: ['Node.js worker', 'GitHub Actions/CI artifact links', 'Typed run schema', 'Promptfoo-style regression tests as an optional dev dependency'],
    validation: 'Run the checklist against 3 public sample repositories and share a reproducible report.',
    monetization: 'Offer a fixed-scope CI audit or test-pack setup; verify demand before productizing.',
    risk: 'CI credentials and untrusted code need isolation. Never execute repository code inside the production API process.'
  },
  {
    id: 'micro-saas-research',
    label: 'Niche micro-SaaS and market-gap research',
    query: 'micro SaaS customer pain point',
    idea: 'A source-backed opportunity brief builder that compares repeated complaints, existing alternatives, buyer segments and a smallest test.',
    buyer: 'Solo founders and small agencies choosing their next product or service',
    mvp: ['Store source links and observation dates', 'Cluster repeated pain points', 'Compare alternatives and saturation proxies', 'Generate a falsifiable experiment with pass/fail thresholds'],
    stack: ['Node.js collection workers', 'Firestore evidence records', 'Deterministic scoring', 'AI synthesis only after evidence collection'],
    validation: 'Produce 3 public, cited briefs and ask potential buyers whether the decision saved time or changed their choice.',
    monetization: 'Sell a niche research brief or product-discovery service before considering subscription access.',
    risk: 'Public discussion volume is not proof of willingness to pay. Every brief must state evidence limits.'
  },
  {
    id: 'small-business-digital-setup',
    label: 'Digital setup for local businesses',
    query: 'small business online booking inventory tools',
    idea: 'A simple setup kit for business profiles, catalog, inquiry tracking and follow-up drafts that works with low bandwidth.',
    buyer: 'Local shops and service providers with fragmented online presence',
    mvp: ['Business profile checklist', 'Product/service catalog template', 'Inquiry tracker', 'Editable follow-up drafts and simple performance log'],
    stack: ['Flutter forms', 'Local-first drafts', 'CSV/JSON export', 'Optional approved connectors only'],
    validation: 'Offer a manual setup to 3 businesses and record time saved and actual willingness to pay.',
    monetization: 'One-time setup service plus optional maintenance, with prices tested locally.',
    risk: 'Business platform access and payouts vary by country; never assume a platform feature is available.'
  }
];

function dayStart(date) {
  const d = new Date(date);
  d.setUTCHours(0, 0, 0, 0);
  return Math.floor(d.getTime() / 1000);
}

function clamp(value, min = 0, max = 100) {
  return Math.max(min, Math.min(max, value));
}

function growthScore(previous, recent) {
  if (!Number.isFinite(previous) || !Number.isFinite(recent)) return null;
  const growth = (recent - previous) / Math.max(previous, 3);
  const activity = Math.min(recent, 50) / 50;
  return Math.round(clamp(Math.max(0, growth * 45) + activity * 45));
}

async function fetchHnCount(query, from, to) {
  const url = new URL('https://hn.algolia.com/api/v1/search_by_date');
  url.searchParams.set('query', query);
  url.searchParams.set('tags', 'story');
  url.searchParams.set('numericFilters', 'created_at_i>=' + from + ',created_at_i<' + to);
  url.searchParams.set('hitsPerPage', '0');
  const response = await fetch(url, {signal: AbortSignal.timeout(10000)});
  if (!response.ok) throw new Error('Hacker News API HTTP ' + response.status);
  const data = await response.json();
  return Number(data.nbHits || 0);
}

async function fetchGitHubActivity(query, sinceDate) {
  const url = new URL('https://api.github.com/search/repositories');
  url.searchParams.set('q', query + ' created:>=' + sinceDate);
  url.searchParams.set('sort', 'stars');
  url.searchParams.set('order', 'desc');
  url.searchParams.set('per_page', '5');
  const response = await fetch(url, {
    headers: {accept: 'application/vnd.github+json', 'x-github-api-version': '2022-11-28'},
    signal: AbortSignal.timeout(10000),
  });
  if (!response.ok) throw new Error('GitHub Search API HTTP ' + response.status);
  const data = await response.json();
  return {
    totalCount: Number(data.total_count || 0),
    repositories: (Array.isArray(data.items) ? data.items : []).slice(0, 5).map((item) => ({
      name: String(item.full_name || '').slice(0, 160),
      url: String(item.html_url || '').slice(0, 500),
      description: String(item.description || '').slice(0, 300),
      stars: Number(item.stargazers_count || 0),
      createdAt: String(item.created_at || ''),
      language: String(item.language || '').slice(0, 60),
    })),
  };
}

function buildPack(theme, signals, nowIso) {
  const evidence = [
    'Hacker News recent 7-day mentions: ' + (signals.recentMentions == null ? 'unavailable' : signals.recentMentions),
    'Hacker News preceding 7-day mentions: ' + (signals.previousMentions == null ? 'unavailable' : signals.previousMentions),
    'New GitHub repositories matching the discovery query: ' + (signals.githubNewRepositories == null ? 'unavailable' : signals.githubNewRepositories),
    'Source window ends at: ' + nowIso,
  ];
  const readinessChecklist = [
    'Problem and target buyer stated',
    'Evidence links and observation window recorded',
    'Competitor/alternative review still required',
    'Zero-cost validation experiment defined',
    'MVP scope and acceptance criteria defined',
    'Privacy, security, and licensing review required before release',
    'No app is considered production-ready until build, tests, and manual QA pass',
  ];
  return {
    title: theme.label,
    productHypothesis: theme.idea,
    targetBuyer: theme.buyer,
    evidenceSummary: evidence,
    evidenceConfidence: signals.recentMentions == null || signals.githubNewRepositories == null ? 'incomplete' : 'early-signal-only',
    mvpScope: theme.mvp,
    proposedArchitecture: theme.stack,
    validationExperiment: theme.validation,
    monetizationHypothesis: theme.monetization,
    keyRisks: theme.risk,
    acceptanceCriteria: [
      'Core flow works with sample data and shows source provenance',
      'Failure and offline states are visible; no fake success state',
      'Sensitive or external actions require explicit user approval',
      'Automated tests cover normal, empty, stale, malformed, and unavailable-source cases',
      'Android build and Flutter analysis pass before release readiness is claimed',
    ],
    readinessChecklist,
    status: 'research_pack_ready',
    notYetBuilt: true,
    disclaimer: 'This is a research-backed build brief, not a validated business, finished application, forecast, or guaranteed income.',
  };
}

async function scanMarket(now = new Date()) {
  const today = dayStart(now);
  const weekSeconds = WINDOW_DAYS * 86400;
  const recentStart = today - weekSeconds;
  const previousStart = today - 2 * weekSeconds;
  const sinceDate = new Date((today - 90 * 86400) * 1000).toISOString().slice(0, 10);
  const checkedAt = now.toISOString();
  const opportunities = [];

  // Keep the number of unauthenticated GitHub Search requests bounded.
  for (const theme of WATCH_THEMES) {
    const [hn, github] = await Promise.allSettled([
      Promise.all([
        fetchHnCount(theme.query, recentStart, today),
        fetchHnCount(theme.query, previousStart, recentStart),
      ]),
      fetchGitHubActivity(theme.query, sinceDate),
    ]);
    const hnOk = hn.status === 'fulfilled';
    const githubOk = github.status === 'fulfilled';
    const recentMentions = hnOk ? hn.value[0] : null;
    const previousMentions = hnOk ? hn.value[1] : null;
    const githubNewRepositories = githubOk ? github.value.totalCount : null;
    const trend = growthScore(previousMentions, recentMentions);
    const ecosystem = githubOk ? Math.round(clamp(Math.log10(githubNewRepositories + 1) * 25)) : null;
    const scoreParts = [trend, ecosystem].filter(Number.isFinite);
    const score = scoreParts.length ? Math.round(scoreParts.reduce((a, b) => a + b, 0) / scoreParts.length) : null;
    const signals = {
      recentMentions,
      previousMentions,
      trendScore: trend,
      githubNewRepositories,
      githubExamples: githubOk ? github.value.repositories : [],
      sourceStatus: {hackerNews: hnOk ? 'ok' : 'unavailable', github: githubOk ? 'ok' : 'unavailable'},
      checkedAt,
    };
    opportunities.push({
      id: theme.id,
      label: theme.label,
      score,
      timing: evaluateOpportunityTiming(signals),
      signals,
      buildPack: buildPack(theme, signals, checkedAt),
      sourceLinks: [
        'https://hn.algolia.com/',
        'https://github.com/search?q=' + encodeURIComponent(theme.query),
      ],
    });
  }

  opportunities.sort((a, b) => (b.score ?? -1) - (a.score ?? -1));
  return {
    generatedAt: checkedAt,
    window: 'Last 7 complete UTC days vs preceding 7 complete UTC days; GitHub repositories created in the last 90 days',
    sourcePolicy: 'Public Hacker News Algolia Search API and GitHub Search API. Results are discovery signals only; mention/repository counts do not prove demand or willingness to pay.',
    opportunities,
    summary: {
      themesScanned: opportunities.length,
      sources: ['Hacker News Algolia Search API', 'GitHub Search API'],
      sourceFailures: opportunities.reduce((n, item) => n + Object.values(item.signals.sourceStatus).filter((x) => x !== 'ok').length, 0),
      readyBuildPacks: opportunities.filter((item) => item.buildPack.status === 'research_pack_ready').length,
      actualAppsBuilt: 0,
    },
  };
}

exports.getNovaMarketWatch = onCall(
  {region: REGION, timeoutSeconds: 180, memory: '512MiB', enforceAppCheck: true},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in to access NOVA Market Watch.');
    const ref = db.collection(COLLECTION).doc(CACHE_ID);
    const snap = await ref.get();
    const cached = snap.data();
    if (cached?.generatedAt && Date.now() - Date.parse(cached.generatedAt) < CACHE_MS) {
      return {...cached, cached: true};
    }
    try {
      const result = await scanMarket();
      await ref.set({...result, updatedAt: FieldValue.serverTimestamp()});
      return {...result, cached: false};
    } catch (error) {
      const message = String(error?.message || error).slice(0, 300);
      console.error('NOVA Market Watch scan failed', message);
      // A failed refresh should not hide the last successful report from the user.
      // Mark it stale explicitly so the UI cannot mistake old evidence for a fresh scan.
      if (cached?.generatedAt) {
        return {
          ...cached,
          cached: true,
          stale: true,
          refreshError: 'The latest refresh failed; showing the last successful report.',
        };
      }
      throw new HttpsError('unavailable', 'Market scan is temporarily unavailable and no cached report exists.');
    }
  },
);

exports.runNovaMarketWatchDaily = onSchedule(
  {schedule: 'every day 08:40', timeZone: 'Africa/Khartoum', region: REGION, timeoutSeconds: 300, memory: '512MiB', maxInstances: 1},
  async () => {
    const result = await scanMarket();
    await db.collection(COLLECTION).doc(CACHE_ID).set({...result, updatedAt: FieldValue.serverTimestamp()});
  },
);

exports.scanNovaMarketForTest = scanMarket;
exports.scoreNovaMarketGrowthForTest = growthScore;
exports.buildNovaMarketPackForTest = buildPack;
exports.novaMarketWatchThemesForTest = WATCH_THEMES;

exports.evaluateNovaOpportunityTimingForTest = evaluateOpportunityTiming;
