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


export async function createGroupNotifications(db, {
  actorUid,
  conversationId,
  groupTitle,
  memberIds,
  type,
  targetUid = null,
}) {
  const recipients = [...new Set((Array.isArray(memberIds) ? memberIds : [])
    .filter((uid) => typeof uid === 'string' && uid && uid !== actorUid))];
  const titles = {
    group_member_added: 'أضيفت إلى مجموعة',
    group_member_removed: 'تمت إزالتك من مجموعة',
    group_owner_changed: 'تم تغيير مالك المجموعة',
  };
  const bodies = {
    group_member_added: `تمت إضافتك إلى مجموعة «${clean(groupTitle, 120)}» في AUREN.`,
    group_member_removed: `تمت إزالتك من مجموعة «${clean(groupTitle, 120)}» في AUREN.`,
    group_owner_changed: `أصبحت مالك مجموعة «${clean(groupTitle, 120)}» في AUREN.`,
  };
  if (!titles[type] || !bodies[type]) throw new Error('Unsupported group notification type.');

  const finalRecipients = targetUid
    ? recipients.filter((uid) => uid === targetUid)
    : recipients;

  await Promise.all(finalRecipients.map((uid) => createUserNotification(db, uid, {
    type: 'group',
    title: titles[type],
    body: bodies[type],
    actorUid,
    targetId: targetUid,
    conversationId,
    dedupeId: `${type}_${conversationId}_${uid}_${Date.now()}`,
  })));
  return finalRecipients.length;
}
