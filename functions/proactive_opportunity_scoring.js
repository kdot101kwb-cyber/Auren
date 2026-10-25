'use strict';
const {createHash} = require('node:crypto');

const MIN_SCORE = 68;
const MAX_AGE_DAYS = 14;

/**
 * Score an ingested opportunity using bounded, source-attributed signals.
 * Inputs are deliberately validated instead of silently guessed.
 */
function scoreOpportunitySignal(signal, nowMs = Date.now()) {
  const keys = ['demand', 'trend', 'monetization', 'evidenceStrength', 'competition', 'executionCost'];
  const values = {};
  for (const key of keys) {
    values[key] = Number(signal[key]);
    if (!Number.isFinite(values[key]) || values[key] < 0 || values[key] > 100) {
      throw new TypeError(key + ' must be 0..100');
    }
  }
  const trust = Number(signal.sourceTrust ?? 0);
  if (!Number.isFinite(trust) || trust < 0 || trust > 100) {
    throw new TypeError('sourceTrust must be 0..100');
  }
  const observed = Date.parse(signal.observedAt || '');
  if (!Number.isFinite(observed)) throw new TypeError('observedAt must be an ISO date');

  const ageDays = Math.max(0, (nowMs - observed) / 86400000);
  const freshness = Math.max(0, 100 - ageDays * 100 / MAX_AGE_DAYS);
  const raw = values.demand * 0.22 + values.trend * 0.18 +
    values.monetization * 0.20 + values.evidenceStrength * 0.18 +
    trust * 0.10 + (100 - values.competition) * 0.06 +
    (100 - values.executionCost) * 0.06;
  const score = Math.round(raw * (0.65 + freshness / 100 * 0.35) * 10) / 10;

  return {
    score,
    freshness: Math.round(freshness),
    ageDays: Math.round(ageDays * 10) / 10,
    eligible: ageDays <= MAX_AGE_DAYS && values.evidenceStrength >= 45 &&
      trust >= 40 && score >= MIN_SCORE,
  };
}

function alertDocumentId(uid, signalId) {
  return createHash('sha256').update(uid + '|' + signalId).digest('hex').slice(0, 40);
}

module.exports = {scoreOpportunitySignal, alertDocumentId, MIN_SCORE, MAX_AGE_DAYS};
