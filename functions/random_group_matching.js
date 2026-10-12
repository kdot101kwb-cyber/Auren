'use strict';

const admin = require('firebase-admin');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {validateRequestIds, validateWaitingRequests} = require('./random_group_matching_core');
const db = admin.firestore();
const REGION = 'us-central1';
const MAX_CANDIDATES = 40;

function requireUid(request) {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Authentication is required.');
  return uid;
}

function blockedRef(ownerUid, otherUid) {
  return db.collection('users').doc(ownerUid).collection('blocked').doc(otherUid);
}

async function hasAnyBlock(tx, uids) {
  const refs = [];
  for (let i = 0; i < uids.length; i++) {
    for (let j = i + 1; j < uids.length; j++) {
      refs.push(blockedRef(uids[i], uids[j]), blockedRef(uids[j], uids[i]));
    }
  }
  const snapshots = await Promise.all(refs.map((ref) => tx.get(ref)));
  return snapshots.some((snap) => snap.exists);
}

exports.listAurenRandomGroupCandidates = onCall(
  {region: REGION, timeoutSeconds: 20, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = requireUid(request);
    const groupSize = Number(request.data?.groupSize);
    if (!Number.isInteger(groupSize) || groupSize < 3 || groupSize > 8) {
      throw new HttpsError('invalid-argument', 'groupSize must be between 3 and 8.');
    }
    const language = String(request.data?.language || '').trim().slice(0, 60).toLocaleLowerCase();
    const snap = await db.collection('random_group_connect')
      .where('status', '==', 'waiting').limit(160).get();
    const candidates = snap.docs
      .filter((doc) => {
        const data = doc.data() || {};
        return data.uid !== uid && data.groupSize === groupSize &&
          (!language || String(data.language || '').trim().toLocaleLowerCase() === language);
      })
      .slice(0, MAX_CANDIDATES)
      .map((doc) => {
        const data = doc.data() || {};
        return {
          id: doc.id,
          groupSize: data.groupSize,
          country: String(data.country || '').slice(0, 80),
          language: String(data.language || '').slice(0, 60),
          interest: String(data.interest || '').slice(0, 120),
        };
      });
    return {candidates};
  },
);

exports.formAurenRandomGroup = onCall(
  {region: REGION, timeoutSeconds: 30, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = requireUid(request);
    let requestIds;
    try {
      requestIds = validateRequestIds(request.data?.requestIds);
    } catch (error) {
      throw new HttpsError('invalid-argument', error.message);
    }
    const requestRefs = requestIds.map((id) => db.collection('random_group_connect').doc(id));
    const groupRef = db.collection('random_groups').doc();
    try {
      const groupId = await db.runTransaction(async (tx) => {
        const requestSnaps = await Promise.all(requestRefs.map((ref) => tx.get(ref)));
        if (requestSnaps.some((snap) => !snap.exists)) {
          throw new HttpsError('failed-precondition', 'One or more selected requests are no longer available.');
        }
        const rows = requestSnaps.map((snap) => snap.data() || {});
        const ownIndex = rows.findIndex((row) => row.uid === uid);
        if (ownIndex < 0) throw new HttpsError('permission-denied', 'Your own waiting request must be included.');
        const expectedSize = rows[ownIndex].groupSize;
        let memberUids;
        try {
          memberUids = validateWaitingRequests(rows, uid, expectedSize);
        } catch (error) {
          throw new HttpsError('failed-precondition', error.message);
        }
        if (rows.some((row) => row.uid === uid && row.status !== 'waiting')) {
          throw new HttpsError('failed-precondition', 'Your request is no longer waiting.');
        }
        if (await hasAnyBlock(tx, memberUids)) {
          throw new HttpsError('failed-precondition', 'The selected group cannot be formed because a block exists between members.');
        }
        tx.create(groupRef, {
          memberUids,
          size: memberUids.length,
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
        return groupRef.id;
      });
      return {groupId};
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      throw new HttpsError('aborted', 'The group could not be formed. Refresh the candidates and try again.');
    }
  },
);

exports.createAurenRandomGroupConversation = onCall(
  {region: REGION, timeoutSeconds: 30, memory: '256MiB', enforceAppCheck: true},
  async (request) => {
    const uid = requireUid(request);
    const groupId = String(request.data?.groupId || '').trim();
    const title = String(request.data?.title || 'AUREN Random Group').trim().slice(0, 120);
    if (!groupId || groupId.length > 128 || !title) {
      throw new HttpsError('invalid-argument', 'A valid groupId and title are required.');
    }
    const groupRef = db.collection('random_groups').doc(groupId);
    return db.runTransaction(async (tx) => {
      const groupSnap = await tx.get(groupRef);
      if (!groupSnap.exists) throw new HttpsError('not-found', 'Group not found.');
      const group = groupSnap.data() || {};
      const members = Array.isArray(group.memberUids) ? group.memberUids : [];
      if (!members.includes(uid)) throw new HttpsError('permission-denied', 'Only a group member can open this chat.');
      if (group.conversationId && group.chatReady === true) return {conversationId: group.conversationId};
      if (await hasAnyBlock(tx, members)) {
        throw new HttpsError('failed-precondition', 'A group member has blocked another member. The chat cannot be opened.');
      }
      const conversationRef = db.collection('conversations').doc();
      tx.create(conversationRef, {
        memberIds: members,
        title,
        isAi: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: '',
        lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
        lastMessageSenderId: uid,
        type: 'group',
        ownerId: uid,
      });
      tx.update(groupRef, {conversationId: conversationRef.id, chatReady: true});
      return {conversationId: conversationRef.id};
    });
  },
);
