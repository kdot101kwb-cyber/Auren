'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {buildDepartmentBrief, buildExecutiveRollup} = require('./nova_department_reporting');
const {DEPARTMENTS} = require('./nova_department_registry');

test('each department can introduce itself with mission and actionable plan', () => {
  for (const department of DEPARTMENTS) {
    const report = buildDepartmentBrief({departmentId:department.id, objective:'Improve NOVA reliability'});
    assert.match(report.introduction, /أنا/);
    assert.ok(report.mission.length > 10);
    assert.ok(report.plan.length >= 3);
    assert.equal(report.accountableTo, 'user');
  }
});

test('does not mark completed without evidence', () => {
  const report = buildDepartmentBrief({departmentId:'engineering', objective:'Build Android app', status:'completed'});
  assert.equal(report.status, 'in_progress');
  assert.match(report.statusNote, /غياب دليل/);
});

test('external actions require approval and router never executes them', () => {
  const report = buildDepartmentBrief({departmentId:'operations', objective:'Send an email', taskType:'send_email', externalSideEffect:true});
  assert.equal(report.approvalRequired, true);
  assert.equal(report.mayExecuteExternalAction, false);
});

test('executive rollup exposes missing reports, blockers, and decisions', () => {
  const blocked = buildDepartmentBrief({departmentId:'security', objective:'Review access controls', status:'blocked', blockers:['Need approved test scope']});
  const approval = buildDepartmentBrief({departmentId:'operations', objective:'Prepare an email', taskType:'send_email', proposedActions:['Draft message']});
  const rollup = buildExecutiveRollup({objective:'Prepare NOVA department review', briefs:[blocked, approval]});
  assert.equal(rollup.reportCount, 2);
  assert.ok(rollup.departmentsMissing.includes('engineering'));
  assert.equal(rollup.blockedDepartments.length, 1);
  assert.equal(rollup.ownerDecisionsRequired.length, 1);
  assert.equal(rollup.externalActionsExecuted, false);
});

test('rejects unknown departments, empty objectives, and unknown status', () => {
  assert.throws(() => buildDepartmentBrief({departmentId:'unknown', objective:'x'}), /Unknown department/);
  assert.throws(() => buildDepartmentBrief({departmentId:'security', objective:' '}), /objective/);
  assert.throws(() => buildDepartmentBrief({departmentId:'security', objective:'x', status:'magically_done'}), /Unsupported/);
});
