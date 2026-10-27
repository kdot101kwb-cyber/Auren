'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  AGENT_PROJECTS,
  GROK_INTEGRATIONS,
  DEPARTMENT_AGENT_MAP,
  getDepartmentAgentPlan,
  getAllDepartmentAgentPlans,
  buildDepartmentAgentAssignment,
} = require('./nova_agent_catalog');
const {DEPARTMENTS} = require('./nova_department_registry');

test('every NOVA department has at least two known open-source agent/framework candidates', () => {
  assert.deepEqual(Object.keys(DEPARTMENT_AGENT_MAP).sort(), DEPARTMENTS.map((d) => d.id).sort());
  for (const department of DEPARTMENTS) {
    const plan = getDepartmentAgentPlan(department.id);
    assert.ok(plan.primaryAgents.length >= 2, department.id);
    assert.ok(plan.primaryAgents.every((agent) => AGENT_PROJECTS[agent.id]), department.id);
    assert.ok(plan.primaryAgents.every((agent) => agent.repository.startsWith('https://github.com/')), department.id);
    assert.equal(plan.runtimeReady, false);
    assert.equal(plan.mayExecuteExternalAction, false);
  }
});

test('catalog makes zero-cost boundaries clear without claiming runtime is free', () => {
  for (const project of Object.values(AGENT_PROJECTS)) {
    assert.ok(project.license);
    assert.ok(project.costNote.includes('may cost money'));
  }
});

test('Grok integration candidates have verified source metadata but remain disconnected and cost-gated', () => {
  assert.deepEqual(Object.keys(GROK_INTEGRATIONS).sort(), ['grok_build','grok_cli','xai_sdk_ts']);
  for (const integration of Object.values(GROK_INTEGRATIONS)) {
    const url = new URL(integration.repository);
    assert.equal(url.protocol, 'https:');
    assert.equal(url.hostname, 'github.com');
    assert.ok(integration.license);
    assert.equal(integration.integrationStatus, 'catalogued_not_connected');
    assert.equal(integration.runtimeReady, false);
    assert.equal(integration.mobileEmbedded, false);
    assert.equal(integration.requiresExplicitOwnerCostApproval, true);
    assert.equal(integration.mayIncurCosts, true);
  }
  assert.equal(GROK_INTEGRATIONS.xai_sdk_ts.requiresServerSideSecret, true);
  assert.equal(GROK_INTEGRATIONS.xai_sdk_ts.experimental, true);
  assert.equal(GROK_INTEGRATIONS.grok_build.license, 'Apache-2.0');
  assert.equal(GROK_INTEGRATIONS.grok_cli.license, 'MIT');
});

test('engineering and AUREN plans include Grok Build only as a candidate, not a live runtime', () => {
  for (const departmentId of ['engineering','auren']) {
    const plan = getDepartmentAgentPlan(departmentId);
    assert.ok(plan.primaryAgents.some((agent) => agent.id === 'grok_build'));
    assert.equal(plan.runtimeReady, false);
    assert.equal(plan.mayExecuteExternalAction, false);
  }
});

test('unknown departments and blank objectives fail closed', () => {
  assert.throws(() => getDepartmentAgentPlan('not-a-department'), /Unknown departmentId/);
  assert.throws(() => buildDepartmentAgentAssignment({departmentId:'research', objective:' '}), /objective/);
});

test('assignment includes agent links but does not claim that agents are connected or running', () => {
  const assignment = buildDepartmentAgentAssignment({
    departmentId:'research',
    objective:'Compare free AI video tools',
    taskType:'research',
  });
  assert.equal(assignment.integrationStatus, 'catalogued_not_connected');
  assert.equal(assignment.runtimeReady, false);
  assert.equal(assignment.mayExecuteExternalAction, false);
  assert.ok(assignment.agents.length >= 2);
  assert.match(assignment.nextStep, /tested worker adapter/);
});

test('external-action tasks always pause for owner approval and cannot execute', () => {
  for (const taskType of ['social_publish','send_email','spend_money','investment_execution','deploy_production','delete_data']) {
    const assignment = buildDepartmentAgentAssignment({
      departmentId:'operations',
      objective:'Prepare a safe plan',
      taskType,
    });
    assert.equal(assignment.approvalRequired, true, taskType);
    assert.equal(assignment.mayExecuteExternalAction, false, taskType);
  }
});

test('all 11 department plans can be generated and include integration prerequisites', () => {
  const plans = getAllDepartmentAgentPlans();
  assert.equal(plans.length, 11);
  assert.ok(plans.every((plan) => plan.requiredBeforeLiveUse.length >= 4));
});
