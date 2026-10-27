'use strict';

// Reviewed GitHub agent/framework catalog and deterministic departmental assignments.
// Catalog entries describe candidate open-source projects; they are NOT installed or live
// runtimes. NOVA must add a model provider, sandboxed worker, and tested adapter before execution.
const AGENT_PROJECTS = Object.freeze({
  langgraph: {
    id:'langgraph',
    name:'LangGraph',
    repository:'https://github.com/langchain-ai/langgraph',
    license:'MIT',
    runtime:'Python / JavaScript',
    role:'Stateful orchestration, checkpoints, pause/resume, human approval gates',
    integrationMode:'orchestration_adapter',
    costNote:'Library is free; model inference and hosting may cost money.',
  },
  crewai: {
    id:'crewai',
    name:'CrewAI',
    repository:'https://github.com/crewAIInc/crewAI',
    license:'MIT',
    runtime:'Python',
    role:'Role-based specialist teams and collaborative task workflows',
    integrationMode:'specialist_team_adapter',
    costNote:'Library is free; model inference and hosting may cost money.',
  },
  browser_use: {
    id:'browser_use',
    name:'Browser Use',
    repository:'https://github.com/browser-use/browser-use',
    license:'MIT',
    runtime:'Python',
    role:'Browser-based public-source research and structured data collection',
    integrationMode:'sandboxed_browser_adapter',
    costNote:'Use local/open-source mode; hosted browser infrastructure is optional and may cost money.',
  },
  openhands: {
    id:'openhands',
    name:'OpenHands',
    repository:'https://github.com/OpenHands/OpenHands',
    license:'MIT',
    runtime:'TypeScript / Python SDK',
    role:'Repository-aware software engineering and coding tasks in an isolated workspace',
    integrationMode:'sandboxed_code_adapter',
    costNote:'Software is open source; safe compute and model inference may cost money.',
  },
  smolagents: {
    id:'smolagents',
    name:'smolagents',
    repository:'https://github.com/huggingface/smolagents',
    license:'Apache-2.0',
    runtime:'Python',
    role:'Lightweight tool-using agents for research and data workflows',
    integrationMode:'restricted_tool_adapter',
    costNote:'Library is free; model inference and hosting may cost money.',
  },
  pydantic_ai: {
    id:'pydantic_ai',
    name:'Pydantic AI',
    repository:'https://github.com/pydantic/pydantic-ai',
    license:'MIT',
    runtime:'Python',
    role:'Typed outputs, input validation, and schema-constrained assistant workflows',
    integrationMode:'typed_output_adapter',
    costNote:'Library is free; model inference and hosting may cost money.',
  },
  aider: {
    id:'aider',
    name:'Aider',
    repository:'https://github.com/Aider-AI/aider',
    license:'Apache-2.0',
    runtime:'Python / CLI',
    role:'Pair-programming and controlled code changes in a Git workspace',
    integrationMode:'sandboxed_code_adapter',
    costNote:'Tool is free; model inference and compute may cost money.',
  },
});

const DEPARTMENT_AGENT_MAP = Object.freeze({
  executive:{primary:['langgraph','crewai'],support:['pydantic_ai'],why:'Coordinate stateful plans, delegate specialist reviews, and validate structured executive reports.'},
  security:{primary:['langgraph','pydantic_ai'],support:['openhands'],why:'Run gated security-review workflows, produce structured findings, and propose fixes for review; never run offensive tests outside authorized scope.'},
  engineering:{primary:['openhands','aider'],support:['langgraph'],why:'Use isolated coding workspaces for repository changes, with orchestration and test evidence.'},
  quality:{primary:['pydantic_ai','langgraph'],support:['openhands'],why:'Validate structured acceptance criteria, track test evidence, and route failures for controlled fixes.'},
  research:{primary:['browser_use','smolagents'],support:['pydantic_ai'],why:'Collect public-source evidence, extract structured facts, and label uncertainty.'},
  product:{primary:['crewai','pydantic_ai'],support:['browser_use'],why:'Coordinate product/UX analysis, validate requirements, and research comparable public products.'},
  growth:{primary:['browser_use','crewai'],support:['pydantic_ai'],why:'Research trends and public competitor signals, then create measurable growth experiments and draft content.'},
  finance:{primary:['pydantic_ai','smolagents'],support:['langgraph'],why:'Build typed budget and revenue scenarios, check assumptions, and prepare risk notes; no trading, transfers, or wallet access.'},
  legal:{primary:['browser_use','pydantic_ai'],support:['langgraph'],why:'Research official public policies and structure compliance checklists; not a substitute for licensed legal advice.'},
  operations:{primary:['crewai','langgraph'],support:['pydantic_ai'],why:'Coordinate tasks, status updates, reminders, and drafts with validation and auditability.'},
  auren:{primary:['openhands','langgraph'],support:['browser_use','pydantic_ai'],why:'Inspect approved AUREN repository work, plan code changes, research markets, and report test/CI evidence.'},
});

const EXTERNAL_ACTION_TYPES = new Set([
  'social_publish','send_email','send_message','spend_money','investment_execution',
  'deploy_production','delete_data','change_permissions','create_account','submit_application',
]);

function getDepartmentAgentPlan(departmentId) {
  const assignment = DEPARTMENT_AGENT_MAP[departmentId];
  if (!assignment) throw new TypeError('Unknown departmentId.');
  const resolve = (ids) => ids.map((id) => {
    const project = AGENT_PROJECTS[id];
    if (!project) throw new Error('Agent catalog references an unknown project.');
    return {...project};
  });
  return Object.freeze({
    departmentId,
    primaryAgents:resolve(assignment.primary),
    supportingAgents:resolve(assignment.support),
    rationale:assignment.why,
    integrationStatus:'catalogued_not_connected',
    runtimeReady:false,
    requiredBeforeLiveUse:[
      'Install and pin the reviewed dependency in an isolated worker environment.',
      'Configure a model provider without hard-coding secrets.',
      'Enforce owner authentication, per-task permissions, timeouts, and resource limits.',
      'Add adapter contract tests and end-to-end evidence.',
    ],
    externalActionsRequireOwnerApproval:true,
    mayExecuteExternalAction:false,
  });
}

function getAllDepartmentAgentPlans() {
  return Object.keys(DEPARTMENT_AGENT_MAP).map(getDepartmentAgentPlan);
}

function buildDepartmentAgentAssignment({departmentId, objective, taskType = 'plan'}) {
  if (typeof objective !== 'string' || !objective.trim()) {
    throw new TypeError('A clear objective is required.');
  }
  const plan = getDepartmentAgentPlan(departmentId);
  const externalSideEffect = EXTERNAL_ACTION_TYPES.has(String(taskType).trim());
  return Object.freeze({
    schemaVersion:1,
    departmentId,
    objective:objective.trim().slice(0,2000),
    taskType:String(taskType).trim().slice(0,80),
    orchestrator:'langgraph',
    agents:plan.primaryAgents.map((agent) => ({id:agent.id, name:agent.name, repository:agent.repository, role:agent.role})),
    integrationStatus:plan.integrationStatus,
    runtimeReady:false,
    approvalRequired:externalSideEffect,
    mayExecuteExternalAction:false,
    nextStep:externalSideEffect
      ? 'Prepare a draft or plan only; pause for explicit owner approval before any external side effect.'
      : 'This is a routing plan only. A tested worker adapter and model provider are required before agent execution.',
  });
}

module.exports = {
  AGENT_PROJECTS,
  DEPARTMENT_AGENT_MAP,
  EXTERNAL_ACTION_TYPES,
  getDepartmentAgentPlan,
  getAllDepartmentAgentPlans,
  buildDepartmentAgentAssignment,
};
