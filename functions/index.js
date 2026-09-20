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


exports.aurenAiGateway = require('firebase-functions/v2/https').onCall(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB' },
  async (request) => {
    if (!request.auth?.uid) {
      throw new Error('Unauthenticated');
    }

    const data = request.data || {};
    const conversationId = typeof data.conversationId === 'string' ? data.conversationId.trim() : '';
    const message = typeof data.message === 'string' ? data.message.trim() : '';
    if (!conversationId || !message || message.length > 12000) {
      throw new Error('Invalid AI request.');
    }

    const apiKey = process.env.AUREN_AI_API_KEY;
    const model = process.env.AUREN_AI_MODEL || 'gpt-4o-mini';
    const baseUrl = (process.env.AUREN_AI_BASE_URL || 'https://api.openai.com/v1').replace(/\\/$/, '');

    if (!apiKey) {
      return {
        text: 'AUREN AI Gateway متصل، لكن مزود الذكاء الاصطناعي لم يتم تفعيل مفتاحه بعد. أرسل سؤالك مرة أخرى بعد إعداد AUREN_AI_API_KEY.',
        action: null,
        payload: {},
        requiresApproval: false,
      };
    }

    const response = await fetch(baseUrl + '/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: 'Bearer ' + apiKey,
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: 'You are AUREN AI. Be helpful, concise, safe, and action-oriented. Never execute external actions without explicit user approval. For a request to create a note or echo text, you may return ONLY a JSON object with keys text, action, payload, using action demo.create_note or demo.echo and payload {text}; otherwise answer normally.' },
          { role: 'user', content: message },
        ],
        temperature: 0.4,
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      console.error('AI provider error', response.status, body.slice(0, 1000));
      throw new Error('AI provider request failed.');
    }

    const result = await response.json();
    const rawText = result?.choices?.[0]?.message?.content;
    if (typeof rawText !== 'string' || !rawText.trim()) {
      throw new Error('AI provider returned an empty response.');
    }

    // The model may return a small JSON action envelope. Never trust it blindly:
    // only the allow-listed low-risk demo actions are exposed to the client.
    let text = rawText.trim();
    let action = null;
    let payload = {};
    let requiresApproval = false;
    try {
      const candidate = JSON.parse(text.replace(/^\`\`\`json\s*/i, '').replace(/\`\`\`$/i, '').trim());
      if (candidate && typeof candidate === 'object') {
        const allowedActions = new Set(['demo.echo', 'demo.create_note']);
        const candidateAction = typeof candidate.action === 'string' ? candidate.action : null;
        const candidatePayload = candidate.payload && typeof candidate.payload === 'object'
          ? candidate.payload
          : {};
        if (candidateAction && allowedActions.has(candidateAction)) {
          const keys = Object.keys(candidatePayload);
          if (keys.every((key) => key === 'text') &&
              typeof candidatePayload.text === 'string' &&
              candidatePayload.text.length <= 2000) {
            action = candidateAction;
            payload = { text: candidatePayload.text };
            requiresApproval = true;
            text = typeof candidate.text === 'string' && candidate.text.trim()
              ? candidate.text.trim()
              : 'لدي طلب تنفيذ يحتاج موافقتك قبل التنفيذ.';
          }
        }
      }
    } catch (_) {
      // Normal natural-language responses are valid and need no action envelope.
    }

    return {
      text,
      action,
      payload,
      requiresApproval,
    };
  },
);
