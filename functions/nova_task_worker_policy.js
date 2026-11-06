'use strict';

const {ACTION_POLICIES, canNovaWorkerExecute} = require('./nova_action_policy');

const SAFE_TEXT_TYPES = new Set(
  Object.keys(ACTION_POLICIES).filter((type) =>
    ACTION_POLICIES[type].workerExecutable && !ACTION_POLICIES[type].approvalRequired
  )
);

function isTaskExecutable(task, ownerUid, nowMs = Date.now()) {
  return canNovaWorkerExecute(task, ownerUid, nowMs);
}

module.exports = {SAFE_TEXT_TYPES, isTaskExecutable};
