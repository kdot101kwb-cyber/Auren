import { FieldValue } from 'firebase-admin/firestore';

function clean(value, max) {
  return typeof value === 'string' ? value.trim().slice(0, max) : '';
}

export async function createUserNotification(db, uid, {
  type = 'general',
  title,
  body,
  actorUid = null,
  targetId = null,
  entityId = null,
  conversationId = null,
  dedupeId = null,
} = {}) {
  if (!uid || typeof uid !== 'string') throw new Error('Notification recipient is required.');
  const safeTitle = clean(title, 120);
  const safeBody = clean(body, 1000);
  if (!safeTitle || !safeBody) throw new Error('Notification title and body are required.');
  const id = clean(dedupeId, 180) || db.collection('_').doc().id;
  const ref = db.collection('users').doc(uid).collection('notifications').doc(id);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) return;
    tx.create(ref, {
      type: clean(type, 40) || 'general',
      title: safeTitle,
      body: safeBody,
      actorUid: clean(actorUid, 128) || null,
      targetId: clean(targetId, 180) || null,
      entityId: clean(entityId, 180) || null,
      conversationId: clean(conversationId, 180) || null,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return ref.id;
}

export async function createMessageNotifications(db, {
  senderUid,
  conversationId,
  messageId,
  text,
  memberIds,
}) {
  const recipients = [...new Set((Array.isArray(memberIds) ? memberIds : [])
    .filter((uid) => typeof uid === 'string' && uid && uid !== senderUid))];
  const preview = clean(text, 120);
  await Promise.all(recipients.map((uid) => createUserNotification(db, uid, {
    type: 'message',
    title: 'رسالة جديدة',
    body: preview || 'لديك رسالة جديدة في AUREN Messenger.',
    actorUid: senderUid,
    targetId: messageId,
    conversationId,
    dedupeId: `message_${messageId}_${uid}`,
  })));
  return recipients.length;
}
