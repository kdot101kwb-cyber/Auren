'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {getApps, initializeApp} = require('firebase-admin/app');

// Callable handlers are invoked directly so authorization failures are tested
// before any Firestore, provider, GitHub, or other external side effect.
if (!getApps().length) {
  initializeApp({projectId:'auren-nova-owner-auth-tests'});
}

const callableModules = [
  ['./nova_command_center', [
    'submitNovaTask',
    'getNovaTask',
    'approveNovaTask',
    'cancelNovaTask',
    'listNovaTasks',
  ]],
  ['./nova_self_repair_service', [
    'generateNovaRepairProposal',
    'listNovaRepairProposals',
    'createNovaRepairProposal',
    'approveAndApplyNovaRepair',
    'recoverNovaRepairApply',
    'checkNovaRepairValidation',
  ]],
  ['./nova_debate_service', [
    'novaStrategicDebate',
    'novaApproveDebatePlan',
  ]],
  ['./nova_app_builder', [
    'submitNovaBuildJob',
    'getNovaBuildJob',
  ]],
  ['./nova_higgsfield_service', [
    'submitNovaHiggsfieldVideo',
    'getNovaHiggsfieldVideoStatus',
  ]],
  ['./nova_freetheai_video_service', [
    'listNovaFreeTheAIVideoModels',
    'submitNovaFreeTheAIVideo',
    'getNovaFreeTheAIVideoStatus',
  ]],
  ['./nova_revenue_engine', [
    'configureNovaRevenueEngine',
    'getNovaRevenueDashboard',
  ]],
  ['./nova_signal_engine', [
    'getNovaSignalOpportunities',
  ]],
];

const endpoints = callableModules.flatMap(([modulePath, names]) => {
  const moduleExports = require(modulePath);
  return names.map((name) => {
    const callable = moduleExports[name];
    assert.equal(typeof callable, 'function', modulePath + ' must export ' + name);
    assert.equal(typeof callable.run, 'function', modulePath + ':' + name + ' must expose its callable handler');
    return {name, callable};
  });
});

function request(auth) {
  return {
    data:{},
    auth,
    app:{appId:'nova-owner-auth-test'},
  };
}

const invalidIdentities = [
  {
    label:'unauthenticated request',
    auth:null,
    code:'unauthenticated',
  },
  {
    label:'anonymous account, even with a forged owner claim',
    auth:{
      uid:'anonymous-user',
      token:{
        novaOwner:true,
        email_verified:true,
        firebase:{sign_in_provider:'anonymous'},
      },
    },
    code:'permission-denied',
  },
  {
    label:'ordinary verified account without owner claim',
    auth:{
      uid:'ordinary-user',
      token:{
        email_verified:true,
        firebase:{sign_in_provider:'password'},
      },
    },
    code:'permission-denied',
  },
  {
    label:'owner claim on an unverified account',
    auth:{
      uid:'unverified-user',
      token:{
        novaOwner:true,
        email_verified:false,
        firebase:{sign_in_provider:'password'},
      },
    },
    code:'permission-denied',
  },
  {
    label:'owner claim without explicit provider metadata',
    auth:{
      uid:'providerless-user',
      token:{novaOwner:true, email_verified:true},
    },
    code:'permission-denied',
  },
];

for (const {name, callable} of endpoints) {
  for (const identity of invalidIdentities) {
    test(name + ' rejects ' + identity.label + ' before handler side effects', async () => {
      await assert.rejects(
        Promise.resolve().then(() => callable.run(request(identity.auth))),
        (error) => error && error.code === identity.code,
      );
    });
  }
}

test('integration coverage includes every declared private NOVA callable endpoint', () => {
  const declared = new Set();
  for (const file of fs.readdirSync(__dirname).filter((name) => /^nova_.*\.js$/.test(name))) {
    const source = fs.readFileSync(path.join(__dirname, file), 'utf8');
    for (const match of source.matchAll(/exports\.(\w+)\s*=\s*onCall\s*\(/g)) {
      declared.add(match[1]);
    }
  }
  const covered = new Set(endpoints.map((endpoint) => endpoint.name));
  assert.deepEqual([...declared].sort(), [...covered].sort(),
    'Every exported onCall in a NOVA module must be exercised by this authorization suite.');
  assert.equal(endpoints.length, 23);
});
