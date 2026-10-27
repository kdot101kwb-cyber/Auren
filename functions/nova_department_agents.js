'use strict';

// Open-source agent integration map for NOVA's existing department router.
// This maps departments to reviewed upstream projects and capability profiles.
// It does not vendor code, install runtimes, call model APIs, or execute tasks.
const AGENT_CATALOG = Object.freeze({
  langgraph: Object.freeze({
    id:'langgraph', name:'LangGraph', repository:'https://github.com/langchain-ai/langgraph',
    license:'MIT', language:'Python and JavaScript/TypeScript',
    role:'Stateful orchestration, checkpoints, and owner-approval pauses',
    integrationMode:'future_shared_orchestrator',
  }),
  crewai: Object.freeze({
    id:'crewai', name:'CrewAI', repository:'https://github.com/crewAIInc/crewAI',
    license:'MIT', language:'Python',
    role:'Role-based specialist collaboration and workflow coordination',
    integrationMode:'optional_python_service',
  }),
  openhands: Object.freeze({
    id:'openhands', name:'OpenHands', repository:'https://github.com/All-Hands-AI/OpenHands',
    license:'MIT', language:'Python',
    role:'Repository-aware engineering agent in an isolated workspace',
    integrationMode:'optional_sandboxed_engineering_worker',
  }),
  swe_agent: Object.freeze({
    id:'swe_agent', name:'SWE-agent', repository:'https://github.com/SWE-agent/SWE-agent',
    license:'MIT', language:'Python',
    role:'Issue-driven code changes with test evidence',
    integrationMode:'optional_sandboxed_engineering_worker',
  }),
  pydantic_ai: Object.freeze({
    id:'pydantic_ai', name:'Pydantic AI', repository:'https://github.com/pydantic/pydantic-ai',
    license:'MIT', language:'Python',
    role:'Typed outputs, structured reports, and validated tool interfaces',
    integrationMode:'optional_typed_agent_service',
  }),
  smolagents: Object.freeze({
    id:'smolagents', name:'smolagents', repository:'https://github.com/huggingface/smolagents',
    license:'Apache-2.0', language:'Python',
    role:'Lightweight research and tool-using agent experiments',
    integrationMode:'optional_sandboxed_research_worker',
  }),
});

const {routeNovaTask} = require('./nova_department_registry');

const DEPARTMENT_AGENT_BINDINGS = Object.freeze({
  executive: Object.freeze({primary:'langgraph', supporting:['crewai','pydantic_ai'], profiles:['chief_of_staff','decision_brief','risk_and_cost_comparison']}),
  security: Object.freeze({primary:'pydantic_ai', supporting:['langgraph'], profiles:['security_triage','privacy_review','independent_control_check']}),
  engineering: Object.freeze({primary:'openhands', supporting:['swe_agent','langgraph'], profiles:['flutter_engineer','firebase_engineer','repository_maintenance']}),
  quality: Object.freeze({primary:'swe_agent', supporting:['pydantic_ai','langgraph'], profiles:['test_planner','regression_review','evidence_validator']}),
  research: Object.freeze({primary:'smolagents', supporting:['langgraph','pydantic_ai'], profiles:['source_researcher','market_scanner','source_verifier']}),
  product: Object.freeze({primary:'crewai', supporting:['langgraph','pydantic_ai'], profiles:['product_discovery','ux_review','accessibility_review']}),
  growth: Object.freeze({primary:'crewai', supporting:['smolagents','pydantic_ai'], profiles:['content_strategy','audience_research','growth_experiment_planner']}),
  finance: Object.freeze({primary:'pydantic_ai', supporting:['langgraph','smolagents'], profiles:['budget_planner','revenue_analyst','investment_risk_reviewer']}),
  legal: Object.freeze({primary:'pydantic_ai', supporting:['langgraph'], profiles:['privacy_compliance_triage','terms_review','jurisdiction_and_uncertainty_check']}),
  operations: Object.freeze({primary:'langgraph', supporting:['crewai','pydantic_ai'], profiles:['task_coordinator','communications_drafter','workflow_follow_up']}),
  auren: Object.freeze({primary:'openhands', supporting:['swe_agent','langgraph','smolagents'], profiles:['repo_organizer','feature_planner','market_scan_and_ci_review']}),
});

function getDepartmentAgentPlan(departmentId) {
  const binding = DEPARTMENT_AGENT_BINDINGS[departmentId];
  if (!binding) throw new TypeError('Unknown departmentId.');
  const projectIds = [binding.primary, ...binding.supporting];
  return Object.freeze({
    schemaVersion:1,
    departmentId,
    primaryAgent:AGENT_CATALOG[binding.primary],
    supportingAgents:binding.supporting.map((id) => AGENT_CATALOG[id]),
    specialistProfiles:[...binding.profiles],
    integrationStatus:'catalogued_not_installed',
    executionStatus:'not_dispatched',
    modelProviderRequired:true,
    mayExecuteExternalAction:false,
    approvalRequiredForExternalEffects:true,
    note:'Repository mapping only. A sandboxed worker, configured model provider, and passing integration tests are required before this profile can run.',
    projectIds,
  });
}

function buildDepartmentAgentDispatch({departmentId, taskType, objective, externalSideEffect = false}) {
  if (typeof taskType !== 'string' || !taskType.trim()) throw new TypeError('taskType is required.');
  if (typeof objective !== 'string' || !objective.trim()) throw new TypeError('objective is required.');
  const route = routeNovaTask({type:taskType, externalSideEffect});
  const selectedDepartment = departmentId || route.departmentId;
  if (route.departmentId !== selectedDepartment) throw new TypeError('Department does not match the approved task route.');
  const plan = getDepartmentAgentPlan(selectedDepartment);
  return Object.freeze({
    schemaVersion:1,
    departmentId:selectedDepartment,
    taskType:taskType.trim().slice(0,100),
    objective:objective.trim().slice(0,2000),
    primaryAgentId:plan.primaryAgent.id,
    supportingAgentIds:[...plan.projectIds.slice(1)],
    specialistProfiles:[...plan.specialistProfiles],
    status:'planned_not_executed',
    requiresConfiguredModelProvider:plan.modelProviderRequired,
    risk:route.risk,
    approvalRequired:route.approvalRequired,
    requiresSandboxForCodeExecution:selectedDepartment === 'engineering' || selectedDepartment === 'auren' || taskType === 'github_ci_check',
    approvalRequiredForExternalEffects:true,
    externalActionExecuted:false,
  });
}

module.exports = {AGENT_CATALOG, DEPARTMENT_AGENT_BINDINGS, getDepartmentAgentPlan, buildDepartmentAgentDispatch};
