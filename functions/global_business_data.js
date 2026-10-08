'use strict';

const {createHash} = require('node:crypto');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const TRADE_API = 'https://comtradeapi.un.org/public/v1/preview/C/A/HS';

function clean(value, max = 300) {
  return String(value ?? '').trim().slice(0, max);
}

function normalizeCountryCode(value) {
  const code = clean(value, 3).toUpperCase();
  return /^[A-Z]{2,3}$/.test(code) ? code : '';
}

/**
 * Normalize a business lead supplied by a source whose licence permits
 * storage and display in AUREN. This function deliberately does not scrape
 * websites or infer a business's importer/exporter status.
 */
function normalizeBusinessRecord(input = {}) {
  const name = clean(input.name || input.companyName, 200);
  const countryCode = normalizeCountryCode(input.countryCode);
  const source = clean(input.source, 120);
  const sourceUrl = clean(input.sourceUrl, 1000);
  const license = clean(input.license, 300);
  const businessType = clean(input.businessType || input.type, 40).toLowerCase();
  let parsedSourceUrl;
  try { parsedSourceUrl = new URL(sourceUrl); } catch (_) { parsedSourceUrl = null; }
  const allowedTypes = new Set(['supplier', 'exporter', 'importer', 'manufacturer']);
  if (!name || !countryCode || !source || !parsedSourceUrl || parsedSourceUrl.protocol !== 'https:' || !license || !allowedTypes.has(businessType)) {
    throw new HttpsError('invalid-argument',
      'Business records require name, countryCode, businessType, source, sourceUrl, and license.');
  }

  return {
    name,
    normalizedName: name.toLocaleLowerCase(),
    countryCode,
    city: clean(input.city, 120),
    businessType,
    products: Array.isArray(input.products)
      ? [...new Set(input.products.map((item) => clean(item, 100)).filter(Boolean))].slice(0, 30)
      : [],
    website: clean(input.website, 1000),
    publicEmail: clean(input.publicEmail || input.email, 254),
    publicPhone: clean(input.publicPhone || input.phone, 60),
    source,
    sourceUrl,
    sourceLicense: license,
    sourceRecordId: clean(input.sourceRecordId, 200),
    verificationStatus: input.verificationStatus === 'verified' ? 'verified' : 'unverified',
    lastCheckedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

function normalizeTradeObservation(row = {}, params = {}) {
  const reporterCode = clean(row.reporterCode || params.reporterCode, 3);
  const partnerCode = clean(row.partnerCode || params.partnerCode, 3);
  const cmdCode = clean(row.cmdCode || params.cmdCode || 'TOTAL', 20);
  const flowCode = clean(row.flowCode || params.flowCode, 1).toUpperCase();
  const period = clean(row.period || params.period, 4);
  const tradeValue = Number(row.primaryValue ?? row.TradeValue ?? row.tradeValue);
  if (!reporterCode || !partnerCode || !/^[0-9]{4}$/.test(period) ||
      !['X', 'M', ' re-export '.trim()].includes(flowCode) ||
      !Number.isFinite(tradeValue) || tradeValue < 0) return null;
  return {
    reporterCode,
    partnerCode,
    cmdCode,
    flowCode,
    period,
    tradeValue,
    netWgt: Number.isFinite(Number(row.netWgt)) ? Number(row.netWgt) : null,
    qty: Number.isFinite(Number(row.qty)) ? Number(row.qty) : null,
    source: 'UN Comtrade',
    sourceUrl: 'https://comtradeapi.un.org/',
    dataKind: 'aggregate_trade_statistics',
    isCompanyLead: false,
    importedAt: FieldValue.serverTimestamp(),
  };
}

exports.ingestGlobalTradeStatistics = onCall({region: 'us-central1', timeoutSeconds: 60, memory: '256MiB'}, async (request) => {
  if (!request.auth || request.auth.token?.admin !== true) {
    throw new HttpsError('permission-denied', 'Administrator access is required.');
  }
  const reporterCode = clean(request.data?.reporterCode || '729', 3);
  const period = clean(request.data?.period || String(new Date().getUTCFullYear() - 2), 4);
  const flowCode = clean(request.data?.flowCode || 'X', 1).toUpperCase();
  const cmdCode = clean(request.data?.cmdCode || 'TOTAL', 20);
  const partnerCode = clean(request.data?.partnerCode || '0', 3);
  if (!/^\d{1,3}$/.test(reporterCode) || !/^\d{4}$/.test(period) ||
      !/^(?:\\d{1,6}|TOTAL)$/.test(cmdCode) ||
      !/^\d{1,3}$/.test(partnerCode)) {
    throw new HttpsError('invalid-argument', 'Invalid UN Comtrade query parameters.');
  }

  const url = new URL(TRADE_API);
  url.search = new URLSearchParams({
    flowCode, reporterCode, period, cmdCode, partnerCode, maxRecords: '500',
  }).toString();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 20000);
  let response;
  try {
    response = await fetch(url, {signal: controller.signal, headers: {'user-agent': 'AUREN-Global-Business-Data/1.0'}});
  } catch (error) {
    throw new HttpsError('unavailable', 'UN Comtrade request failed or timed out.');
  } finally {
    clearTimeout(timer);
  }
  if (!response.ok) throw new HttpsError('unavailable', 'UN Comtrade returned HTTP ' + response.status + '.');
  const body = await response.json();
  const rows = Array.isArray(body.data) ? body.data : [];
  const db = getFirestore();
  let imported = 0;
  const rejected = [];
  for (let i = 0; i < rows.length; i += 400) {
    const batch = db.batch();
    let pageImported = 0;
    for (const row of rows.slice(i, i + 400)) {
      const normalized = normalizeTradeObservation(row, {reporterCode, partnerCode, period, flowCode, cmdCode});
      if (!normalized) {
        rejected.push(1);
        continue;
      }
      const id = [normalized.reporterCode, normalized.partnerCode, normalized.cmdCode,
        normalized.flowCode, normalized.period].join('_');
      batch.set(db.collection('auren_trade_statistics').doc(id), {
        ...normalized,
        importedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      imported++;
      pageImported++;
    }
    if (pageImported) await batch.commit();
  }
  await db.collection('auren_data_ingestion_runs').add({
    source: 'UN Comtrade',
    dataKind: 'aggregate_trade_statistics',
    parameters: {reporterCode, period, flowCode, cmdCode, partnerCode},
    fetchedRows: rows.length,
    importedRows: imported,
    rejectedRows: rejected.length,
    status: 'completed',
    completedAt: FieldValue.serverTimestamp(),
  });
  return {
    source: 'UN Comtrade',
    dataKind: 'aggregate_trade_statistics',
    fetchedRows: rows.length,
    importedRows: imported,
    rejectedRows: rejected.length,
    collection: 'auren_trade_statistics',
    note: 'These are aggregate trade statistics, not named importer/exporter companies or verified supplier leads.',
  };
});

exports.importLicensedBusinessRecords = onCall({region: 'us-central1', timeoutSeconds: 60, memory: '256MiB'}, async (request) => {
  if (!request.auth || request.auth.token?.admin !== true) {
    throw new HttpsError('permission-denied', 'Administrator access is required.');
  }
  const records = request.data?.records;
  if (!Array.isArray(records) || records.length === 0 || records.length > 200) {
    throw new HttpsError('invalid-argument', 'Provide between 1 and 200 licensed business records.');
  }
  const db = getFirestore();
  const batch = db.batch();
  const collectionByType = {
    supplier: 'auren_suppliers',
    exporter: 'auren_exporters',
    importer: 'auren_importers',
    manufacturer: 'auren_manufacturers',
  };
  let imported = 0;
  const rejected = [];
  records.forEach((input, index) => {
    try {
      const record = normalizeBusinessRecord(input);
      const sourceIdentity = record.sourceRecordId ||
        createHash('sha256').update([record.countryCode, record.normalizedName, record.source].join('|')).digest('hex').slice(0, 40);
      const ref = db.collection(collectionByType[record.businessType]).doc(sourceIdentity);
      batch.set(ref, record, {merge: true});
      imported++;
    } catch (error) {
      rejected.push({index, reason: error.code === 'invalid-argument' ? 'invalid_record_or_missing_provenance' : 'normalization_failed'});
    }
  });
  if (imported) await batch.commit();
  await db.collection('auren_data_ingestion_runs').add({
    source: 'licensed_business_record_import',
    dataKind: 'named_business_records',
    fetchedRows: records.length,
    importedRows: imported,
    rejectedRows: rejected.length,
    status: 'completed',
    completedAt: FieldValue.serverTimestamp(),
  });
  return {
    importedRows: imported,
    rejectedRows: rejected.length,
    rejected,
    collections: [...new Set(records.filter((row) => collectionByType[clean(row?.businessType || row?.type, 40).toLowerCase()])
      .map((row) => collectionByType[clean(row?.businessType || row?.type, 40).toLowerCase()]))],
    note: 'Only records with an explicit HTTPS source and licence/provenance are accepted. Importer/exporter status is not inferred.',
  };
});

module.exports.normalizeBusinessRecord = normalizeBusinessRecord;
module.exports.normalizeTradeObservation = normalizeTradeObservation;
