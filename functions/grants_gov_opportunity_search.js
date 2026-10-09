'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');

const GRANTS_GOV_SEARCH_URL = 'https://api.grants.gov/v1/api/search2';
const MAX_ROWS = 25;
const ALLOWED_STATUSES = new Set(['posted', 'forecasted', 'closed', 'archived']);

function normalizeGrantSearch(input) {
  const keyword = String(input?.keyword || '').trim().replace(/\s+/g, ' ').slice(0, 120);
  const rowsValue = Number(input?.rows || 10);
  const startValue = Number(input?.startRecordNum || 0);
  const rows = Number.isFinite(rowsValue) ? Math.max(1, Math.min(MAX_ROWS, Math.floor(rowsValue))) : 10;
  const startRecordNum = Number.isFinite(startValue) ? Math.max(0, Math.min(100000, Math.floor(startValue))) : 0;
  const rawStatuses = Array.isArray(input?.oppStatuses)
    ? input.oppStatuses
    : String(input?.oppStatuses || 'posted|forecasted').split('|');
  const oppStatuses = [...new Set(rawStatuses.map((s) => String(s).trim().toLowerCase()).filter((s) => ALLOWED_STATUSES.has(s)))];
  if (keyword.length < 2) {
    throw new HttpsError('invalid-argument', 'Enter a funding keyword with at least 2 characters.');
  }
  if (!oppStatuses.length) {
    throw new HttpsError('invalid-argument', 'Select at least one supported opportunity status.');
  }
  return {keyword, rows, startRecordNum, oppStatuses: oppStatuses.join('|')};
}

function normalizeGrantOpportunity(item) {
  const id = String(item?.id || '').trim();
  const title = String(item?.title || '').trim();
  if (!id || !title) return null;
  const number = String(item.number || '').trim();
  const rawStatus = String(item.oppStatus || '').trim().toLowerCase();
  const closeDate = String(item.closeDate || '').trim() || null;
  return {
    opportunityId: id,
    opportunityNumber: number || null,
    title,
    agencyCode: String(item.agencyCode || '').trim() || null,
    agencyName: String(item.agencyName || '').trim() || null,
    openDate: String(item.openDate || '').trim() || null,
    closeDate,
    status: ALLOWED_STATUSES.has(rawStatus) ? rawStatus : 'unknown',
    fundingCategoryCodes: Array.isArray(item.fundingCategories) ? item.fundingCategories : [],
    source: 'Grants.gov',
    sourceUrl: number
      ? 'https://www.grants.gov/search-results-detail/' + encodeURIComponent(number)
      : 'https://www.grants.gov/search-grants',
    eligibilityNote: 'Confirm applicant eligibility, geography, deadlines, and award conditions on the official opportunity page. This source covers US federal grant opportunities, not global grants.',
    verificationStatus: 'official_listing_not_independently_verified',
  };
}

async function searchGrantsGov(input, fetchImpl = fetch) {
  const params = normalizeGrantSearch(input);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetchImpl(GRANTS_GOV_SEARCH_URL, {
      method: 'POST',
      headers: {'content-type': 'application/json', accept: 'application/json'},
      body: JSON.stringify({...params, eligibilities: '', agencies: '', aln: '', fundingCategories: ''}),
      signal: controller.signal,
    });
    if (!response.ok) throw new HttpsError('unavailable', 'Grants.gov search is temporarily unavailable.');
    const payload = await response.json();
    if (Number(payload?.errorcode || 0) !== 0) {
      throw new HttpsError('unavailable', 'Grants.gov did not return a successful search response.');
    }
    const data = payload?.data || {};
    const hits = Array.isArray(data.oppHits) ? data.oppHits : [];
    const results = hits.map(normalizeGrantOpportunity).filter(Boolean);
    return {
      status: 'ok',
      keyword: params.keyword,
      requestedStatuses: params.oppStatuses.split('|'),
      startRecordNum: params.startRecordNum,
      count: results.length,
      totalMatches: Number.isFinite(Number(data.hitCount)) ? Number(data.hitCount) : null,
      results,
      source: 'Grants.gov',
      sourceUrl: 'https://www.grants.gov/search-grants',
      retrievedAt: new Date().toISOString(),
      coverageNote: 'Grants.gov lists US federal opportunities only. A listing does not guarantee eligibility, award, or availability to applicants outside the United States.',
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', 'Could not retrieve Grants.gov opportunities. Please try again later.');
  } finally {
    clearTimeout(timeout);
  }
}

exports.aurenSearchGrantsGovOpportunities = onCall({
  region: 'us-central1',
  timeoutSeconds: 20,
  memory: '256MiB',
}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in to search funding opportunities.');
  }
  return searchGrantsGov(request.data || {});
});

module.exports.normalizeGrantSearch = normalizeGrantSearch;
module.exports.normalizeGrantOpportunity = normalizeGrantOpportunity;
module.exports.searchGrantsGov = searchGrantsGov;
