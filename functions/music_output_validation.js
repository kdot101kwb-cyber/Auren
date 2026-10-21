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

module.exports = {isMaterializedMusicOutput};
