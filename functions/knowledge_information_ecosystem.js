'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');

const db = getFirestore();
const MAX_TITLE = 180;
const MAX_TEXT = 6000;
const MAX_URLS = 12;

function requireUid(request) {
  const uid = String(request.auth?.uid || '').trim();
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  return uid;
}
function clean(value, max = MAX_TEXT) {
  return String(value ?? '').replace(/\\s+/g, ' ').trim().slice(0, max);
}
function required(value, label, max = MAX_TEXT) {
  const result = clean(value, max);
  if (!result) throw new HttpsError('invalid-argument', label + ' is required.');
  return result;
}
function safeUrls(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.slice(0, MAX_URLS).map((item) => {
    const raw = clean(item, 2000);
    try {
      const url = new URL(raw);
      if (!['https:', 'http:'].includes(url.protocol)) return '';
      if (url.username || url.password) return '';
      return url.toString();
    } catch (_) { return ''; }
  }).filter(Boolean))];
}
function userCollection(uid, name) {
  return db.collection('users').doc(uid).collection(name);
}

// 1. Knowledge Inbox: capture a note or URL with provenance for later review.
exports.captureAurenKnowledgeItem = onCall({region: 'us-central1'}, async (request) => {
  const uid = requireUid(request);
  const title = required(request.data?.title, 'title', MAX_TITLE);
  const body = clean(request.data?.body, MAX_TEXT);
  const sourceUrl = safeUrls([request.data?.sourceUrl])[0] || '';
  if (!body && !sourceUrl) throw new HttpsError('invalid-argument', 'Provide body text or a valid HTTP(S) source URL.');
  const ref = userCollection(uid, 'knowledgeInbox').doc();
  await ref.set({
    title, body, sourceUrl, tags: Array.isArray(request.data?.tags)
      ? [...new Set(request.data.tags.map((tag) => clean(tag, 40)).filter(Boolean))].slice(0, 12) : [],
    status: 'inbox', capturedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(), schemaVersion: 1,
  });
  return {id: ref.id, status: 'saved'};
});

// 2. Evidence Vault: keep a claim separate from the sources that support or dispute it.
exports.saveAurenEvidenceRecord = onCall({region: 'us-central1'}, async (request) => {
  const uid = requireUid(request);
  const claim = required(request.data?.claim, 'claim', 1200);
  const sources = safeUrls(request.data?.sourceUrls);
  if (!sources.length) throw new HttpsError('invalid-argument', 'At least one valid source URL is required.');
  const verdict = ['unverified', 'supported', 'disputed', 'mixed'].includes(request.data?.verdict)
    ? request.data.verdict : 'unverified';
  const ref = userCollection(uid, 'evidenceVault').doc();
  await ref.set({claim, sourceUrls: sources, verdict, notes: clean(request.data?.notes, 3000),
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), schemaVersion: 1});
  return {id: ref.id, verdict};
});

// 3. Source Provenance: save a source profile without claiming that its trustworthiness is verified.
exports.saveAurenSourceProfile = onCall({region: 'us-central1'}, async (request) => {
  const uid = requireUid(request);
  const url = safeUrls([request.data?.url])[0];
  if (!url) throw new HttpsError('invalid-argument', 'A valid HTTP(S) source URL is required.');
  const label = required(request.data?.label || new URL(url).hostname, 'label', MAX_TITLE);
  const sourceType = ['official', 'journal', 'news', 'academic', 'community', 'other'].includes(request.data?.sourceType)
    ? request.data.sourceType : 'other';
  const ref = userCollection(uid, 'sourceProfiles').doc();
  await ref.set({url, label, sourceType, ownerOrPublisher: clean(request.data?.ownerOrPublisher, MAX_TITLE),
    verificationStatus: 'not_checked', userNotes: clean(request.data?.notes, 1500),
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), schemaVersion: 1});
  return {id: ref.id, verificationStatus: 'not_checked'};
});

// 4. Research Reading Queue: organize sources by priority and progress.
exports.upsertAurenReadingQueueItem = onCall({region: 'us-central1'}, async (request) => {
  const uid = requireUid(request);
  const action = request.data?.action === 'remove' ? 'remove' : 'save';
  const id = clean(request.data?.id, 128);
  if (action === 'remove') {
    if (!id || id.includes('/')) throw new HttpsError('invalid-argument', 'A valid item id is required.');
    await userCollection(uid, 'researchReadingQueue').doc(id).delete();
    return {id, status: 'removed'};
  }
  const title = required(request.data?.title, 'title', MAX_TITLE);
  const url = safeUrls([request.data?.url])[0] || '';
  if (!url) throw new HttpsError('invalid-argument', 'A valid HTTP(S) URL is required.');
  const status = ['to_read', 'reading', 'read'].includes(request.data?.status) ? request.data.status : 'to_read';
  const ref = id && !id.includes('/') ? userCollection(uid, 'researchReadingQueue').doc(id) : userCollection(uid, 'researchReadingQueue').doc();
  await ref.set({title, url, status, priority: ['low', 'normal', 'high'].includes(request.data?.priority) ? request.data.priority : 'normal',
    notes: clean(request.data?.notes, 2000), updatedAt: FieldValue.serverTimestamp(),
    createdAt: FieldValue.serverTimestamp(), schemaVersion: 1}, {merge: true});
  return {id: ref.id, status};
});

// 5. Language Bridge Glossary: retain user-curated terms and context across languages.
exports.saveAurenGlossaryEntry = onCall({region: 'us-central1'}, async (request) => {
  const uid = requireUid(request);
  const sourceTerm = required(request.data?.sourceTerm, 'sourceTerm', 240);
  const translatedTerm = required(request.data?.translatedTerm, 'translatedTerm', 240);
  const sourceLanguage = required(request.data?.sourceLanguage, 'sourceLanguage', 24);
  const targetLanguage = required(request.data?.targetLanguage, 'targetLanguage', 24);
  const ref = userCollection(uid, 'languageGlossary').doc();
  await ref.set({sourceTerm, translatedTerm, sourceLanguage, targetLanguage,
    context: clean(request.data?.context, 1200), alternatives: Array.isArray(request.data?.alternatives)
      ? [...new Set(request.data.alternatives.map((v) => clean(v, 240)).filter(Boolean))].slice(0, 8) : [],
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), schemaVersion: 1});
  return {id: ref.id, status: 'saved'};
});

exports._knowledgeInformationTestHelpers = {clean, safeUrls};
