'use strict';

const admin = require('firebase-admin');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {normalizeGroupSelection, hasBlockedPair} = require('./random_group_matching_logic');

const db = admin.firestore();
const groups = db.collection('random_groups');
const requests = db.collection('random_group_connect');
const conversations = db.collection('conversations');
const MAX_GROUP_SIZE = 8;
const MIN_GROUP_SIZE = 3;

function clean(value, max = 128) {
  return typeof value === 'string' ? value.trim().slice(0, max) : '';
}

function requireUid(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in to use random groups.');
  return uid;
}

function validateSize(value) {
  if (!Number.isInteger(value) || value < MIN_GROUP_SIZE || value > MAX_GROUP_SIZE) {
    throw new HttpsError('invalid-argument', 'Group size must be an integer from 3 to 8.');
  }
}

async function readBlockedPairs(tx, memberUids) {
  const refs = [];
  for (const uid of memberUids) {
    for (const otherUid of memberUids) {
      if (uid !== otherUid) {
        refs.push({uid, blockedUid: otherUid, ref: db.collection('users').doc(uid).collection('blocked').doc(otherUid)});
      }
    }
  }
  const snaps = await Promise.all(refs.map((item) => tx.get(item.ref)));
  const existingBlocks = snaps.map((snap, index) => snap.exists ? refs[index] : null).filter(Boolean);
  return hasBlockedPair(memberUids, existingBlocks);
}

exports.listAurenRandomGroupCandidates = onCall(
  {region: 'us-central1', timeoutSeconds: 20, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = requireUid(request);
    const requestId = clean(request.data?.requestId);
    const groupSize = request.data?.groupSize;
    validateSize(groupSize);
    if (!requestId) throw new HttpsError('invalid-argument', 'requestId is required.');

    const ownSnap = await requests.doc(requestId).get();
    const own = ownSnap.data();
    if (!ownSnap.exists || own?.uid !== uid || own?.status !== 'waiting' ||
        own?.groupSize !== groupSize || !clean(own?.language, 40)) {
      throw new HttpsError('failed-precondition', 'Your waiting request is not available.');
    }
    // Never trust the caller-supplied language: derive it from the owner's
    // private waiting request so clients cannot query candidates across languages.
    const language = clean(own.language, 40);

    const snap = await requests.where('status', '==', 'waiting')
      .where('groupSize', '==', groupSize).limit(40).get();
    const candidates = await Promise.all(snap.docs.map(async (doc) => {
      const data = doc.data();
      const candidateUid = clean(data.uid);
      if (candidateUid === uid || !candidateUid ||
          (language && clean(data.language, 40) !== language)) return null;
      const [blockedByCaller, blockedCaller] = await Promise.all([
        db.collection('users').doc(uid).collection('blocked').doc(candidateUid).get(),
        db.collection('users').doc(candidateUid).collection('blocked').doc(uid).get(),
      ]);
      if (blockedByCaller.exists || blockedCaller.exists) return null;
      return {
        candidateUid,
        requestId: doc.id,
        country: clean(data.country, 80),
        language: clean(data.language, 40),
        interest: clean(data.interest, 120),
        goal: clean(data.goal, 160),
      };
    }));
    // A user may have stale duplicate waiting requests. Never show them as
    // multiple people or let duplicate requests make a group selection fail.
    const seenUids = new Set();
    const uniqueCandidates = candidates.filter((candidate) => {
      if (!candidate || seenUids.has(candidate.candidateUid)) return false;
      seenUids.add(candidate.candidateUid);
      return true;
    }).slice(0, 30).map(({candidateUid, ...candidate}) => candidate);
    return {candidates: uniqueCandidates};
  },
);

exports.formAurenRandomGroup = onCall(
  {region: 'us-central1', timeoutSeconds: 30, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = requireUid(request);
    const ownRequestId = clean(request.data?.requestId);
    const candidateRequestIds = request.data?.candidateRequestIds;
    const groupSize = request.data?.groupSize;
    validateSize(groupSize);
    let requestIds;
    try {
      requestIds = normalizeGroupSelection({ownRequestId, candidateRequestIds, groupSize});
    } catch (error) {
      throw new HttpsError(error.code || 'invalid-argument', error.message);
    }
    const requestRefs = requestIds.map((id) => requests.doc(id));
    const groupRef = groups.doc();
    const created = await db.runTransaction(async (tx) => {
      const snapshots = await Promise.all(requestRefs.map((ref) => tx.get(ref)));
      const data = snapshots.map((snap) => snap.data());
      if (snapshots.some((snap) => !snap.exists)) {
        throw new HttpsError('failed-precondition', 'A selected request is no longer available.');
      }
      if (data[0]?.uid !== uid || data[0]?.status !== 'waiting' || data[0]?.groupSize !== groupSize) {
        throw new HttpsError('failed-precondition', 'Your waiting request is not available.');
      }
      const memberUids = data.map((item) => item?.uid);
      if (memberUids.some((member) => typeof member !== 'string' || !member) ||
          new Set(memberUids).size !== groupSize || memberUids.slice(1).includes(uid)) {
        throw new HttpsError('failed-precondition', 'Selected requests do not represent unique members.');
      }
      if (data.some((item) => item?.status !== 'waiting' || item?.groupSize !== groupSize)) {
        throw new HttpsError('failed-precondition', 'A selected request has already been claimed.');
      }
      if (await readBlockedPairs(tx, memberUids)) {
        throw new HttpsError('failed-precondition', 'A selected member has blocked another group member.');
      }

      tx.create(groupRef, {
        memberUids,
        size: groupSize,
        status: 'active',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      for (const ref of requestRefs) {
        tx.update(ref, {
          status: 'grouped',
          groupId: groupRef.id,
          matchedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      return {groupId: groupRef.id, memberUids};
    });
    return {groupId: created.groupId, memberCount: created.memberUids.length};
  },
);

exports.createAurenRandomGroupConversation = onCall(
  {region: 'us-central1', timeoutSeconds: 30, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = requireUid(request);
    const groupId = clean(request.data?.groupId);
    const title = clean(request.data?.title, 100);
    if (!groupId || !title) throw new HttpsError('invalid-argument', 'groupId and title are required.');
    const groupRef = groups.doc(groupId);
    const conversationRef = conversations.doc();
    return db.runTransaction(async (tx) => {
      const groupSnap = await tx.get(groupRef);
      const group = groupSnap.data();
      if (!groupSnap.exists || !group || group.status !== 'active' ||
          !Array.isArray(group.memberUids) || !group.memberUids.includes(uid)) {
        throw new HttpsError('permission-denied', 'Only active group members can create its chat.');
      }
      const existingId = clean(group.conversationId);
      if (existingId) return {conversationId: existingId};
      if (await readBlockedPairs(tx, group.memberUids)) {
        throw new HttpsError('failed-precondition', 'A group member has blocked another member.');
      }
      const now = admin.firestore.FieldValue.serverTimestamp();
      tx.create(conversationRef, {
        memberIds: group.memberUids,
        title,
        isAi: false,
        updatedAt: now,
        type: 'group',
        ownerId: uid,
        lastMessage: '',
        lastMessageAt: now,
        lastMessageSenderId: uid,
      });
      tx.update(groupRef, {conversationId: conversationRef.id, chatReady: true});
      return {conversationId: conversationRef.id};
    });
  },
);
