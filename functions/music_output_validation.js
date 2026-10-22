'use strict';

function isMaterializedMusicOutput(output) {
  if (!output || typeof output !== 'object' || Array.isArray(output)) return false;
  if (typeof output.storagePath === 'string' && output.storagePath.trim()) return true;
  if (typeof output.url !== 'string' || !output.url.trim()) return false;
  try {
    return new URL(output.url).protocol === 'https:';
  } catch (_) {
    return false;
  }
}

/**
 * Verify that an output reference points to a materialized audio artifact.
 * Dependencies are injectable so the validation behavior can be tested without
 * Firebase or network access.
 */
async function validateMaterializedMusicOutput(output, {
  getStorageFile,
  fetchImpl = globalThis.fetch,
  timeoutMs = 10000,
} = {}) {
  if (!output || typeof output !== 'object' || Array.isArray(output)) {
    return {ok: false, reason: 'missing_artifact'};
  }

  if (typeof output.storagePath === 'string' && output.storagePath.trim()) {
    if (typeof getStorageFile !== 'function') {
      return {ok: false, reason: 'storage_validation_unavailable'};
    }
    try {
      const file = getStorageFile(output.storagePath.trim());
      const [exists] = await file.exists();
      if (!exists) return {ok: false, reason: 'storage_object_missing'};
      const [metadata] = await file.getMetadata();
      const contentType = String(metadata?.contentType || '').toLowerCase();
      if (!(contentType.startsWith('audio/') || contentType === 'application/octet-stream')) {
        return {ok: false, reason: 'not_audio', contentType: contentType || null};
      }
      return {ok: true, storagePath: output.storagePath.trim(), contentType};
    } catch (_) {
      return {ok: false, reason: 'storage_validation_failed'};
    }
  }

  if (typeof output.url !== 'string' || !output.url.trim()) {
    return {ok: false, reason: output.externalId ? 'artifact_not_materialized' : 'missing_artifact'};
  }
  let url;
  try {
    url = new URL(output.url);
  } catch (_) {
    return {ok: false, reason: 'invalid_url'};
  }
  if (url.protocol !== 'https:') return {ok: false, reason: 'invalid_url'};
  if (typeof fetchImpl !== 'function' || typeof AbortController !== 'function') {
    return {ok: false, reason: 'url_validation_unavailable'};
  }

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetchImpl(url.toString(), {method: 'HEAD', signal: controller.signal});
    if (!response.ok) return {ok: false, reason: 'http_' + response.status};
    const contentType = String(response.headers?.get?.('content-type') || '').toLowerCase();
    if (!(contentType.startsWith('audio/') || contentType === 'application/octet-stream')) {
      return {ok: false, reason: 'not_audio', contentType: contentType || null};
    }
    return {ok: true, contentType};
  } catch (_) {
    return {ok: false, reason: 'artifact_unreachable'};
  } finally {
    clearTimeout(timer);
  }
}

module.exports = {isMaterializedMusicOutput, validateMaterializedMusicOutput};
