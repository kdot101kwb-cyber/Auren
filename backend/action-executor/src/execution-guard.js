import crypto from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

export function createExecutionKey(uid, actionId) {
  return crypto.createHash('sha256')
    .update(`auren:execution:${uid}:${actionId}`)
    .digest('hex');
}

export async function claimExecution(db, uid, actionId, actionRef) {
  const key = createExecutionKey(uid, actionId);
  const guardRef = db.collection('users').doc(uid)
    .collection('action_executions').doc(key);

  const result = await db.runTransaction(async (tx) => {
    const [guardSnap, actionSnap] = await Promise.all([
      tx.get(guardRef),
      tx.get(actionRef),
    ]);

    if (!actionSnap.exists) {
      throw Object.assign(new Error('Action not found.'), { code: 404 });
    }

    const action = actionSnap.data();
    if (action.status !== 'approved') {
      throw Object.assign(new Error('Action is not executable in its current state.'), { code: 409 });
    }

    if (guardSnap.exists) {
      const guard = guardSnap.data();
      if (guard.status === 'completed') {
        return { state: 'completed', guard };
      }
      throw Object.assign(new Error('Action execution is already claimed.'), { code: 409 });
    }

    tx.create(guardRef, {
      actionId,
      status: 'executing',
      attempt: 1,
      startedAt: FieldValue.serverTimestamp(),
    });

    tx.update(actionRef, {
      status: 'executing',
      executionKey: key,
      executionAttempt: 1,
      executionStartedAt: FieldValue.serverTimestamp(),
    });

    return { state: 'claimed', key };
  });

  return result;
}

export function executionGuardPath(uid, key) {
  return db.collection('users').doc(uid).collection('action_executions').doc(key);
}
