'use strict';

function parseFirebaseStorageUrl(value) {
  let url;
  try {
    url = new URL(String(value || ''));
  } catch (_) {
    return null;
  }

  if (url.protocol !== 'https:' || url.hostname !== 'firebasestorage.googleapis.com') {
    return null;
  }

  const match = url.pathname.match(/^\/v0\/b\/([^/]+)\/o\/(.+)$/);
  if (!match) return null;

  try {
    const bucketName = decodeURIComponent(match[1]);
    const objectPath = decodeURIComponent(match[2]);
    if (!bucketName || !objectPath || objectPath.startsWith('/')) return null;
    return {bucketName, objectPath};
  } catch (_) {
    return null;
  }
}

module.exports = {parseFirebaseStorageUrl};
