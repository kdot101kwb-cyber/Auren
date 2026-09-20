const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { defineSecret } = require('firebase-functions/params');

initializeApp();
const db = getFirestore();
const AUREN_AI_API_KEY = defineSecret('AUREN_AI_API_KEY');

async function loadAurenPermissionLedger(uid) {
  const ref = db.collection('users').doc(uid)
    .collection('agent_permissions').doc('primary');
  const snap = await ref.get();
  if (!snap.exists) {
    return {
      enabled: true,
      allowedActions: new Set(),
      dailySpendingLimitMinor: null,
      spentTodayMinor: 0,
      currency: 'USD',
    };
  }
  const data = snap.data() || {};
  return {
    enabled: data.enabled === true,
    allowedActions: new Set(
      Array.isArray(data.allowedActions) ? data.allowedActions : [],
    ),
    dailySpendingLimitMinor:
      Number.isInteger(data.dailySpendingLimitMinor)
        ? data.dailySpendingLimitMinor
        : null,
    spentTodayMinor: Number.isInteger(data.spentTodayMinor)
      ? data.spentTodayMinor
      : 0,
    currency: typeof data.currency === 'string' ? data.currency : 'USD',
  };
}

function assertAurenActionPermission(ledger, action) {
  if (!ledger.enabled) {
    throw new Error('AUREN agent permissions are disabled.');
  }
  if (ledger.allowedActions.size > 0 &&
      !ledger.allowedActions.has(action.actionType)) {
    throw new Error('Action is not granted by the permission ledger.');
  }

  const amount = Number.isInteger(action.payload?.amountMinor)
    ? action.payload.amountMinor
    : 0;
  if (amount < 0 || !Number.isSafeInteger(amount)) {
    throw new Error('Invalid spending amount.');
  }
  if (Number.isInteger(action.spendingLimitMinor) &&
      action.spendingLimitMinor >= 0 &&
      amount > action.spendingLimitMinor) {
    throw new Error('Action amount exceeds its approved spending limit.');
  }
  if (ledger.dailySpendingLimitMinor !== null &&
      ledger.spentTodayMinor + amount > ledger.dailySpendingLimitMinor) {
    throw new Error('Daily AUREN spending limit exceeded.');
  }
}

async function updateAurenAgentTrust(uid, status) {
  const ref = db.collection('users').doc(uid).collection('agent_trust').doc('primary');
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() : {};
    const completed = Number(data.completedExecutions || 0);
    const failed = Number(data.failedExecutions || 0);
    const nextCompleted = completed + (status === 'completed' ? 1 : 0);
    const nextFailed = failed + (status === 'failed' ? 1 : 0);
    const total = nextCompleted + nextFailed;
    const score = total === 0 ? 50 : Math.max(0, Math.min(100, Math.round((nextCompleted / total) * 100)));
    tx.set(ref, {
      agentId: 'primary',
      status: 'active',
      score,
      completedExecutions: nextCompleted,
      failedExecutions: nextFailed,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

async function writeAurenActionAudit(uid, action, status, extra = {}) {
  const ref = db.collection('users').doc(uid).collection('action_audit').doc();
  await ref.set({
    actionId: action.id || null,
    actionType: action.actionType || null,
    agentId: action.agentId || 'primary',
    permission: action.permission || null,
    riskLevel: action.riskLevel || null,
    approvalLevel: action.approvalLevel ?? null,
    requiresApproval: action.requiresApproval === true,
    status,
    createdAt: FieldValue.serverTimestamp(),
    ...extra,
  });
}

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


exports.onAurenActionStatusChanged = onDocumentUpdated(
  'users/{userId}/actions/{actionId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;
    if (!['approved', 'rejected'].includes(after.status)) return;
    await writeAurenActionAudit(event.params.userId, {
      ...after,
      id: event.params.actionId,
    }, after.status, { source: 'action-status-change' });
  },
);

exports.executeAurenAction = require('firebase-functions/v2/https').onCall(
  { region: 'us-central1', timeoutSeconds: 30, memory: '256MiB' },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new Error('Unauthenticated');

    const actionId = typeof request.data?.actionId === 'string' ? request.data.actionId.trim() : '';
    if (!actionId) throw new Error('Invalid actionId.');

    const actionRef = db.collection('users').doc(uid).collection('actions').doc(actionId);
    const actionSnapshot = await actionRef.get();
    if (!actionSnapshot.exists) throw new Error('Action not found.');
    const action = actionSnapshot.data();

    const allowedActions = new Set(['demo.echo', 'demo.create_note', 'memory.save']);
    if (!allowedActions.has(action?.actionType) || action?.permission !== 'userApproval' ||
        action?.riskLevel !== 'low' || action?.approvalLevel !== 1 ||
        action?.requiresApproval !== true || action?.status !== 'approved') {
      throw new Error('Action is not authorized for execution.');
    }

    const permissionLedger = await loadAurenPermissionLedger(uid);
    assertAurenActionPermission(permissionLedger, action);

    const payload = action.payload && typeof action.payload === 'object' && !Array.isArray(action.payload)
      ? action.payload
      : {};
    const keys = Object.keys(payload);
    if (action.actionType === 'memory.save') {
      if (keys.some((key) => !['key', 'value'].includes(key)) ||
          typeof payload.key !== 'string' || typeof payload.value !== 'string' ||
          payload.key.trim().length === 0 || payload.key.length > 120 ||
          payload.value.trim().length === 0 || payload.value.length > 2000) {
        throw new Error('Invalid memory payload.');
      }
    } else if (keys.some((key) => key !== 'text') || typeof payload.text !== 'string' ||
        payload.text.trim().length === 0 || payload.text.length > 2000) {
      throw new Error('Invalid action payload.');
    }

    const executionRef = db.collection('users').doc(uid).collection('action_executions').doc(actionId);
    await db.runTransaction(async (tx) => {
      const current = await tx.get(actionRef);
      if (!current.exists || current.data()?.status !== 'approved') {
        throw new Error('Action is no longer approved for execution.');
      }
      tx.update(actionRef, {
        status: 'executing',
        executionStartedAt: FieldValue.serverTimestamp(),
      });
      tx.set(executionRef, {
        actionId,
        actionType: action.actionType,
        status: 'executing',
        startedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
    });

    await writeAurenActionAudit(uid, { ...action, id: actionId }, 'executing', { source: 'executeAurenAction' });

    try {
      let executionResult;
      if (action.actionType === 'demo.echo') {
        executionResult = payload.text.trim();
      } else if (action.actionType === 'memory.save') {
        const memoryId = 'memory_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8);
        await db.collection('users').doc(uid).collection('memory').doc(memoryId).set({
          key: payload.key.trim(),
          value: payload.value.trim(),
          enabled: true,
          updatedAt: new Date().toISOString(),
          source: 'auren-ai',
          actionId,
        });
        executionResult = 'تم حفظ المعلومة في ذاكرة AUREN.';
      } else {
        await db.collection('users').doc(uid).collection('notes').add({
          text: payload.text.trim(),
          source: 'auren-ai-action',
          actionId,
          createdAt: FieldValue.serverTimestamp(),
        });
        executionResult = 'تم إنشاء الملاحظة بنجاح.';
      }

      await actionRef.update({
        status: 'completed',
        result: executionResult,
        executionCompletedAt: FieldValue.serverTimestamp(),
      });
      await executionRef.set({
        status: 'completed',
        result: executionResult,
        completedAt: FieldValue.serverTimestamp(),
      }, {merge: true});

      await writeAurenActionAudit(uid, { ...action, id: actionId }, 'completed', { result: executionResult, source: 'executeAurenAction' });
      await updateAurenAgentTrust(uid, 'completed');
      return {status: 'completed', result: executionResult};
    } catch (e) {
      const message = e?.message || 'Action execution failed.';
      await actionRef.update({
        status: 'failed',
        result: message,
        executionCompletedAt: FieldValue.serverTimestamp(),
      });
      await executionRef.set({
        status: 'failed',
        result: message,
        completedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      await writeAurenActionAudit(uid, { ...action, id: actionId }, 'failed', { result: message, source: 'executeAurenAction' });
      await updateAurenAgentTrust(uid, 'failed');
      throw new Error(message);
    }
  },
);

exports.aurenAiGateway = require('firebase-functions/v2/https').onCall(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB', secrets: [AUREN_AI_API_KEY] },
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

    // Never trust a client-supplied conversation ID alone. Verify membership
    // server-side before sending any conversation context to the provider.
    const conversationSnapshot = await db.collection('conversations').doc(conversationId).get();
    const conversationData = conversationSnapshot.data();
    if (!conversationSnapshot.exists || !conversationData ||
        !Array.isArray(conversationData.memberIds) ||
        !conversationData.memberIds.includes(request.auth.uid) ||
        conversationData.isAi !== true) {
      throw new Error('Conversation access denied.');
    }

    const apiKey = AUREN_AI_API_KEY.value();
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
          { role: 'system', content: 'You are AUREN AI. Be helpful, concise, safe, and action-oriented. Never execute external actions without explicit user approval. For a request to create a note or echo text, you may return ONLY a JSON object with keys text, action, payload, using action demo.create_note or demo.echo with payload {text}, or memory.save with payload {key,value}; otherwise answer normally.' },
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
        const allowedActions = new Set(['demo.echo', 'demo.create_note', 'memory.save']);
        const candidateAction = typeof candidate.action === 'string' ? candidate.action : null;
        const candidatePayload = candidate.payload && typeof candidate.payload === 'object'
          ? candidate.payload
          : {};
        if (candidateAction && allowedActions.has(candidateAction)) {
          const keys = Object.keys(candidatePayload);
          const validTextAction = keys.every((key) => key === 'text') &&
            typeof candidatePayload.text === 'string' &&
            candidatePayload.text.length <= 2000;
          const validMemoryAction = keys.every((key) => key === 'key' || key === 'value') &&
            typeof candidatePayload.key === 'string' &&
            typeof candidatePayload.value === 'string' &&
            candidatePayload.key.trim().length > 0 &&
            candidatePayload.key.length <= 120 &&
            candidatePayload.value.trim().length > 0 &&
            candidatePayload.value.length <= 2000;
          if (validTextAction || validMemoryAction) {
            action = candidateAction;
            payload = validMemoryAction
              ? { key: candidatePayload.key.trim(), value: candidatePayload.value.trim() }
              : { text: candidatePayload.text };
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

exports.submitAurenAgentReview = require('firebase-functions/v2/https').onCall(
  { region: 'us-central1', timeoutSeconds: 15, memory: '256MiB' },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new Error('Unauthenticated');
    const agentId = typeof request.data?.agentId === 'string' ? request.data.agentId.trim() : '';
    const rating = Number(request.data?.rating);
    const text = typeof request.data?.text === 'string' ? request.data.text.trim() : '';
    if (!agentId || agentId.length > 120 || !Number.isInteger(rating) || rating < 1 || rating > 5 || !text || text.length > 1000) {
      throw new Error('Invalid review.');
    }
    const listing = await db.collection('agent_listings').doc(agentId).get();
    if (!listing.exists || listing.data()?.state !== 'published') throw new Error('Agent is not published.');
    const existing = await db.collection('agent_reviews').where('agentId','==',agentId).where('reviewerUid','==',uid).limit(1).get();
    if (!existing.empty) throw new Error('You already reviewed this Agent.');
    const reviewRef = db.collection('agent_reviews').doc();
    await reviewRef.set({
      agentId, reviewerUid: uid, rating, text,
      createdAt: FieldValue.serverTimestamp(),
    });
    const reviews = await db.collection('agent_reviews').where('agentId','==',agentId).get();
    const total = reviews.docs.reduce((sum,d)=>sum+Number(d.data().rating||0),0);
    const count = reviews.size;
    await db.collection('agent_reputation').doc(agentId).set({
      agentId, score: count ? Math.round((total/count)*10)/10 : 0,
      reviewCount: count, updatedAt: FieldValue.serverTimestamp(),
    }, {merge:true});
    return {status:'created', reviewId:reviewRef.id};
  },
);


exports.openAurenAgentDispute = require('firebase-functions/v2/https').onCall(
 {region:'us-central1',timeoutSeconds:15,memory:'256MiB'},
 async (request)=>{
  const uid=request.auth?.uid;if(!uid)throw new Error('Unauthenticated');
  const agentId=typeof request.data?.agentId==='string'?request.data.agentId.trim():'';
  const actionId=typeof request.data?.actionId==='string'?request.data.actionId.trim():'';
  const reason=typeof request.data?.reason==='string'?request.data.reason.trim():'';
  if(!agentId||!actionId||!reason||reason.length>1000)throw new Error('Invalid dispute.');
  const action=await db.collection('users').doc(uid).collection('actions').doc(actionId).get();
  if(!action.exists)throw new Error('Action not found.');
  const disputeRef=db.collection('users').doc(uid).collection('disputes').doc();
  await disputeRef.set({agentId,actionId,reason,status:'open',createdAt:FieldValue.serverTimestamp()});
  await writeAurenActionAudit(uid,{...action.data(),id:actionId},'dispute_opened',{agentId,source:'openAurenAgentDispute'});
  return {status:'open',disputeId:disputeRef.id};
 });


exports.fundAurenAgentWallet = require('firebase-functions/v2/https').onCall(
  {region:'us-central1',timeoutSeconds:15,memory:'256MiB'},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new Error('Unauthenticated');
    const amountMinor = Number(request.data?.amountMinor);
    const currency = typeof request.data?.currency === 'string' ? request.data.currency.trim().toUpperCase() : '';
    if (!Number.isSafeInteger(amountMinor) || amountMinor <= 0 || amountMinor > 1000000 || !/^[A-Z]{3}$/.test(currency)) {
      throw new Error('Invalid wallet funding request.');
    }
    const walletRef = db.collection('users').doc(uid).collection('wallet').doc('primary');
    const txRef = db.collection('users').doc(uid).collection('wallet_transactions').doc();
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(walletRef);
      const current = snap.exists ? snap.data() : {};
      const existingCurrency = typeof current.currency === 'string' ? current.currency : currency;
      if (existingCurrency !== currency && snap.exists) throw new Error('Wallet currency mismatch.');
      tx.set(walletRef, {
        currency,
        balanceMinor: Number(current.balanceMinor || 0) + amountMinor,
        reservedMinor: Number(current.reservedMinor || 0),
        dailyLimitMinor: Number(current.dailyLimitMinor || 0),
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge:true});
      tx.set(txRef, {
        type:'demo_funding',
        amountMinor,
        currency,
        status:'completed',
        source:'auren-demo',
        createdAt:FieldValue.serverTimestamp(),
      });
    });
    return {status:'completed', amountMinor, currency};
  },
);

exports.publishAurenAgent = require('firebase-functions/v2/https').onCall(
 {region:'us-central1',timeoutSeconds:15,memory:'256MiB'},
 async (request)=>{
  const uid=request.auth?.uid;if(!uid)throw new Error('Unauthenticated');
  const agentId=typeof request.data?.agentId==='string'?request.data.agentId.trim():'';
  const name=typeof request.data?.name==='string'?request.data.name.trim():'';
  const description=typeof request.data?.description==='string'?request.data.description.trim():'';
  const version=typeof request.data?.version==='string'?request.data.version.trim():'';
  const capabilities=Array.isArray(request.data?.capabilities)?request.data.capabilities.filter(x=>typeof x==='string').slice(0,30):[];
  if(!agentId||!name||!version||name.length>120||description.length>1000||agentId.length>120)throw new Error('Invalid Agent listing.');
  const owned=await db.collection('users').doc(uid).collection('agents').doc(agentId).get();
  if(!owned.exists||owned.data()?.status!=='active')throw new Error('Agent is not active or owned.');
  await db.collection('agent_listings').doc(agentId).set({
    agentId,name,description,version,capabilities,state:'published',
    pricing:{model:'free',currency:'USD',amountMinor:0},
    reputationScore:0,reviewCount:0,ownerUid:uid,updatedAt:FieldValue.serverTimestamp(),
  },{merge:true});
  return {status:'published',agentId};
 });


function validateAurenPluginManifest(manifest) {
  if (!manifest || typeof manifest !== 'object' || Array.isArray(manifest)) throw new Error('Invalid plugin manifest.');
  const pluginId = typeof manifest.pluginId === 'string' ? manifest.pluginId.trim() : '';
  const name = typeof manifest.name === 'string' ? manifest.name.trim() : '';
  const version = typeof manifest.version === 'string' ? manifest.version.trim() : '';
  const entrypoint = typeof manifest.entrypoint === 'string' ? manifest.entrypoint.trim() : '';
  const capabilities = Array.isArray(manifest.capabilities) ? manifest.capabilities.filter((x) => typeof x === 'string').map((x) => x.trim()).filter(Boolean) : [];
  if (!/^[a-z0-9][a-z0-9._-]{2,119}$/.test(pluginId) || !name || name.length > 120 || !version || version.length > 40 || !entrypoint || entrypoint.length > 500 || capabilities.length > 30) {
    throw new Error('Plugin manifest failed validation.');
  }
  if (capabilities.some((x) => x.length > 80 || !/^[a-z0-9][a-z0-9._:-]*$/i.test(x))) throw new Error('Invalid plugin capability.');
  return {pluginId, name, version, entrypoint, capabilities};
}

exports.validateAurenPlugin = require('firebase-functions/v2/https').onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB'},
  async (request) => {
    if (!request.auth?.uid) throw new Error('Unauthenticated');
    const manifest = validateAurenPluginManifest(request.data?.manifest);
    return {
      valid: true,
      manifest,
      policy: {sandbox:'auren-isolated-v1', network:'deny-by-default', secrets:'deny', executionTimeoutMs:10000},
    };
  },
);

exports.installAurenPlugin = require('firebase-functions/v2/https').onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB'},
  async (request) => {
    const uid=request.auth?.uid;if(!uid)throw new Error('Unauthenticated');
    const manifest=validateAurenPluginManifest(request.data?.manifest);
    const ref=db.collection('users').doc(uid).collection('agent_installations').doc(manifest.pluginId);
    await ref.set({agentId:manifest.pluginId,name:manifest.name,version:manifest.version,status:'active',installedAt:new Date().toISOString(),source:'plugin',capabilities:manifest.capabilities},{merge:true});
    return {status:'installed',pluginId:manifest.pluginId};
  },
);

exports.invokeAurenPlugin = require('firebase-functions/v2/https').onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB'},
  async (request) => {
    const uid=request.auth?.uid;if(!uid)throw new Error('Unauthenticated');
    const pluginId=typeof request.data?.pluginId==='string'?request.data.pluginId.trim():'';
    const action=typeof request.data?.action==='string'?request.data.action.trim():'';
    const payload=request.data?.payload && typeof request.data.payload==='object' && !Array.isArray(request.data.payload)?request.data.payload:{};
    if(!pluginId||pluginId.length>120||!action||action.length>120||Object.keys(payload).length>20)throw new Error('Invalid plugin invocation.');
    const install=await db.collection('users').doc(uid).collection('agent_installations').doc(pluginId).get();
    if(!install.exists||install.data()?.status!=='active')throw new Error('Plugin is not installed or active.');
    const quotaRef=db.collection('plugin_quotas').doc(uid+'_'+pluginId);
    const invocationRef=db.collection('plugin_invocations').doc();
    const now=new Date(); const day=now.toISOString().slice(0,10);
    await db.runTransaction(async(tx)=>{
      const snap=await tx.get(quotaRef);const data=snap.exists?snap.data():{};
      const used=data.day===day?Number(data.used||0):0;
      if(used>=100)throw new Error('Daily plugin invocation quota exceeded.');
      tx.set(quotaRef,{uid,pluginId,day,used:used+1,limit:100,updatedAt:FieldValue.serverTimestamp()},{merge:true});
      tx.set(invocationRef,{uid,pluginId,action,payload,status:'accepted',createdAt:FieldValue.serverTimestamp()});
    });
    return {status:'accepted',invocationId:invocationRef.id,quotaRemaining:99};
  },
);

exports.simulateAurenAgentAction = require('firebase-functions/v2/https').onCall(
  {region:'us-central1', timeoutSeconds:15, memory:'256MiB'},
  async (request) => {
    const uid=request.auth?.uid;if(!uid)throw new Error('Unauthenticated');
    const agentId=typeof request.data?.agentId==='string'?request.data.agentId.trim():'';
    const action=typeof request.data?.action==='string'?request.data.action.trim():'';
    const payload=request.data?.payload && typeof request.data.payload==='object' && !Array.isArray(request.data.payload)?request.data.payload:{};
    if(!agentId||!action||agentId.length>120||action.length>120||Object.keys(payload).length>20)throw new Error('Invalid simulation request.');
    const install=await db.collection('users').doc(uid).collection('agent_installations').doc(agentId).get();
    if(!install.exists||install.data()?.status!=='active')throw new Error('Agent is not installed or active.');
    const simulationRef=db.collection('users').doc(uid).collection('agent_simulations').doc();
    const result={mode:'simulation',wouldExecute:true,externalSideEffects:false,spendingMinor:0,network:'denied',secrets:'denied',message:'Simulation completed. No external action was executed.'};
    await simulationRef.set({agentId,action,payload,result,status:'completed',createdAt:FieldValue.serverTimestamp()});
    return {status:'completed',simulationId:simulationRef.id,result};
  },
);