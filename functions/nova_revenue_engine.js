'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const db = getFirestore();
const OPENROUTER_API_KEY = defineSecret('OPENROUTER_API_KEY');
const REGION = 'us-central1';
const SETTINGS_COLLECTION = 'nova_revenue_settings';
const RUNS_COLLECTION = 'nova_revenue_runs';

function normalizePreferences(data = {}) {
  const skills = String(data.skills || 'AI content writing, short-form video scripts, SEO').trim().slice(0, 500);
  const languages = String(data.languages || 'Arabic and English').trim().slice(0, 120);
  const hoursPerDay = Number(data.hoursPerDay || 3);
  if (!Number.isFinite(hoursPerDay) || hoursPerDay < 1 || hoursPerDay > 12) {
    throw new Error('hoursPerDay must be between 1 and 12.');
  }
  const startingBudgetUsd = Number(data.startingBudgetUsd || 0);
  if (!Number.isFinite(startingBudgetUsd) || startingBudgetUsd < 0 || startingBudgetUsd > 100) {
    throw new Error('startingBudgetUsd must be between $0 and $100.');
  }
  return {skills, languages, hoursPerDay, startingBudgetUsd};
}

function utcDateKey(now = new Date()) {
  return now.toISOString().slice(0, 10);
}

function buildRevenuePrompt(preferences, dateKey) {
  return [
    'You are NOVA AI, a cautious freelance revenue operations assistant. Prepare a practical daily work pack, not a promise of earnings.',
    'Return concise Markdown in Arabic. Do not claim that accounts were created, jobs applied to, clients contacted, files published, or money earned.',
    'Prioritize zero-upfront-cost services that can be sold with existing AI tools and a phone. Avoid scams, fake reviews, spam, plagiarism, copyrighted imitation, fabricated credentials, and guaranteed-income claims.',
    'Make platform payout eligibility and identity/payment verification a user-check item; do not assume any marketplace is available in the user’s country.',
    'Target aspiration: work toward $100/day, but label it a goal rather than forecast. Include transparent example pricing and arithmetic, and state that customer acquisition is uncertain.',
    'Produce these headings exactly: ## Today\'s focus, ## Three sellable services, ## Portfolio sample to create, ## Client outreach draft, ## Social content pack, ## Airdrop watch, ## 3-hour execution plan, ## Revenue math (not a forecast), ## Risks and next checks.',
    'Under Social content pack, prepare one original daily post/caption and short-video script each for YouTube Shorts, Instagram Reels, TikTok, and X, with hook, CTA, suggested visual, and hashtags. These are drafts only; never claim to publish or schedule them. Respect platform policies, copyright, and anti-spam rules.',
    'Under Airdrop watch, list only opportunities that can be supported by current official project announcements or official campaign pages. Include project, official source URL, campaign status/deadline if verified, eligibility/tasks, network, whether a fee is required, and a confidence label. If current sources cannot be verified, say so and provide a research checklist rather than inventing campaigns. Never promise token value or eligibility. Never ask for seed phrases/private keys, never sign transactions, connect wallets, pay gas/fees, or claim tokens automatically. Explain that actual receipt requires the user to claim through the verified official site and wallet support; this engine cannot transfer tokens into the wallet by itself.'
    'Under Ten income paths ranked, rank 10 distinct options by zero-cost start, likely time to first customer, skill fit, platform/payment availability checks, repeatability, and evidence needed. Include freelance copywriting, CV/LinkedIn help, short-video scripts, SEO briefs, social media packs, digital templates, translation/localization, virtual assistance, lead research, and short-form video production/repurposing. Do not imply all platforms or payouts work in every country. Under Three sellable services, choose the best three of those 10 and give scope, turnaround, illustrative price and deliverables.',
    'Outreach draft must be personalized with placeholders and must not be sent automatically. No bulk outreach.',
    'Do not recommend buying ads, subscriptions, or credits. Start with $0 tools; any unavoidable fee must be disclosed before use.',
    'Date (UTC): ' + dateKey,
    'Skills: ' + preferences.skills,
    'Languages: ' + preferences.languages,
    'Available hours/day: ' + preferences.hoursPerDay,
    'Starting budget USD: ' + preferences.startingBudgetUsd,
  ].join('\n');
}

async function generateDailyPack(uid, preferences, dateKey) {
  const settingsRef = db.collection('users').doc(uid).collection(SETTINGS_COLLECTION).doc('config');
  const runRef = db.collection('users').doc(uid).collection(RUNS_COLLECTION).doc(dateKey);
  const claim = await db.runTransaction(async (tx) => {
    const settingsSnap = await tx.get(settingsRef);
    if (!settingsSnap.exists || settingsSnap.data()?.enabled !== true) return {skip: 'disabled'};
    const prior = await tx.get(runRef);
    if (prior.exists && ['running', 'succeeded'].includes(String(prior.data()?.status || ''))) return {skip: 'already_started'};
    tx.set(runRef, {
      dateKey, status: 'running', provider: 'openrouter/free',
      startedAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return {skip: null, preferences: settingsSnap.data()?.preferences || {}};
  });
  if (claim.skip) return {status: claim.skip};
  try {
    const key = OPENROUTER_API_KEY.value().trim();
    if (!key) throw new Error('OPENROUTER_API_KEY is not configured in Firebase Secret Manager.');
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: 'Bearer ' + key,
        'HTTP-Referer': 'https://auren.app',
        'X-Title': 'NOVA AI Revenue Engine',
      },
      body: JSON.stringify({
        model: 'openrouter/free',
        temperature: 0.35,
        messages: [
          {role: 'system', content: 'You create ethical, realistic revenue work packs. Never imply guaranteed earnings or that external actions have been executed.'},
          {role: 'user', content: buildRevenuePrompt(claim.preferences, dateKey)},
        ],
      }),
      signal: AbortSignal.timeout(45000),
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(String(payload?.error?.message || 'OpenRouter HTTP ' + response.status).slice(0, 350));
    const markdown = payload?.choices?.[0]?.message?.content;
    if (typeof markdown !== 'string' || markdown.trim().length < 100) throw new Error('AI provider returned an incomplete work pack.');
    await runRef.set({
      status: 'succeeded',
      report: markdown.trim().slice(0, 24000),
      model: String(payload?.model || 'openrouter/free').slice(0, 160),
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      disclaimer: 'Suggestions and drafts only. No account creation, applications, outreach, publishing, or payments were performed.',
    }, {merge: true});
    return {status: 'succeeded', dateKey, report: markdown.trim(), model: payload?.model || 'openrouter/free'};
  } catch (error) {
    const message = String(error?.message || error).slice(0, 350);
    await runRef.set({status: 'failed', error: message, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
    throw error;
  }
}

exports.configureNovaRevenueEngine = onCall(
  {region: REGION, timeoutSeconds: 55, memory: '256MiB', enforceAppCheck: true, consumeAppCheckToken: true, secrets: [OPENROUTER_API_KEY]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to configure the NOVA revenue engine.');
    let preferences;
    try { preferences = normalizePreferences(request.data || {}); }
    catch (error) { throw new HttpsError('invalid-argument', error.message); }
    const enabled = request.data?.enabled === true;
    const ref = db.collection('users').doc(uid).collection(SETTINGS_COLLECTION).doc('config');
    await ref.set({
      enabled, preferences,
      configuredBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
      ...(enabled ? {enabledAt: FieldValue.serverTimestamp()} : {disabledAt: FieldValue.serverTimestamp()}),
    }, {merge: true});
    if (!enabled) return {ok: true, enabled: false, message: 'Background revenue engine paused.'};
    try {
      const dateKey = utcDateKey();
      const result = await generateDailyPack(uid, preferences, dateKey);
      return {ok: true, enabled: true, ...result, message: result.status === 'succeeded'
        ? 'Today’s revenue work pack is ready. It contains drafts and tasks only; nothing was sent or published.'
        : 'Background engine enabled. Today’s pack already exists or is being generated.'};
    } catch (error) {
      throw new HttpsError('unavailable', String(error?.message || error).slice(0, 350));
    }
  },
);

exports.getNovaRevenueDashboard = onCall(
  {region: REGION, timeoutSeconds: 15, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'Sign in to view your NOVA revenue work pack.');
    const settingsRef = db.collection('users').doc(uid).collection(SETTINGS_COLLECTION).doc('config');
    const settings = await settingsRef.get();
    const dateKey = utcDateKey();
    const run = await db.collection('users').doc(uid).collection(RUNS_COLLECTION).doc(dateKey).get();
    const row = run.data() || {};
    return {
      enabled: settings.exists && settings.data()?.enabled === true,
      preferences: settings.data()?.preferences || null,
      dateKey,
      status: row.status || 'not_generated',
      report: row.report || null,
      error: row.error || null,
      disclaimer: 'Drafts only: NOVA has not applied to jobs, contacted clients, published content, opened accounts, or received money.',
    };
  },
);

exports.runNovaRevenueEngineDaily = onSchedule(
  {schedule: 'every day 09:00', region: REGION, timeoutSeconds: 300, memory: '512MiB', maxInstances: 1, secrets: [OPENROUTER_API_KEY]},
  async () => {
    const dateKey = utcDateKey();
    const enabledSettings = await db.collectionGroup(SETTINGS_COLLECTION).where('enabled', '==', true).limit(100).get();
    for (const settingDoc of enabledSettings.docs) {
      const uid = settingDoc.ref.parent.parent?.id;
      if (!uid || settingDoc.id !== 'config') continue;
      try {
        await generateDailyPack(uid, settingDoc.data()?.preferences || {}, dateKey);
      } catch (error) {
        console.error('NOVA revenue pack failed for user', uid, String(error?.message || error).slice(0, 250));
      }
    }
  },
);

exports.normalizeNovaRevenuePreferences = normalizePreferences;
exports.novaRevenueUtcDateKey = utcDateKey;
exports.buildNovaRevenuePrompt = buildRevenuePrompt;
