'use strict';
const {createHash} = require('node:crypto');
const MIN_SCORE = 68;
const MAX_AGE_DAYS = 14;
function scoreOpportunitySignal(signal, nowMs = Date.now()) {
  const keys=['demand','trend','monetization','evidenceStrength','competition','executionCost'];
  const v={};
  for(const key of keys){v[key]=Number(signal[key]);if(!Number.isFinite(v[key])||v[key]<0||v[key]>100)throw new TypeError(key+' must be 0..100');}
  const trust=Number(signal.sourceTrust??0);if(!Number.isFinite(trust)||trust<0||trust>100)throw new TypeError('sourceTrust must be 0..100');
  const observed=Date.parse(signal.observedAt||'');if(!Number.isFinite(observed))throw new TypeError('observedAt must be an ISO date');
  const ageDays=Math.max(0,(nowMs-observed)/86400000);const freshness=Math.max(0,100-ageDays*100/MAX_AGE_DAYS);
  const raw=v.demand*.22+v.trend*.18+v.monetization*.20+v.evidenceStrength*.18+trust*.10+(100-v.competition)*.06+(100-v.executionCost)*.06;
  const score=Math.round(raw*(.65+freshness/100*.35)*10)/10;
  return {score,freshness:Math.round(freshness),ageDays:Math.round(ageDays*10)/10,eligible:ageDays<=MAX_AGE_DAYS&&v.evidenceStrength>=45&&trust>=40&&score>=MIN_SCORE};
}
function alertDocumentId(uid,signalId){return createHash('sha256').update(uid+'|'+signalId).digest('hex').slice(0,40);}
module.exports={scoreOpportunitySignal,alertDocumentId,MIN_SCORE,MAX_AGE_DAYS};
