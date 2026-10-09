'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');

const WORLD_BANK_PROJECTS_API = 'https://api.worldbank.org/v2';
const COUNTRY_CODE = /^[A-Z]{2}$/;
const MAX_RESULTS = 25;

function normalizeProjectSearch(input) {
  const countryCode = String(input?.countryCode || '').trim().toUpperCase();
  const query = String(input?.query || '').trim().replace(/\\s+/g, ' ').slice(0, 120);
  const pageValue = Number(input?.page || 1);
  const limitValue = Number(input?.limit || 10);
  const page = Number.isFinite(pageValue) ? Math.max(1, Math.min(1000, Math.floor(pageValue))) : 1;
  const limit = Number.isFinite(limitValue) ? Math.max(1, Math.min(MAX_RESULTS, Math.floor(limitValue))) : 10;
  if (!COUNTRY_CODE.test(countryCode)) {
    throw new HttpsError('invalid-argument', 'countryCode must be a two-letter ISO country code.');
  }
  return {countryCode, query, page, limit};
}

function normalizeWorldBankProject(project) {
  const id = String(project?.id || '').trim();
  const name = String(project?.project_name || project?.projectname || '').trim();
  if (!id || !name) return null;
  const amount = project.totalamt ?? project.total_amount ?? null;
  const cost = project.curr_project_cost ?? project.current_project_cost ?? null;
  return {
    projectId: id,
    name,
    countryCode: String(project.countrycode || project.country_code || '').trim() || null,
    countryName: String(project.countryname || project.country_name || '').trim() || null,
    status: String(project.status || '').trim() || null,
    approvalDate: String(project.boardapprovaldate || project.approval_date || '').trim() || null,
    closingDate: String(project.closingdate || project.closing_date || '').trim() || null,
    financingAmount: amount === undefined || amount === null || amount === '' ? null : Number(amount),
    projectCost: cost === undefined || cost === null || cost === '' ? null : Number(cost),
    currency: 'USD',
    source: 'World Bank Projects & Operations',
    sourceUrl: String(project.url || project.project_url || '').trim() ||
      'https://projects.worldbank.org/en/projects-operations/project-detail/' + encodeURIComponent(id),
    verificationStatus: 'official_source_record_not_independently_verified',
    fundingNote: 'Project financing is not an open grant or direct investment offer. Check the official project page for status, eligibility, and procurement opportunities.',
  };
}

async function searchWorldBankProjects(input, fetchImpl = fetch) {
  const {countryCode, query, page, limit} = normalizeProjectSearch(input);
  const params = new URLSearchParams({
    format: 'json',
    page: String(page),
    per_page: String(Math.min(100, Math.max(limit, 25))),
  });
  const url = WORLD_BANK_PROJECTS_API + '/country/' + encodeURIComponent(countryCode) + '/projects?' + params.toString();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetchImpl(url, {
      method: 'GET',
      headers: {accept: 'application/json'},
      signal: controller.signal,
    });
    if (!response.ok) throw new HttpsError('unavailable', 'World Bank project search is temporarily unavailable.');
    const payload = await response.json();
    const meta = Array.isArray(payload) && payload[0] && typeof payload[0] === 'object' ? payload[0] : {};
    const rawProjects = Array.isArray(payload?.[1]) ? payload[1] : [];
    const normalizedQuery = query.toLocaleLowerCase();
    const results = rawProjects
      .map(normalizeWorldBankProject)
      .filter(Boolean)
      .filter((project) => !normalizedQuery ||
        (project.name + ' ' + project.projectId + ' ' + (project.status || '')).toLocaleLowerCase().includes(normalizedQuery))
      .slice(0, limit);
    return {
      status: 'ok',
      countryCode,
      query: query || null,
      page,
      pageCount: Number.isFinite(Number(meta.pages)) ? Number(meta.pages) : null,
      sourceRecordCount: Number.isFinite(Number(meta.total)) ? Number(meta.total) : null,
      count: results.length,
      results,
      source: 'World Bank Projects & Operations',
      sourceUrl: url,
      retrievedAt: new Date().toISOString(),
      coverageNote: 'This endpoint lists World Bank projects for the selected country. It is not a complete directory of all banks, investors, grants, or private funding opportunities.',
    };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', 'Could not retrieve World Bank project records. Please try again later.');
  } finally {
    clearTimeout(timeout);
  }
}

exports.aurenSearchWorldBankProjects = onCall({
  region: 'us-central1',
  timeoutSeconds: 20,
  memory: '256MiB',
}, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in to search official development projects.');
  }
  return searchWorldBankProjects(request.data || {});
});

module.exports.normalizeProjectSearch = normalizeProjectSearch;
module.exports.normalizeWorldBankProject = normalizeWorldBankProject;
module.exports.searchWorldBankProjects = searchWorldBankProjects;
