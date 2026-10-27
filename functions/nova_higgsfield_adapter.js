'use strict';

const API_ORIGIN = 'https://api.higgsfield.ai';

function validateEndpoint(value) {
  let url;
  try { url = new URL(String(value || '')); } catch (_) {
    throw new Error('HIGGSFIELD_VIDEO_ENDPOINT must be a valid HTTPS API URL.');
  }
  if (url.protocol !== 'https:') {
    throw new Error('HIGGSFIELD_VIDEO_ENDPOINT must use HTTPS.');
  }
  if (url.origin !== API_ORIGIN || url.username || url.password || url.search || url.hash) {
    throw new Error('Endpoint must use the official Higgsfield API origin.');
  }
  if (!/^\/higgsfield(?:-ai)?\/[a-zA-Z0-9._/-]+$/.test(url.pathname) || url.pathname.includes('..')) {
    throw new Error('Endpoint path is not an allowed model endpoint.');
  }
  return url.toString();
}

function normalizeStatus(payload) {
  const rawStatus = String(payload?.status || payload?.state || '').toLowerCase();
  const outputUrl = payload?.video_url || payload?.output_url || payload?.result?.video_url || payload?.result?.output_url || payload?.assets?.[0]?.url || null;
  if (['completed','complete','succeeded','success','done'].includes(rawStatus)) return {status:'succeeded', outputUrl, rawStatus};
  if (['failed','error','cancelled','canceled'].includes(rawStatus)) return {status:'failed', outputUrl:null, rawStatus, error:String(payload?.error?.message || payload?.error || payload?.message || 'Higgsfield generation failed').slice(0,500)};
  return {status:'processing', outputUrl:null, rawStatus:rawStatus || 'unknown'};
}

async function requestJson(url, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25000);
  try {
    const response = await (options.fetchImpl || fetch)(url, {
      method:options.method || 'GET',
      headers:{accept:'application/json', ...(options.headers || {}), ...(options.body ? {'content-type':'application/json'} : {})},
      ...(options.body ? {body:JSON.stringify(options.body)} : {}),
      signal:controller.signal,
    });
    const raw = await response.text();
    let payload = {};
    try { payload = raw ? JSON.parse(raw) : {}; } catch (_) {}
    if (!response.ok) throw new Error(('Higgsfield API HTTP ' + response.status + ': ' + String(payload?.error?.message || payload?.message || raw || 'request failed')).slice(0,500));
    return payload;
  } finally { clearTimeout(timeout); }
}

function authHeader(keyId, keySecret) {
  const id = String(keyId || '').trim(), secret = String(keySecret || '').trim();
  if (!id || !secret) throw new Error('Higgsfield API credentials are not configured.');
  return {authorization:'Key ' + id + ':' + secret};
}

async function submitVideoGeneration({endpoint, prompt, keyId, keySecret, options={}, fetchImpl=fetch}) {
  const url = validateEndpoint(endpoint);
  const cleanPrompt = String(prompt || '').trim();
  if (!cleanPrompt || cleanPrompt.length > 6000) throw new Error('Video prompt must contain 1–6000 characters.');
  const payload = await requestJson(url, {method:'POST', headers:authHeader(keyId,keySecret), body:{prompt:cleanPrompt,...options}, fetchImpl});
  const requestId = String(payload?.request_id || payload?.id || '').trim();
  if (!/^[A-Za-z0-9_-]{8,128}$/.test(requestId)) throw new Error('Higgsfield response did not include a valid request ID.');
  return {requestId, statusUrl:API_ORIGIN + '/requests/' + encodeURIComponent(requestId) + '/status', status:normalizeStatus(payload)};
}

async function getVideoGenerationStatus({requestId,keyId,keySecret,fetchImpl=fetch}) {
  const id = String(requestId || '').trim();
  if (!/^[A-Za-z0-9_-]{8,128}$/.test(id)) throw new Error('Invalid Higgsfield request ID.');
  const payload = await requestJson(API_ORIGIN + '/requests/' + encodeURIComponent(id) + '/status', {headers:authHeader(keyId,keySecret),fetchImpl});
  return normalizeStatus(payload);
}

module.exports = {validateEndpoint,normalizeStatus,submitVideoGeneration,getVideoGenerationStatus};
