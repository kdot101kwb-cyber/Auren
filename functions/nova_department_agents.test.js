'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {DEPARTMENTS} = require('./nova_department_registry');
const {AGENT_CATALOG, DEPARTMENT_AGENT_BINDINGS, getDepartmentAgentPlan, buildDepartmentAgentDispatch} = require('./nova_department_agents');

test('every NOVA department has a valid open-source agent mapping', () => {
  assert.equal(Object.keys(DEPARTMENT_AGENT_BINDINGS).length, DEPARTMENTS.length);
  for (const department of DEPARTMENTS) {
    const plan = getDepartmentAgentPlan(department.id);
    assert.ok(AGENT_CATALOG[plan.primaryAgent.id]);
    assert.ok(plan.supportingAgents.length >= 1);
    assert.ok(plan.specialistProfiles.length >= 1);
    assert.equal(plan.integrationStatus, 'catalogued_not_installed');
    assert.equal(plan.mayExecuteExternalAction, false);
  }
});

test('catalog entries have upstream repository and license metadata', () => {
  for (const agent of Object.values(AGENT_CATALOG)) {
    assert.match(agent.repository, /^https:\/\/github\.com\//);
    assert.ok(agent.license);
    assert.ok(agent.role);
  }
});

test('department dispatch plan selects the assigned primary agent without executing work', () => {
  const dispatch = buildDepartmentAgentDispatch({
    departmentId:'engineering',
    taskType:'github_ci_check',
    objective:'Inspect NOVA test failures',
  });
  assert.equal(dispatch.primaryAgentId, 'openhands');
  assert.ok(dispatch.supportingAgentIds.includes('swe_agent'));
  assert.equal(dispatch.requiresSandboxForCodeExecution, true);
  assert.equal(dispatch.status, 'planned_not_executed');
  assert.equal(dispatch.externalActionExecuted, false);
});

test('dispatch requires a valid department, task type, and objective', () => {
  assert.throws(() => getDepartmentAgentPlan('unknown'), /Unknown department/);
  assert.throws(() => buildDepartmentAgentDispatch({departmentId:'research', taskType:'', objective:'Find trends'}), /taskType/);
  assert.throws(() => buildDepartmentAgentDispatch({departmentId:'research', taskType:'research', objective:' '}), /objective/);
});
