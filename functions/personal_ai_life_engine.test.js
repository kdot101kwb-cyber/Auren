const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const moduleSource = fs.readFileSync(path.join(__dirname, 'personal_ai_life_engine.js'), 'utf8');
const rulesSource = fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8');
const planServiceSource = fs.readFileSync(path.join(__dirname, '..', 'lib', 'services', 'personal_ai', 'daily_plan_service.dart'), 'utf8');
const planScreenSource = fs.readFileSync(path.join(__dirname, '..', 'lib', 'features', 'personal_ai', 'presentation', 'daily_plan_screen.dart'), 'utf8');

test('Personal AI / Life Engine exposes complete goal, plan-task, and memory actions', () => {
  for (const name of [
    'createAurenGoal',
    'updateAurenGoalProgress',
    'createAurenDailyPlan',
    'completeAurenDailyPlanTask',
    'saveAurenMemory',
    'setAurenMemoryEnabled',
    'deleteAurenMemory',
  ]) assert.match(moduleSource, new RegExp('exports\\.' + name + '\\s*=\\s*onCall'));
});

test('Personal AI uses the canonical user-owned collections already consumed by Flutter', () => {
  assert.match(moduleSource, /collection\('users'\)\.doc\(uid\)\.collection\('goals'\)/);
  assert.match(moduleSource, /collection\('memory'\)/);
  assert.match(moduleSource, /collection\('daily_plans'\)/);
  assert.doesNotMatch(moduleSource, /collection\('memories'\)/);
  assert.doesNotMatch(moduleSource, /collection\('dailyPlans'\)/);
});

test('Personal AI has authenticated ownership boundaries', () => {
  assert.match(moduleSource, /request\.auth\?\.uid/);
  assert.match(moduleSource, /goalRef\(uid, goalId\)/);
});

test('Personal AI rules protect plan tasks and memory controls', () => {
  assert.match(rulesSource, /match\s*\/daily_plans\/\{planId\}/);
  assert.match(rulesSource, /match\s*\/tasks\/\{taskId\}/);
  assert.match(rulesSource, /match\s*\/memory\/\{memoryId\}/);
  assert.match(rulesSource, /request\.resource\.data\.completed is bool/);
});

test('Daily Plan UI can execute and reflect task completion', () => {
  assert.match(planServiceSource, /setTaskCompleted/);
  assert.match(planServiceSource, /watchTasks/);
  assert.match(planScreenSource, /CheckboxListTile/);
  assert.match(planScreenSource, /تقدم اليوم/);
});
