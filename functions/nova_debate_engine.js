'use strict';

const MAX_PROMPT_LENGTH = 5000;
const MAX_CONTEXT_LENGTH = 12000;
const MAX_PLAN_STEPS = 12;
const ROLES = Object.freeze([
  {id:'engineering', name:'هندسة وتطوير', focus:'التصميم التقني، قابلية الصيانة، والتعقيد'},
  {id:'quality', name:'الجودة والاختبارات', focus:'حالات الفشل، الاختبارات، وقابلية التحقق'},
  {id:'security', name:'الأمان والخصوصية', focus:'الصلاحيات، البيانات، الأسرار، والآثار الجانبية'},
  {id:'cost_performance', name:'التكلفة والأداء', focus:'الوقت، التكلفة، الاعتمادية، واستهلاك الموارد'},
]);

function cleanText(value, max) {
  return String(value ?? '').replace(/\u0000/g, '').trim().slice(0, max);
}

function normalizeDebateInput(data = {}) {
  const prompt = cleanText(data.prompt, MAX_PROMPT_LENGTH);
  if (!prompt) throw new Error('اكتب القرار أو الخطة التي تريد مناقشتها.');
  if (String(data.prompt).length > MAX_PROMPT_LENGTH) throw new Error('النص أطول من الحد المسموح.');
  const context = cleanText(data.context, MAX_CONTEXT_LENGTH);
  return {
    prompt,
    context,
    strategy: 'strategic',
    boardEnabled: true,
    executionPolicy: 'approved',
    roles: ROLES.map((role) => ({...role})),
  };
}

function buildDebateMessages(input) {
  const normalized = normalizeDebateInput(input);
  const system = [
    'You are NOVA AI Strategic Debate, an evidence-led decision review service.',
    'Respond in Arabic unless the user clearly uses another language.',
    'Do not agree automatically and do not oppose for performance. Challenge weak assumptions with reasons and evidence; state uncertainty explicitly.',
    'Balance outcome quality, delivery time, total cost, operational risk, and reversibility.',
    'Simulate a multidisciplinary review using the four distinct roles provided. They are structured perspectives from one model, not independent real agents; never claim separate model calls occurred.',
    'Never claim repository facts, test results, prices, citations, or external checks that were not provided. Separate observed facts, assumptions, and recommendations.',
    'Return only valid JSON with keys: summary (string), recommendation (support|revise|reject), confidence (number 0..1), decisionRationale (string), objections (array of {role,title,reason,severity,mitigation}), alternatives (array of {name,benefit,cost,risk}), plan (array of {step,reason,verification,estimatedEffort}), risks (array of {risk,likelihood,impact,mitigation}), agreementRequired (true), executionGate (must be awaiting_user_agreement), safeFixesAfterAgreement (true), sensitiveActionsRequireApproval (true), missingEvidence (array of strings).',
    'Use no more than 5 objections, 3 alternatives, 12 plan steps, 6 risks, and 8 missing-evidence items. Each plan step must have a concrete verification criterion.',
    'Do not execute tools, claim work was performed, or authorize deployment/deletion/permission changes. The user must explicitly agree to the plan first.',
    'Keep the proposal practical and prioritize the smallest verifiable delivery slice.',
  ].join('\n');
  const user = JSON.stringify({
    request: normalized.prompt,
    context: normalized.context || '(No additional context supplied)',
    strategy: normalized.strategy,
    reviewBoard: normalized.roles,
    decisionPolicy: {
      executionPolicy: normalized.executionPolicy,
      mustWaitForAgreement: true,
      allowSafeFixesAfterAgreement: true,
      requireExplicitApprovalForSensitiveActions: true,
    },
  });
  return [{role:'system', content:system}, {role:'user', content:user}];
}

function normalizeDebateResult(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('استجابة مجلس النقاش ليست كائناً صالحاً.');
  const list = (items, max) => Array.isArray(items) ? items.slice(0, max) : [];
  const str = (v, max = 1600) => cleanText(v, max);
  const recommendation = ['support','revise','reject'].includes(value.recommendation) ? value.recommendation : 'revise';
  const confidence = Number(value.confidence);
  const plan = list(value.plan, MAX_PLAN_STEPS).map((item) => ({
    step:str(item?.step, 500),
    reason:str(item?.reason, 800),
    verification:str(item?.verification, 500),
    estimatedEffort:str(item?.estimatedEffort, 120),
  })).filter((item) => item.step);
  return {
    summary:str(value.summary),
    recommendation,
    confidence:Number.isFinite(confidence) ? Math.max(0, Math.min(1, confidence)) : 0.5,
    decisionRationale:str(value.decisionRationale),
    objections:list(value.objections, 5).map((item) => ({
      role:str(item?.role, 100),
      title:str(item?.title, 180),
      reason:str(item?.reason, 800),
      severity:['low','medium','high','critical'].includes(item?.severity) ? item.severity : 'medium',
      mitigation:str(item?.mitigation, 500),
    })),
    alternatives:list(value.alternatives, 3).map((item) => ({
      name:str(item?.name, 180), benefit:str(item?.benefit, 500),
      cost:str(item?.cost, 300), risk:str(item?.risk, 300),
    })),
    plan,
    risks:list(value.risks, 6).map((item) => ({
      risk:str(item?.risk, 300), likelihood:str(item?.likelihood, 80),
      impact:str(item?.impact, 120), mitigation:str(item?.mitigation, 500),
    })),
    missingEvidence:list(value.missingEvidence, 8).map((item) => str(item, 300)).filter(Boolean),
    agreementRequired:true,
    executionGate:'awaiting_user_agreement',
    safeFixesAfterAgreement:true,
    sensitiveActionsRequireApproval:true,
  };
}

function parseModelJson(text) {
  const raw = cleanText(text, 30000);
  const fenced = raw.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  const candidate = fenced ? fenced[1] : raw;
  const start = candidate.indexOf('{');
  const end = candidate.lastIndexOf('}');
  if (start < 0 || end <= start) throw new Error('تعذر استخراج JSON صالح من نتيجة النقاش.');
  return normalizeDebateResult(JSON.parse(candidate.slice(start, end + 1)));
}

module.exports = {
  MAX_PROMPT_LENGTH,
  MAX_CONTEXT_LENGTH,
  ROLES,
  normalizeDebateInput,
  buildDebateMessages,
  normalizeDebateResult,
  parseModelJson,
};
