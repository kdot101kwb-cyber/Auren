'use strict';

/**
 * AUREN live provider adapters.
 *
 * These adapters are deliberately dependency-free and server-side only.
 * Credentials are passed by the caller; never put keys in Firestore or the
 * client. Adapters return a normalized async job contract so the production
 * worker can submit once and poll later.
 */

function requireValue(value, name) {
  const v = String(value || '').trim();
  if (!v) throw new Error(name + ' is not configured.');
  return v;
}

async function requestJson(url, {method='GET', headers={}, body, timeoutMs=30000}={}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, {
      method,
      headers: {'content-type':'application/json', ...headers},
      ...(body === undefined ? {} : {body: JSON.stringify(body)}),
      signal: controller.signal,
    });
    const raw = await response.text();
    let data = {};
    try { data = JSON.parse(raw); } catch (_) { data = {raw}; }
    if (!response.ok) {
      return {ok:false, status:response.status, message:String(
        data?.detail || data?.error?.message || data?.error || data?.message || raw
      ).slice(0,700), data};
    }
    return {ok:true, status:response.status, data};
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Hugging Face routed chat adapter.
 * Current HF docs expose an OpenAI-compatible chat endpoint and automatic
 * provider routing. This adapter is for planning/script/QC tasks.
 */
async function submitHuggingFaceChat({token, model='openai/gpt-oss-120b:fastest', messages, idempotencyKey=''}) {
  const key = requireValue(token, 'HF_TOKEN');
  const result = await requestJson('https://router.huggingface.co/v1/chat/completions', {
    method:'POST',
    headers:{authorization:'Bearer '+key},
    body:{model, messages:Array.isArray(messages) ? messages : [], stream:false},
  });
  if (!result.ok) return {ok:false, providerId:'huggingface', ...result};
  const text = result.data?.choices?.[0]?.message?.content;
  if (!text) return {ok:false, providerId:'huggingface', message:'Provider returned no text output.'};
  return {
    ok:true, providerId:'huggingface', state:'completed',
    idempotencyKey, output:{type:'text', text},
  };
}

/**
 * Replicate prediction submission. A version or model reference is required.
 * The returned prediction id is persisted by the caller and polled later.
 */
async function submitReplicate({token, version, input, idempotencyKey=''}) {
  const key = requireValue(token, 'REPLICATE_API_TOKEN');
  const v = requireValue(version, 'REPLICATE_VERSION');
  const result = await requestJson('https://api.replicate.com/v1/predictions', {
    method:'POST',
    headers:{authorization:'Bearer '+key, prefer:'wait'},
    body:{version:v, input:input || {}},
    timeoutMs:60000,
  });
  if (!result.ok) return {ok:false, providerId:'replicate', ...result};
  const predictionId = String(result.data?.id || '');
  if (!predictionId) return {ok:false, providerId:'replicate', message:'Replicate returned no prediction id.'};
  return {
    ok:true, providerId:'replicate',
    state:String(result.data?.status || 'starting'),
    externalJobId:predictionId,
    idempotencyKey,
    output:normalizeReplicateOutput(result.data),
  };
}

async function pollReplicate({token, predictionId}) {
  const key = requireValue(token, 'REPLICATE_API_TOKEN');
  const id = requireValue(predictionId, 'REPLICATE_PREDICTION_ID');
  const result = await requestJson('https://api.replicate.com/v1/predictions/'+encodeURIComponent(id), {
    headers:{authorization:'Bearer '+key},
  });
  if (!result.ok) return {ok:false, providerId:'replicate', ...result};
  const status=String(result.data?.status || 'unknown');
  return {
    ok:true, providerId:'replicate', state:status,
    externalJobId:id,
    output:normalizeReplicateOutput(result.data),
    error:status==='failed' || status==='canceled' ? String(result.data?.error || 'Provider job failed').slice(0,700) : '',
  };
}

function normalizeReplicateOutput(data) {
  const output=data?.output;
  if (typeof output==='string' && output) return {url:output};
  if (Array.isArray(output) && output.length) {
    const first=output.find((v)=>typeof v==='string') || '';
    if (first) return {url:first};
  }
  return null;
}

module.exports = {
  requestJson,
  submitHuggingFaceChat,
  submitReplicate,
  pollReplicate,
  normalizeReplicateOutput,
};
