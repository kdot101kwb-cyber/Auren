const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

async function notify(uid, data) {
  if (!uid || !data) return;
  await db.collection('users').doc(uid).collection('notifications').add({
    title: String(data.title || 'AUREN'),
    body: String(data.body || ''),
    read: false,
    type: String(data.type || 'system'),
    actorUid: data.actorUid || null,
    targetId: data.targetId || null,
    entityId: data.entityId || null,
    conversationId: data.conversationId || null,
    createdAt: FieldValue.serverTimestamp(),
  });
}

exports.onFollowCreated = onDocumentCreated('follows/{followId}', async (event) => {
  const follow = event.data?.data();
  if (!follow) return;
  const actorUid = follow.followerId;
  const targetUid = follow.followingId;
  if (!actorUid || !targetUid || actorUid === targetUid) return;
  await notify(targetUid, {
    title: 'New follower',
    body: 'Someone started following you.',
    type: 'follow',
    actorUid,
    targetId: targetUid,
    entityId: event.params.followId,
  });
});

exports.onPostLikeCreated = onDocumentCreated('posts/{postId}/likes/{userId}', async (event) => {
  const like = event.data?.data();
  const post = await db.collection('posts').doc(event.params.postId).get();
  const postData = post.data();
  if (!like || !postData) return;
  const actorUid = event.params.userId;
  const targetUid = postData.authorId;
  if (!actorUid || !targetUid || actorUid === targetUid) return;
  await notify(targetUid, {
    title: 'Post liked',
    body: 'Someone liked your post.',
    type: 'like',
    actorUid,
    targetId: targetUid,
    entityId: event.params.postId,
  });
});

exports.onPostCommentCreated = onDocumentCreated('posts/{postId}/comments/{commentId}', async (event) => {
  const comment = event.data?.data();
  const post = await db.collection('posts').doc(event.params.postId).get();
  const postData = post.data();
  if (!comment || !postData) return;
  const actorUid = comment.authorId;
  const targetUid = postData.authorId;
  if (!actorUid || !targetUid || actorUid === targetUid) return;
  await notify(targetUid, {
    title: 'New comment',
    body: 'Someone commented on your post.',
    type: 'comment',
    actorUid,
    targetId: targetUid,
    entityId: event.params.postId,
  });
});

exports.onConversationMessageCreated = onDocumentCreated(
  'conversations/{conversationId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message || message.isAi === true) return;
    const conversation = await db.collection('conversations').doc(event.params.conversationId).get();
    const data = conversation.data();
    if (!data || !Array.isArray(data.memberIds)) return;

    const actorUid = message.senderId;
    const recipients = data.memberIds.filter((uid) => uid && uid !== actorUid);
    await Promise.all(recipients.map((uid) => notify(uid, {
      title: data.type === 'group' ? data.title || 'Group message' : 'New message',
      body: String(message.text || '').slice(0, 140),
      type: data.type === 'group' ? 'group' : 'message',
      actorUid,
      targetId: uid,
      entityId: event.params.conversationId,
      conversationId: event.params.conversationId,
    })));
  },
);

exports.onConversationMembershipChanged = onDocumentUpdated(
  'conversations/{conversationId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || after.type !== 'group') return;

    const oldMembers = Array.isArray(before.memberIds) ? before.memberIds : [];
    const newMembers = Array.isArray(after.memberIds) ? after.memberIds : [];
    const added = newMembers.filter((uid) => !oldMembers.includes(uid));
    const removed = oldMembers.filter((uid) => !newMembers.includes(uid));
    const ownerUid = after.ownerId;

    await Promise.all([
      ...added.map((uid) => notify(uid, {
        title: 'Added to group',
        body: `You were added to ${after.title || 'a group'}.`,
        type: 'group',
        actorUid: ownerUid,
        targetId: uid,
        entityId: event.params.conversationId,
        conversationId: event.params.conversationId,
      })),
      ...removed.map((uid) => notify(uid, {
        title: 'Removed from group',
        body: `You were removed from ${after.title || 'a group'}.`,
        type: 'group',
        actorUid: ownerUid,
        targetId: uid,
        entityId: event.params.conversationId,
        conversationId: event.params.conversationId,
      })),
    ]);
  },
);
