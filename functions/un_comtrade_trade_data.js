'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');

const API_BASE = 'https://comtradeapi.un.org/public/v1/preview/C/A/HS';
const MAX_RECORDS = 100;

function normalizeInput(input = {}) {
  const reporterCode = String(input.reporterCode || '').trim();
  const period = String(input.period || '').trim();
  const flowCode = String(input.flowCode || 'X').trim().toUpperCase();
  const partnerCode = String(input.partnerCode ?? '0').trim();
  const cmdCode = String(input.cmdCode || 'TOTAL').trim().toUpperCase();
  const limitValue = Number(input.limit ?? 25);
  const limit = Number.isFinite(limitValue) ? Math.max(1, Math.min(MAX_RECORDS, Math.floor(limitValue))) : 25;
  if (!/^\d{1,3}$/.test(reporterCode)) {
    throw new HttpsError('invalid-argument', 'reporterCode must be a UN M49 numeric reporter code.');
  }
  if (!/^\d{4}$/.test(period) || Number(period) < 1962 || Number(period) > new Date().getUTCFullYear()) {
    throw new HttpsError('invalid-argument', 'period must be a valid four-digit year.');
  }
  if (!['X', 'M', 'RX'].includes(flowCode)) {
    throw new HttpsError('invalid-argument', 'flowCode must be X (exports), M (imports), or RX (re-exports).');
  }
  if (!/^\d{1,3}$/.test(partnerCode)) {
    throw new HttpsError('invalid-argument', 'partnerCode must be a UN M49 numeric partner code.');
  }
  if (!/^[A-Z0-9]{1,10}$/.test(cmdCode)) {
    throw new HttpsError('invalid-argument', 'cmdCode must be a valid commodity code.');
  }
  return {reporterCode, period, flowCode, partnerCode, cmdCode, limit};
}

function normalizeTradeRecord(row) {
  return {
    reporterCode: row.reporterCode == null ? null : String(row.reporterCode),
    reporter: String(row.reporterDesc || '').trim() || null,
    partnerCode: row.partnerCode == null ? null : String(row.partnerCode),
    partner: String(row.partnerDesc || '').trim() || null,
    commodityCode: String(row.cmdCode || '').trim() || null,
    commodity: String(row.cmdDesc || '').trim() || null,
    flowCode: String(row.flowCode || '').trim() || null,
    flow: String(row.flowDesc || '').trim() || null,
    period: row.period == null ? null : String(row.period),
    tradeValueUsd: Number.isFinite(Number(row.primaryValue)) ? Number(row.primaryValue) : null,
    netWeightKg: Number.isFinite(Number(row.netWgt)) ? Number(row.netWgt) : null,
    quantity: Number.isFinite(Number(row.qty)) ? Number(row.qty) : null,
    quantityUnit: String(row.qtyUnitAbbr || '').trim() || null,
    source: 'United Nations Statistics Division — UN Comtrade',
    sourceUrl: 'https://comtrade.un.org/',
    verificationStatus: 'official_reported_trade_statistics_not_company_verification',
  };
}

async function searchUNComtrade(input, options = {}) {
  const filters = normalizeInput(input);
  const fetchImpl = options.fetchImpl || fetch;
  const url = new URL(API_BASE);
  for (const [key, value] of Object.entries({
    reportercode: filters.reporterCode,
    period: filters.period,
    flowCode: filters.flowCode,
    partnerCode: filters.partnerCode,
    cmdCode: filters.cmdCode,
    maxRecords: String(filters.limit),
    includeDesc: 'true',
  })) url.searchParams.set(key, value);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);
  let response;
  try {
    response = await fetchImpl(url.toString(), {method: 'GET', headers: {accept: 'application/json'}, signal: controller.signal});
  } catch (error) {
    throw new HttpsError('unavailable', error?.name === 'AbortError' ? 'UN Comtrade request timed out.' : 'UN Comtrade is temporarily unavailable.');
  } finally {
    clearTimeout(timeout);
  }
  if (!response.ok) {
    throw new HttpsError('unavailable', 'UN Comtrade returned HTTP ' + response.status + '.');
  }
  let payload;
  try { payload = await response.json(); } catch (_) {
    throw new HttpsError('data-loss', 'UN Comtrade returned invalid JSON.');
  }
  const rows = Array.isArray(payload?.data) ? payload.data : [];
  return {
    status: 'ok',
    scope: 'global_source_with_selected_reporter',
    filters,
    count: rows.length,
    results: rows.map(normalizeTradeRecord),
    source: 'UN Comtrade preview API',
    sourceUrl: 'https://comtradeapi.un.org/',
    retrievedAt: new Date().toISOString(),
    totalRecords: Number.isFinite(Number(payload?.count)) ? Number(payload.count) : null,
    coverageNote: 'Official reported trade statistics, not a directory of individual companies. The preview API is limited in records and rate. Availability and detail vary by reporter, partner, commodity, and year; empty results do not prove no trade occurred.',
  };
}

exports.aurenSearchUNComtradeTradeData = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB'},
  async (request) => {
    if (!request.auth?.uid) throw new HttpsError('unauthenticated', 'Sign in to search global trade statistics.');
    return searchUNComtrade(request.data || {});
  },
);

module.exports.normalizeInput = normalizeInput;
module.exports.normalizeTradeRecord = normalizeTradeRecord;
module.exports.searchUNComtrade = searchUNComtrade;
