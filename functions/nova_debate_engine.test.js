'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  normalizeDebateInput, buildDebateMessages, normalizeDebateResult, parseModelJson,
} = require('./nova_debate_engine');

test('requires a non-empty bounded prompt and fixes the approved policy', () => {
  assert.throws(() => normalizeDebateInput({prompt:'  '}), /اكتب القرار/);
  assert.throws(() => normalizeDebateInput({prompt:'x'.repeat(5001)}), /الحد المسموح/);
  const input = normalizeDebateInput({prompt:'راجع الخطة', strategy:'agreeable', executionPolicy:'auto', boardEnabled:false});
  assert.equal(input.strategy, 'strategic');
  assert.equal(input.boardEnabled, true);
  assert.equal(input.executionPolicy, 'approved');
  assert.equal(input.roles.length, 4);
});

test('validates and carries an optional project reference into the council prompt', () => {
  const input = normalizeDebateInput({prompt:'راجع المشروع',projectId:'project_123456'});
  assert.equal(input.projectId,'project_123456');
  assert.throws(() => normalizeDebateInput({prompt:'راجع المشروع',projectId:'../other'}), /معرّف المشروع/);
  const messages = buildDebateMessages({prompt:'راجع المشروع',projectId:'project_123456'});
  assert.match(messages[1].content, /project_123456/);
});

test('bounds context and builds an evidence-led multidisciplinary prompt', () => {
  const messages = buildDebateMessages({prompt:'أريد إطلاق ميزة', context:'x'.repeat(14000)});
  assert.equal(messages.length, 2);
  assert.match(messages[0].content, /Do not agree automatically/);
  assert.match(messages[0].content, /four distinct roles/);
  assert.match(messages[1].content, /mustWaitForAgreement/);
  assert.ok(messages[1].content.length < 14000);
});

test('normalizes model response and forces explicit agreement gate', () => {
  const result = normalizeDebateResult({
    recommendation:'support', confidence:9, agreementRequired:false,
    executionGate:'approved', safeFixesAfterAgreement:false,
    sensitiveActionsRequireApproval:false,
    plan:[{step:'اختبار',verification:'نتيجة ناجحة'}],
  });
  assert.equal(result.recommendation, 'support');
  assert.equal(result.confidence, 1);
  assert.equal(result.executionGate, 'awaiting_user_agreement');
  assert.equal(result.agreementRequired, true);
  assert.equal(result.safeFixesAfterAgreement, true);
  assert.equal(result.sensitiveActionsRequireApproval, true);
  assert.equal(result.plan.length, 1);
});

test('caps untrusted model-generated lists and normalizes unknown severity', () => {
  const result = normalizeDebateResult({
    recommendation:'invented',
    objections:Array.from({length:9}, (_, i) => ({title:String(i),severity:'extreme'})),
    plan:Array.from({length:20}, (_, i) => ({step:'step '+i})),
    risks:Array.from({length:20}, (_, i) => ({risk:'risk '+i})),
  });
  assert.equal(result.recommendation, 'revise');
  assert.equal(result.objections.length, 5);
  assert.equal(result.objections[0].severity, 'medium');
  assert.equal(result.plan.length, 12);
  assert.equal(result.risks.length, 6);
});

test('parses plain and fenced JSON and rejects malformed model output', () => {
  assert.equal(parseModelJson('{"summary":"ok","recommendation":"support"}').summary, 'ok');
  assert.equal(parseModelJson('```json\n{"summary":"ok"}\n```').summary, 'ok');
  assert.throws(() => parseModelJson('no structured result'), /JSON صالح/);
  assert.throws(() => parseModelJson('{"summary": }'), SyntaxError);
});
