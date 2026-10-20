'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {
  MAX_TITLE,
  MAX_TEXT,
  clean,
  required,
  safeUrls,
  boundedUniqueStrings,
  normalizeQueueStatus,
  normalizePriority,
  normalizeEvidenceVerdict,
} = require('./knowledge_information_validation');

const db = getFirestore();

function requireUid(request) {
  const uid = String(request.auth?.uid || '').trim();
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  return uid;
}
function userCollection(uid, name) {
  return db.collection('users').doc(uid).collection(name);
}
async function listUserItems(uid, name) {
  const snapshot = await userCollection(uid, name).orderBy('updatedAt', 'desc').limit(50).get();
  return {items: snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}))};
}

// 1. Knowledge Inbox: capture a note or URL with provenance for later review.
exports.captureAurenKnowledgeItem = onCall({region: 'us-central1'}, async (request) => {
  const uid = requireUid(request);
  if (request.data?.action === 'list') return listUserItems(uid, 'knowledgeInbox');
  const title = required(request.data?.title, 'title', MAX_TITLE);
  const body = clean(request.data?.body, MAX_TEXT);
  const sourceUrl = safeUrls([request.data?.sourceUrl])[0] || '';
  if (!body && !sourceUrl) throw new HttpsError('invalid-argument', 'Provide body text or a valid HTTP(S) source URL.');
  const ref = userCollection(uid, 'knowledgeInbox').doc();
  await ref.set({
    title, body, sourceUrl, tags: boundedUniqueStrings(request.data?.tags, 12, 40),
    status: 'inbox', capturedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(), schemaVersion: 1,
  });
  return {id: ref.id, status: 'saved'};
});

// 2. Evidence Vault: keep a claim separate from the sources that support or dispute it.
exports.saveAurenEvidenceRecord = onCall({region: 'us-central1'}, async (request) => {
  const uid = requireUid(request);
  if (request.data?.action === 'list') return listUserItems(uid, 'evidenceVault');
  const claim = required(request.data?.claim, 'claim', 1200);
  const sources = safeUrls(request.data?.sourceUrls);
  if (!sources.length) throw new HttpsError('invalid-argument', 'At least one valid source URL is required.');
  const verdict = normalizeEvidenceVerdict(request.data?.verdict);
  const ref = userCollection(uid, 'evidenceVault').doc();
  await ref.set({claim, sourceUrls: sources, verdict, notes: clean(request.data?.notes, 3000),
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), schemaVersion: 1});
  return {id: ref.id, verdict};
});

// 3. Source Provenance: save a source profile without claiming that its trustworthiness is verified.
exports.saveAurenSourceProfile = onCall({region: 'us-central1'}, async (request) => {
  const uid = requireUid(request);
  if (request.data?.action === 'list') return listUserItems(uid, 'sourceProfiles');
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
  if (request.data?.action === 'list') return listUserItems(uid, 'researchReadingQueue');
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
  const status = normalizeQueueStatus(request.data?.status);
  const ref = id && !id.includes('/') ? userCollection(uid, 'researchReadingQueue').doc(id) : userCollection(uid, 'researchReadingQueue').doc();
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(ref);
    const payload = {
      title,
      url,
      status,
      priority: normalizePriority(request.data?.priority),
      notes: clean(request.data?.notes, 2000),
      updatedAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    };
    // Preserve the original creation time when an existing queue item is edited.
    if (!existing.exists) payload.createdAt = FieldValue.serverTimestamp();
    transaction.set(ref, payload, {merge: true});
  });
  return {id: ref.id, status};
});

// 5. Language Bridge Glossary: retain user-curated terms and context across languages.
exports.saveAurenGlossaryEntry = onCall({region: 'us-central1'}, async (request) => {
  const uid = requireUid(request);
  if (request.data?.action === 'list') return listUserItems(uid, 'languageGlossary');
  const sourceTerm = required(request.data?.sourceTerm, 'sourceTerm', 240);
  const translatedTerm = required(request.data?.translatedTerm, 'translatedTerm', 240);
  const sourceLanguage = required(request.data?.sourceLanguage, 'sourceLanguage', 24);
  const targetLanguage = required(request.data?.targetLanguage, 'targetLanguage', 24);
  const ref = userCollection(uid, 'languageGlossary').doc();
  await ref.set({sourceTerm, translatedTerm, sourceLanguage, targetLanguage,
    context: clean(request.data?.context, 1200), alternatives: boundedUniqueStrings(request.data?.alternatives, 8, 240),
    createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), schemaVersion: 1});
  return {id: ref.id, status: 'saved'};
});

exports._knowledgeInformationTestHelpers = {clean, safeUrls};
