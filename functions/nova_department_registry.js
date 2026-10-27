'use strict';

// NOVA departmental routing registry. This is deterministic orchestration metadata;
// it does not create live model agents or execute external actions by itself.
const DEPARTMENTS = Object.freeze([
  {id:'executive', head:'NOVA Chief Executive AI', specialists:['strategy_planner','chief_of_staff'], capabilities:['plan','research','opportunity_scan','finance_report','integration_health','github_ci_check'], dataScope:'owner_workspace', risk:'low'},
  {id:'security', head:'AI Chief Security Officer', specialists:['application_security','firebase_security','privacy','incident_response','independent_security_reviewer'], capabilities:['security_review','github_ci_check','integration_health'], dataScope:'security_metadata', risk:'high'},
  {id:'engineering', head:'AI Chief Technology Officer', specialists:['flutter_engineer','backend_engineer','firebase_engineer','automation_engineer'], capabilities:['github_ci_check','integration_health','plan'], dataScope:'approved_project_files', risk:'medium'},
  {id:'quality', head:'AI Quality Director', specialists:['test_engineer','release_validator','regression_analyst'], capabilities:['github_ci_check','integration_health','security_review'], dataScope:'test_results', risk:'low'},
  {id:'research', head:'AI Research Director', specialists:['market_researcher','trend_analyst','source_verifier'], capabilities:['research','opportunity_scan'], dataScope:'public_sources', risk:'low'},
  {id:'product', head:'AI Product Director', specialists:['ux_researcher','accessibility_specialist','product_analyst'], capabilities:['plan','research','content_draft'], dataScope:'approved_product_context', risk:'low'},
  {id:'growth', head:'AI Growth Director', specialists:['content_strategist','audience_analyst','distribution_planner'], capabilities:['research','opportunity_scan','content_draft'], dataScope:'public_metrics_and_drafts', risk:'medium'},
  {id:'finance', head:'AI Finance Director', specialists:['revenue_analyst','budget_planner','investment_risk_reviewer'], capabilities:['finance_report','opportunity_scan','plan'], dataScope:'owner_provided_financial_data', risk:'high'},
  {id:'legal', head:'AI Legal & Compliance Director', specialists:['privacy_compliance_reviewer','terms_reviewer','policy_analyst'], capabilities:['research','security_review','plan'], dataScope:'minimum_required_context', risk:'high'},
  {id:'operations', head:'AI Operations Director', specialists:['executive_assistant','communications_drafter','workflow_coordinator'], capabilities:['chat','plan','content_draft'], dataScope:'owner_workspace_minimum', risk:'medium'},
  {id:'auren', head:'AI AUREN Program Director', specialists:['repository_organizer','feature_planner','market_scanner'], capabilities:['github_ci_check','integration_health','research','plan'], dataScope:'approved_auren_project_files', risk:'medium'},
]);
const TASK_ROUTES = Object.freeze({
  chat:'operations', plan:'executive', research:'research', opportunity_scan:'research',
  content_draft:'growth', social_content_draft:'growth', image_generation:'product',
  video_generation:'growth', social_publish:'growth', github_ci_check:'engineering',
  integration_health:'quality', finance_report:'finance', security_review:'security',
  send_email:'operations', send_message:'operations', spend_money:'finance',
  investment_execution:'finance', deploy_production:'engineering',
  delete_data:'security', change_permissions:'security',
});
const HIGH_RISK_TYPES = new Set(['image_generation','video_generation','social_publish','send_email','send_message','spend_money','change_permissions','deploy_production','delete_data','investment_execution']);
const EXTERNAL_SIDE_EFFECTS = new Set(['social_publish','send_email','send_message','spend_money','change_permissions','deploy_production','delete_data','investment_execution']);

function getDepartment(id) {
  return DEPARTMENTS.find((department) => department.id === id) || null;
}
function routeNovaTask(task) {
  if (!task || typeof task !== 'object' || Array.isArray(task)) throw new TypeError('Task must be an object.');
  const type = String(task.type || '').trim();
  const departmentId = TASK_ROUTES[type];
  if (!departmentId) throw new Error('No approved department route exists for this task type.');
  const department = getDepartment(departmentId);
  const highRisk = HIGH_RISK_TYPES.has(type) || task.externalSideEffect === true;
  const approvalRequired = highRisk || EXTERNAL_SIDE_EFFECTS.has(type) || task.requiresApproval === true;
  return Object.freeze({
    taskType:type,
    coordinator:'NOVA Chief Executive AI',
    accountableTo:'user',
    departmentId:department.id,
    departmentHead:department.head,
    specialists:[...department.specialists],
    risk:highRisk ? 'high' : department.risk,
    approvalRequired,
    mayExecuteExternalAction: false,
    stages:['executive_intake','department_head_review','specialist_analysis','independent_quality_or_security_review','user_report'],
    note:approvalRequired
      ? 'Prepare analysis or a draft only; require explicit owner approval before any external side effect.'
      : 'Routing plan only; a configured model provider and authorized worker are still required.',
  });
}
function createDepartmentAuditEvent({ownerUid, taskId, departmentId, action, outcome, timestamp = new Date().toISOString()}) {
  if (!ownerUid || !taskId || !getDepartment(departmentId) || !action || !outcome) {
    throw new TypeError('ownerUid, taskId, valid departmentId, action, and outcome are required.');
  }
  return Object.freeze({
    ownerUid:String(ownerUid),
    taskId:String(taskId),
    departmentId,
    action:String(action).slice(0,100),
    outcome:String(outcome).slice(0,100),
    timestamp:String(timestamp),
    containsPrompt:false,
    containsSecrets:false,
  });
}
module.exports = {DEPARTMENTS, TASK_ROUTES, HIGH_RISK_TYPES, EXTERNAL_SIDE_EFFECTS, getDepartment, routeNovaTask, createDepartmentAuditEvent};
