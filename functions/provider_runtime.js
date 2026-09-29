'use strict';

const {
  submitHuggingFaceChat,
  submitReplicate,
  pollReplicate,
  submitMoneyPrinterTurbo,
  pollMoneyPrinterTurbo,
} = require('./live_provider_adapters');

/**
 * Runtime provider router for AUREN.
 *
 * Order is deterministic and fail-closed:
 * configured free/low-cost providers are attempted first, then later
 * candidates. A provider is considered live only when its adapter returns a
 * real accepted/completed result. No output is fabricated on failure.
 */
const DEFAULT_PROVIDER_ORDER = Object.freeze([
  'huggingface',
  'replicate',
  'moneyprinterturbo',
]);

function buildProviderOrder(candidates) {
  const source = Array.isArray(candidates) && candidates.length ? candidates : DEFAULT_PROVIDER_ORDER;
  return [...new Set(source.map((v) => String(v || '').trim()).filter(Boolean))];
}

async function submitAurenProviderJob({provider, credentials, task, idempotencyKey}) {
  if (provider === 'huggingface') {
    return submitHuggingFaceChat({
      token: credentials?.token,
      model: credentials?.model || 'openai/gpt-oss-120b:fastest',
      messages: task?.messages || [],
      idempotencyKey,
    });
  }

  if (provider === 'moneyprinterturbo') {
    return submitMoneyPrinterTurbo({
      baseUrl: credentials?.baseUrl,
      apiKey: credentials?.apiKey,
      generatePath: credentials?.generatePath,
      subject: task?.subject || task?.input?.prompt,
      language: task?.language || 'en',
      aspectRatio: task?.aspectRatio || task?.input?.aspect_ratio || '16:9',
      voice: task?.voice || '',
      idempotencyKey,
    });
  }

  if (provider === 'replicate') {
    return submitReplicate({
      token: credentials?.token,
      version: credentials?.version,
      input: task?.input || {},
      idempotencyKey,
    });
  }

  return {ok:false, providerId:provider, unavailable:true, message:'No live adapter is registered for this provider.'};
}

async function submitWithFallback({candidates, credentialsByProvider={}, task, idempotencyKey}) {
  const order = buildProviderOrder(candidates);
  const attempts = [];

  for (const provider of order) {
    const result = await submitAurenProviderJob({
      provider,
      credentials: credentialsByProvider[provider] || {},
      task,
      idempotencyKey,
    });
    attempts.push({
      providerId:provider,
      ok:Boolean(result.ok),
      state:result.state || '',
      externalJobId:result.externalJobId || '',
      message:String(result.message || result.error || '').slice(0,500),
    });

    if (result.ok) {
      return {ok:true, providerId:provider, result, attempts};
    }
  }

  return {
    ok:false,
    state:'waiting_provider',
    idempotencyKey,
    attempts,
    message:'No configured live provider accepted the task.',
  };
}

async function pollAurenProviderJob({provider, credentials, externalJobId}) {
  if (provider === 'moneyprinterturbo') {
    return pollMoneyPrinterTurbo({
      baseUrl: credentials?.baseUrl,
      apiKey: credentials?.apiKey,
      jobId: externalJobId,
      pollPath: credentials?.pollPath,
    });
  }
  if (provider !== 'replicate') {
    return {ok:false, providerId:provider, state:'completed',
      message:'This adapter has no asynchronous poll operation.'};
  }
  return pollReplicate({
    token:credentials?.token,
    predictionId:externalJobId,
  });
}

module.exports = {
  DEFAULT_PROVIDER_ORDER,
  buildProviderOrder,
  submitAurenProviderJob,
  submitWithFallback,
  pollAurenProviderJob,
};
