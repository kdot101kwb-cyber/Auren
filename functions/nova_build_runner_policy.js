'use strict';

const STACK_COMMANDS = Object.freeze({
  flutter: Object.freeze([
    Object.freeze({id:'dependencies', executable:'flutter', args:Object.freeze(['pub','get'])}),
    Object.freeze({id:'format_check', executable:'dart', args:Object.freeze(['format','--output=none','--set-exit-if-changed','.'])}),
    Object.freeze({id:'analyze', executable:'flutter', args:Object.freeze(['analyze','--no-fatal-infos'])}),
    Object.freeze({id:'tests', executable:'flutter', args:Object.freeze(['test'])}),
    Object.freeze({id:'debug_apk', executable:'flutter', args:Object.freeze(['build','apk','--debug'])}),
  ]),
});

const REQUIRED_ISOLATION = Object.freeze([
  'ephemeralWorkspace',
  'noRepositoryWriteToken',
  'noProductionSecrets',
  'networkDisabledDuringExecution',
  'resourceLimitsEnforced',
]);

function buildRunnerPlan(stack) {
  const normalized = String(stack || 'auto');
  if (normalized === 'auto') {
    return {
      status:'needs_stack_selection',
      executable:false,
      reason:'Choose a supported stack before an isolated runner can prepare a build.',
      steps:[],
    };
  }
  const steps = STACK_COMMANDS[normalized];
  if (!steps) {
    return {
      status:'unsupported_stack',
      executable:false,
      reason:'No allowlisted build plan exists for this stack.',
      steps:[],
    };
  }
  return {
    status:'waiting_for_isolated_runner',
    executable:false,
    reason:'A plan is prepared, but no runner is authorized or connected. This is not a build result.',
    steps:steps.map(step => ({id:step.id, executable:step.executable, args:[...step.args]})),
    requiredIsolation:[...REQUIRED_ISOLATION],
    requiresUserApprovalBeforeExecution:true,
  };
}

function isRunnerEligible(runner) {
  if (!runner || typeof runner !== 'object') return false;
  if (runner.status !== 'ready' || runner.attested !== true) return false;
  return REQUIRED_ISOLATION.every(key => runner[key] === true);
}

function isApprovalValid(job, approval) {
  if (!job || !approval || typeof approval !== 'object') return false;
  if (!job.ownerUid || approval.approvedBy !== job.ownerUid) return false;
  if (approval.jobId !== job.jobId || approval.approved !== true) return false;
  if (!approval.approvedAt || !Number.isFinite(Date.parse(approval.approvedAt))) return false;
  if (!approval.planHash || approval.planHash !== job.planHash) return false;
  return true;
}

module.exports = {STACK_COMMANDS, REQUIRED_ISOLATION, buildRunnerPlan, isRunnerEligible, isApprovalValid};
