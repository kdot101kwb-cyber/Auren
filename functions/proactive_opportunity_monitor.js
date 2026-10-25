'use strict';

const {createHash} = require('node:crypto');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const db = getFirestore();
const MIN_SCORE = 68;
const MAX_AGE_DAYS = 14;

function scoreOpportunitySignal(signal, nowMs = Date.now()) {
  const keys = ['demand','trend','monetization','evidenceStrength','competition','executionCost'];
  const values = {};
  for (const key of keys) {
    values[key] = Number(signal[key]);
    if (!Number.isFinite(values[key]) || values[key] < 0 || values[key] > 100) throw new TypeError(key + ' must be 0..100');
  }
  const trust = Number(signal.sourceTrust ?? 0);
  if (!Number.isFinite(trust) || trust < 0 || trust > 100) throw new TypeError('sourceTrust must be 0..100');
  const observed = Date.parse(signal.observedAt || '');
  if (!Number.isFinite(observed)) throw new TypeError('observedAt must be an ISO date');
  const ageDays = Math.max(0, (nowMs - observed) / 86400000);
  const freshness = Math.max(0, 100 - ageDays * 100 / MAX_AGE_DAYS);
  const raw = values.demand*.22 + values.trend*.18 + values.monetization*.20 + values.evidenceStrength*.18 + trust*.10 + (100-values.competition)*.06 + (100-values.executionCost)*.06;
  const score = Math.round(raw * (0.65 + freshness/100*.35) * 10) / 10;
  return {score, freshness: Math.round(freshness), ageDays: Math.round(ageDays*10)/10, eligible: ageDays <= MAX_AGE_DAYS && values.evidenceStrength >= 45 && trust >= 40 && score >= MIN_SCORE};
}

function alertDocumentId(uid, signalId) { return createHash('sha256').update(uid+'|'+signalId).digest('hex').slice(0,40); }

exports.scoreOpportunitySignal = scoreOpportunitySignal;
exports.alertDocumentId = alertDocumentId;
exports.saveOpportunityMonitorSettings = onCall({region:'us-central1'}, async (request) => {
  if (!request.auth?.uid) throw new HttpsError('unauthenticated','Sign in first.');
  const data = request.data || {};
  const minimumScore = data.minimumScore == null ? MIN_SCORE : Number(data.minimumScore);
  if (!Number.isFinite(minimumScore) || minimumScore < 50 || minimumScore > 95) throw new HttpsError('invalid-argument','minimumScore must be 50..95');
  const normalize = (v, max) => Array.isArray(v) ? [...new Set(v.map(x=>String(x).trim().slice(0,80)).filter(Boolean))].slice(0,max) : [];
  const settings = {enabled:data.enabled === true, minimumScore, topics:normalize(data.topics,20), regions:normalize(data.regions,10), updatedAt:FieldValue.serverTimestamp()};
  await db.collection('users').doc(request.auth.uid).collection('opportunity_monitoring').doc('settings').set(settings,{merge:true});
  return {ok:true, enabled:settings.enabled, minimumScore, topics:settings.topics, regions:settings.regions};
});

// Runs every six hours. Only ingested, source-attributed records are considered;
// this scheduler does not pretend to crawl the web by itself.
exports.scanProactiveOpportunitySignals = onSchedule({schedule:'every 6 hours',timeZone:'Etc/UTC',region:'us-central1',timeoutSeconds:300}, async () => {
  const [settingsSnap, signalsSnap] = await Promise.all([
    db.collectionGroup('opportunity_monitoring').where('enabled','==',true).limit(300).get(),
    db.collection('market_opportunity_signals').where('monitoringEligible','==',true).limit(500).get(),
  ]);
  if (settingsSnap.empty || signalsSnap.empty) return;
  const ranked = [];
  for (const doc of signalsSnap.docs) {
    const signal = {id:doc.id,...doc.data()};
    try { const result = scoreOpportunitySignal(signal); if (result.eligible) ranked.push({signal,result}); } catch (_) {}
  }
  ranked.sort((a,b)=>b.result.score-a.result.score);
  for (const settingsDoc of settingsSnap.docs) {
    const uid = settingsDoc.ref.parent.parent?.id;
    if (!uid) continue;
    const settings = settingsDoc.data() || {};
    const topics = Array.isArray(settings.topics) ? settings.topics : [];
    const regions = Array.isArray(settings.regions) ? settings.regions : [];
    const candidates = ranked.filter(({signal,result}) => result.score >= Number(settings.minimumScore || MIN_SCORE) && (!topics.length || topics.some(x=>String(signal.topic||'').toLowerCase().includes(String(x).toLowerCase()))) && (!regions.length || regions.some(x=>String(signal.region||'').toLowerCase()===String(x).toLowerCase()))).slice(0,5);
    for (const {signal,result} of candidates) {
      const ref = db.collection('users').doc(uid).collection('proactive_opportunities').doc(alertDocumentId(uid,signal.id));
      const old = await ref.get();
      if (old.exists) continue;
      let sourceUrl = '';
      try { const parsed = new URL(String(signal.sourceUrl||'')); if (parsed.protocol === 'https:') sourceUrl=parsed.toString(); } catch (_) {}
      if (!sourceUrl || !String(signal.title||'').trim()) continue;
      await ref.create({title:String(signal.title).slice(0,180),summary:String(signal.summary||'').slice(0,1200),sourceUrl,sourceName:String(signal.sourceName||new URL(sourceUrl).hostname).slice(0,120),score:result.score,freshness:result.freshness,evidenceStrength:Number(signal.evidenceStrength),sourceTrust:Number(signal.sourceTrust),recommendedAction:String(signal.recommendedAction||'تحقق من الطلب بتجربة صغيرة قبل الإنفاق').slice(0,500),status:'new',disclaimer:'فرصة مرشحة وليست دخلًا مضمونًا. تحقق من المصدر والطلب والتكاليف قبل اتخاذ قرار مالي.',sourceSignalId:signal.id,createdAt:FieldValue.serverTimestamp()});
    }
  }
});
