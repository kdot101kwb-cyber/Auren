const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const moduleSource = fs.readFileSync(path.join(__dirname, 'personal_ai_life_engine.js'), 'utf8');
const rulesSource = fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8');

test('Personal AI / Life Engine exposes the core goal, plan, and memory actions', () => {
  for (const name of [
    'createAurenGoal',
    'updateAurenGoalProgress',
    'createAurenDailyPlan',
    'saveAurenMemory',
  ]) assert.match(moduleSource, new RegExp('exports\\.' + name + '\\s*=\\s*onCall'));
});

test('Personal AI / Life Engine validates ownership at the callable boundary', () => {
  assert.match(moduleSource, /request\.auth\?\.uid/);
  assert.match(moduleSource, /users'\)\.doc\(uid\)/);
});

test('Personal AI / Life Engine has client security rules for goals, plans, and memories', () => {
  for (const collection of ['goals', 'dailyPlans', 'memories']) {
    assert.match(rulesSource, new RegExp('match \\/users\\/\\{userId\\}\\/' + collection));
  }
});
