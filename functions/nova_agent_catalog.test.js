'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  AGENT_PROJECTS,
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
