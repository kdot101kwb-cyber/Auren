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
    headers:{authorization:'Bearer '+key},
    body:{version:v, input:input || {}},
    timeoutMs:30000,
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

/**
 * MoneyPrinterTurbo adapter.
 * The base URL/path are deployment-configured so AUREN can point at a local,
 * LAN, VM, or hosted MPT instance without exposing its address to clients.
 */
async function submitMoneyPrinterTurbo({baseUrl, apiKey='', generatePath='/v1/video/generate', subject, language='en', aspectRatio='16:9', voice='', idempotencyKey=''}) {
  const base = requireValue(baseUrl, 'MPT_BASE_URL').replace(/\\/$/, '');
  const path = String(generatePath || '/v1/video/generate').startsWith('/') ? String(generatePath || '/v1/video/generate') : '/' + String(generatePath);
  const headers = apiKey ? {authorization:'Bearer '+String(apiKey)} : {};
  const result = await requestJson(base + path, {
    method:'POST',
    headers,
    body:{
      subject:String(subject || '').slice(0,3000),
      video_subject:String(subject || '').slice(0,3000),
      language:String(language || 'en'),
      aspect_ratio:String(aspectRatio || '16:9'),
      ...(voice ? {voice:String(voice).slice(0,120)} : {}),
      idempotency_key:String(idempotencyKey || ''),
    },
    timeoutMs:30000,
  });
  if (!result.ok) return {ok:false, providerId:'moneyprinterturbo', ...result};
  const data=result.data || {};
  const jobId=String(data.task_id || data.job_id || data.id || data.taskId || '');
  const output=normalizeGenericVideoOutput(data);
  if (!jobId && !output) return {ok:false, providerId:'moneyprinterturbo', message:'MoneyPrinterTurbo returned neither a job id nor a video artifact.'};
  return {ok:true, providerId:'moneyprinterturbo', state:String(data.status || (output ? 'completed' : 'pending')), externalJobId:jobId, idempotencyKey, output};
}

async function pollMoneyPrinterTurbo({baseUrl, apiKey='', jobId, pollPath='/v1/videos/{job_id}/status'}) {
  const base = requireValue(baseUrl, 'MPT_BASE_URL').replace(/\\/$/, '');
  const id = requireValue(jobId, 'MPT_JOB_ID');
  const template=String(pollPath || '/v1/videos/{job_id}/status');
  const path=(template.startsWith('/') ? template : '/' + template).replace('{job_id}', encodeURIComponent(id));
  const result=await requestJson(base + path, {headers:apiKey ? {authorization:'Bearer '+String(apiKey)} : {}});
  if (!result.ok) return {ok:false, providerId:'moneyprinterturbo', ...result};
  const data=result.data || {};
  const state=String(data.status || data.state || 'unknown').toLowerCase();
  const output=normalizeGenericVideoOutput(data);
  return {ok:true, providerId:'moneyprinterturbo', state, externalJobId:id, output, error:String(data.error || data.error_message || '').slice(0,700)};
}

function normalizeGenericVideoOutput(data) {
  const candidates=[data?.video_url,data?.url,data?.output?.url,data?.result?.url,data?.result?.video_url,data?.result?.video_path,data?.video_path];
  const url=candidates.find((v)=>typeof v==='string' && v.trim());
  return url ? {url:String(url).trim()} : null;
}

async function cancelReplicate({token, predictionId}) {
  const key = requireValue(token, 'REPLICATE_API_TOKEN');
  const id = requireValue(predictionId, 'REPLICATE_PREDICTION_ID');
  const result = await requestJson('https://api.replicate.com/v1/predictions/'+encodeURIComponent(id)+'/cancel', {
    method:'POST',
    headers:{authorization:'Bearer '+key},
    timeoutMs:15000,
  });
  return result.ok ? {ok:true, providerId:'replicate', state:String(result.data?.status || 'canceled')} : {ok:false, providerId:'replicate', ...result};
}

function normalizeReplicateOutput(data) {
  const output=data?.output;
  if (typeof output==='string' && output) return {url:output};
  if (Array.isArray(output) && output.length) {
    const firstString=output.find((v)=>typeof v==='string') || '';
    if (firstString) return {url:firstString};
    const firstObject=output.find((v)=>v && typeof v==='object') || null;
    if (firstObject) {
      const url=String(firstObject.url || firstObject.audio_url || firstObject.video_url || '').trim();
      if (url) return {url};
    }
  }
  if (output && typeof output==='object') {
    const url=String(output.url || output.audio_url || output.video_url || '').trim();
    if (url) return {url};
  }
  return null;
}

module.exports = {
  requestJson,
  submitHuggingFaceChat,
  submitReplicate,
  pollReplicate,
  cancelReplicate,
  normalizeReplicateOutput,
  submitMoneyPrinterTurbo,
  pollMoneyPrinterTurbo,
  normalizeGenericVideoOutput,
};
