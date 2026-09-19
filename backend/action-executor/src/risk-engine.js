import { FieldValue } from 'firebase-admin/firestore';

export const RISK_STATES = Object.freeze(['normal', 'watch', 'restricted', 'suspended']);

function metric(value, fallback) {
  if (value === undefined || value === null) return fallback;
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0) {
    throw Object.assign(new Error('Invalid trust metrics.'), { code: 409 });
  }
  return number;
}

export function calculateRisk(trust) {
  const disputes = metric(trust?.disputes, 0);
  const failures = metric(trust?.failures, 0);
  const score = metric(trust?.score, 100);
  const severe = disputes >= 5 || failures >= 5;
  const restricted = disputes >= 3 || failures >= 3 || score < 20;
  const watch = disputes >= 1 || failures >= 1 || score < 50;
  return severe ? 'suspended' : restricted ? 'restricted' : watch ? 'watch' : 'normal';
}

export async function applyRiskPolicy(db, agentId, uid, trust) {
  const state = calculateRisk(trust);
  const score = metric(trust?.score, 100);
  const disputes = metric(trust?.disputes, 0);
  const failures = metric(trust?.failures, 0);
  const ref = db.collection('agent_risk').doc(agentId);
  await ref.set({
    agentId,
    uid,
    state,
    score,
    disputes,
    failures,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  if (state === 'suspended') {
    await db.collection('users').doc(uid).collection('agents').doc('primary').set({
      status: 'paused',
      riskSuspended: true,
      riskReason: 'Automated risk policy',
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  return state;
}

export function assertOperationalRisk(risk) {
  if (risk?.state === 'suspended') {
    throw Object.assign(new Error('Agent is suspended by the risk policy.'), { code: 403 });
  }
  if (risk?.state === 'restricted') {
    throw Object.assign(new Error('Agent is temporarily restricted by the risk policy.'), { code: 403 });
  }
}