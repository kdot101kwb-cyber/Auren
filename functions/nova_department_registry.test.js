'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {DEPARTMENTS, getDepartment, routeNovaTask, createDepartmentAuditEvent} = require('./nova_department_registry');

test('department registry has unique IDs and specialist teams', () => {
  assert.equal(new Set(DEPARTMENTS.map((d) => d.id)).size, DEPARTMENTS.length);
  for (const department of DEPARTMENTS) {
    assert.ok(department.head);
    assert.ok(department.specialists.length > 0);
    assert.ok(department.capabilities.length > 0);
    assert.ok(department.dataScope);
  }
});
test('executive coordinator reports directly to the owner', () => {
  const route = routeNovaTask({type:'plan'});
  assert.equal(route.coordinator, 'NOVA Chief Executive AI');
  assert.equal(route.accountableTo, 'user');
  assert.equal(route.departmentId, 'executive');
});
test('tasks route to domain-specific heads and specialists', () => {
  assert.equal(routeNovaTask({type:'github_ci_check'}).departmentId, 'engineering');
  assert.equal(routeNovaTask({type:'finance_report'}).departmentId, 'finance');
  assert.equal(routeNovaTask({type:'research'}).departmentId, 'research');
});
test('external side effects always require approval and are never executed by router', () => {
  for (const type of ['social_publish','send_email','spend_money','deploy_production','delete_data','investment_execution']) {
    const route = routeNovaTask({type, externalSideEffect:true});
    assert.equal(route.approvalRequired, true);
    assert.equal(route.mayExecuteExternalAction, false);
  }
});
test('unknown task routes fail closed', () => {
  assert.throws(() => routeNovaTask({type:'run_anything'}), /No approved department route/);
  assert.equal(getDepartment('not-a-department'), null);
});
test('audit event is minimal and excludes prompt and secret fields', () => {
  const event = createDepartmentAuditEvent({ownerUid:'owner-1', taskId:'task-1', departmentId:'security', action:'review', outcome:'blocked'});
  assert.equal(event.containsPrompt, false);
  assert.equal(event.containsSecrets, false);
  assert.equal('prompt' in event, false);
  assert.equal('secret' in event, false);
  assert.throws(() => createDepartmentAuditEvent({ownerUid:'owner-1', taskId:'task-1', departmentId:'bad', action:'review', outcome:'blocked'}), /required/);
});
