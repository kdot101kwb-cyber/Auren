'use strict';

function validateRequestIds(value) {
  if (!Array.isArray(value) || value.length < 3 || value.length > 8) {
    throw new TypeError('A random group must contain 3 to 8 request IDs.');
  }
  const ids = value.map((item) => typeof item === 'string' ? item.trim() : '');
  if (ids.some((id) => !id || id.length > 128) || new Set(ids).size !== ids.length) {
    throw new TypeError('Request IDs must be non-empty, unique strings of at most 128 characters.');
  }
  return ids;
}

function validateWaitingRequests(requests, callerUid, expectedSize) {
  if (!Array.isArray(requests) || requests.length !== expectedSize || expectedSize < 3 || expectedSize > 8) {
    throw new TypeError('Selected requests do not match the requested group size.');
  }
  const uids = requests.map((item) => String(item?.uid || ''));
  if (uids.some((uid) => !uid) || new Set(uids).size !== uids.length) {
    throw new TypeError('Each selected request must belong to a different user.');
  }
  if (!uids.includes(callerUid)) throw new TypeError('Your own waiting request must be included.');
  if (requests.some((item) => item?.status !== 'waiting' || item?.groupSize !== expectedSize)) {
    throw new TypeError('All selected requests must still be waiting for the same group size.');
  }
  return uids;
}

module.exports = {validateRequestIds, validateWaitingRequests};
