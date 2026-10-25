'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const db = getFirestore();
const REGION = 'us-central1';
const SIGNALS_COLLECTION = 'nova_signal_scans';
const LATEST_DOC = 'latest';

// Discovery themes are hypotheses to test, not claims that any term will become popular.
const SIGNAL_THEMES = [
  {term: 'agentic browser', domain: 'agenticbrowser.com', idea: 'Build browser-workflow demos and automation setup services for small businesses.'},
  {term: 'synthetic memory', domain: 'syntheticmemory.com', idea: 'Create evaluation datasets and memory-system demos for AI developers.'},
  {term: 'MCP server', domain: 'mcpserver.com', idea: 'Package setup, testing, and documentation services for small MCP integrations.'},
  {term: 'AI agent evaluation', domain: 'aiagentevaluation.com', idea: 'Sell lightweight evaluation reports and test cases for AI agent teams.'},
  {term: 'local AI inference', domain: 'localaiinference.com', idea: 'Create setup guides and local-model optimization services.'},
  {term: 'voice AI agent', domain: 'voiceaiagent.com', idea: 'Build demo call flows and FAQ assistants for local service businesses.'},
  {term: 'AI observability', domain: 'aiobservability.com', idea: 'Offer dashboards, incident checklists, and evaluation templates for AI products.'},
  {term: 'small language model', domain: 'smalllanguagemodel.com', idea: 'Create comparison guides and deployment checklists for small models.'},
  {term: 'AI coding agent', domain: 'aicodingagent.com', idea: 'Sell repository audits, test-generation help, and coding-agent workflow templates.'},
  {term: 'personal AI assistant', domain: 'personalaiassistant.com', idea: 'Build privacy-conscious assistant prototypes and workflow templates.'},
];

function utcDayStart(date) {
  const value = new Date(date);
  value.setUTCHours(0, 0, 0, 0);
  return Math.floor(value.getTime() / 1000);
}

function safeDomainStatus(status, body) {
  if (status === 404) return 'not_found_in_registry_check';
  if (status === 200) return 'registered';
  if (status === 429) return 'rate_limited_unverified';
  return 'unverified';
}

async function fetchHnCount(term, from, to) {
  const url = new URL('https://hn.algolia.com/api/v1/search_by_date');
  url.searchParams.set('query', term);
  url.searchParams.set('tags', 'story');
  url.searchParams.set('numericFilters', 'created_at_i>=' + from + ',created_at_i<' + to);
  url.searchParams.set('hitsPerPage', '0');
  const response = await fetch(url, {signal: AbortSignal.timeout(10000)});
  if (!response.ok) throw new Error('Hacker News search HTTP ' + response.status);
  const data = await response.json();
  return Number(data.nbHits || 0);
}

async function checkComDomain(domain) {
  try {
    const response = await fetch('https://rdap.verisign.com/com/v1/domain/' + encodeURIComponent(domain), {
      headers: {accept: 'application/rdap+json'},
      signal: AbortSignal.timeout(8000),
    });
    return safeDomainStatus(response.status);
  } catch (_) {
    return 'unverified';
  }
}

function scoreGrowth(previous, recent) {
  const growth = (recent - previous) / Math.max(previous, 1);
  const activity = Math.min(recent, 30) / 30;
  const growthScore = Math.max(0, Math.min(70, growth * 20));
  return Math.round(Math.min(100, growthScore + activity * 30));
}

async function scanSignals(now = new Date()) {
  const today = utcDayStart(now);
  const week = 7 * 24 * 60 * 60;
  const previousStart = today - 2 * week;
  const recentStart = today - week;
  const rows = [];
  // Keep concurrency low and tolerate partial source failures.
  for (let i = 0; i < SIGNAL_THEMES.length; i += 2) {
    const batch = SIGNAL_THEMES.slice(i, i + 2);
    const results = await Promise.all(batch.map(async (theme) => {
      let recentMentions = null;
      let previousMentions = null;
      let sourceStatus = 'ok';
      try {
        [recentMentions, previousMentions] = await Promise.all([
          fetchHnCount(theme.term, recentStart, today),
          fetchHnCount(theme.term, previousStart, recentStart),
        ]);
      } catch (_) {
        sourceStatus = 'unavailable';
      }
      const domainStatus = await checkComDomain(theme.domain);
      const score = recentMentions === null ? null : scoreGrowth(previousMentions, recentMentions);
      return {
        term: theme.term,
        domain: theme.domain,
        idea: theme.idea,
        recentMentions,
        previousMentions,
        score,
        source: 'Hacker News Algolia Search API',
        sourceStatus,
        domainStatus,
        domainCheckNote: 'RDAP status is a preliminary registry signal, not a registrar checkout or price quote.',
        checkedAt: now.toISOString(),
      };
    }));
    rows.push(...results);
  }
  rows.sort((a, b) => (b.score ?? -1) - (a.score ?? -1));
  return {
    generatedAt: now.toISOString(),
    window: 'Last 7 complete UTC days vs preceding 7 complete UTC days',
    sourcePolicy: 'Free public search endpoints; partial failures are labelled unverified. Trend mentions are a signal, not a forecast.',
    ideas: rows,
  };
}

exports.getNovaSignalOpportunities = onCall(
  {region: REGION, timeoutSeconds: 120, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in to view NOVA signal opportunities.');
    const snap = await db.collection(SIGNALS_COLLECTION).doc(LATEST_DOC).get();
    const cached = snap.data();
    if (cached?.generatedAt && Date.now() - Date.parse(cached.generatedAt) < 20 * 60 * 60 * 1000) {
      return {...cached, cached: true};
    }
    try {
      const result = await scanSignals();
      await db.collection(SIGNALS_COLLECTION).doc(LATEST_DOC).set({
        ...result,
        updatedAt: FieldValue.serverTimestamp(),
      });
      return {...result, cached: false};
    } catch (error) {
      throw new HttpsError('unavailable', 'Signal scan unavailable: ' + String(error?.message || error).slice(0, 180));
    }
  },
);

exports.runNovaSignalOpportunitiesDaily = onSchedule(
  {schedule: 'every day 09:15', timeZone: 'Africa/Khartoum', region: REGION, timeoutSeconds: 240, memory: '512MiB', maxInstances: 1},
  async () => {
    const result = await scanSignals();
    await db.collection(SIGNALS_COLLECTION).doc(LATEST_DOC).set({
      ...result,
      updatedAt: FieldValue.serverTimestamp(),
    });
  },
);

exports.scanNovaSignalOpportunitiesForTest = scanSignals;
exports.novaSignalThemesForTest = SIGNAL_THEMES;
