'use strict';

function normalizeGroupSelection({ownRequestId, candidateRequestIds, groupSize}) {
  const ownId = typeof ownRequestId === 'string' ? ownRequestId.trim() : '';
  const candidates = Array.isArray(candidateRequestIds)
    ? candidateRequestIds.map((id) => typeof id === 'string' ? id.trim() : '')
    : [];
  const fail = (message) => {
    const error = new Error(message);
    error.code = 'invalid-argument';
    throw error;
  };
  if (!Number.isInteger(groupSize) || groupSize < 3 || groupSize > 8) {
    fail('Group size must be an integer from 3 to 8.');
  }
  if (!ownId || candidates.length !== groupSize - 1 ||
      candidates.some((id) => !id) ||
      new Set(candidates).size !== candidates.length ||
      candidates.includes(ownId)) {
    fail('Select exactly groupSize - 1 unique candidate requests.');
  }
  return [ownId, ...candidates];
}

function hasBlockedPair(memberUids, blockedPairs) {
  const members = new Set(memberUids);
  return blockedPairs.some((pair) =>
    pair && pair.uid !== pair.blockedUid &&
    members.has(pair.uid) && members.has(pair.blockedUid));
}

module.exports = {normalizeGroupSelection, hasBlockedPair};
