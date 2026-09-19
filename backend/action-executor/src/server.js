import express from 'express';
import { getApps, initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

if (getApps().length === 0) {
  initializeApp({ credential: applicationDefault() });
}

const app = express();
app.use(express.json({ limit: '32kb' }));

const db = getFirestore();
const auth = getAuth();

const allowedActions = new Set([
  'demo.echo',
  'demo.create_note',
]);

function error(res, status, message) {
  return res.status(status).json({ error: message });
}

async function requireUser(req, res, next) {
  try {
    const header = req.get('authorization') || '';
    if (!header.startsWith('Bearer ')) {
      return error(res, 401, 'Missing Firebase ID token.');
    }

    const token = header.slice('Bearer '.length).trim();
    const decoded = await auth.verifyIdToken(token);
    req.uid = decoded.uid;
    next();
  } catch {
    return error(res, 401, 'Invalid Firebase ID token.');
  }
}

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'auren-action-executor' });
});

app.post('/api/actions/execute', requireUser, async (req, res) => {
  const actionId = typeof req.body?.actionId === 'string'
    ? req.body.actionId.trim()
    : '';

  if (!actionId) {
    return error(res, 400, 'actionId is required.');
  }

  const actionRef = db
    .collection('users')
    .doc(req.uid)
    .collection('actions')
    .doc(actionId);

  const auditRef = db
    .collection('users')
    .doc(req.uid)
    .collection('action_audit')
    .doc();

  try {
    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(actionRef);

      if (!snap.exists) {
        throw Object.assign(new Error('Action not found.'), { code: 404 });
      }

      const action = snap.data();

      if (action.status !== 'approved') {
        throw Object.assign(
          new Error('Action must be explicitly approved before execution.'),
          { code: 409 },
        );
      }

      if (action.requiresApproval !== true) {
        throw Object.assign(
          new Error('Invalid approval policy for action.'),
          { code: 409 },
        );
      }

      if (!allowedActions.has(action.title)) {
        throw Object.assign(
          new Error('Action type is not allowed by the executor.'),
          { code: 403 },
        );
      }

      tx.update(actionRef, {
        status: 'executing',
        executionStartedAt: FieldValue.serverTimestamp(),
      });

      tx.set(auditRef, {
        actionId,
        event: 'execution_started',
        uid: req.uid,
        actionType: action.title,
        createdAt: FieldValue.serverTimestamp(),
      });

      return action;
    });

    let executionResult;

    switch (result.title) {
      case 'demo.echo':
        executionResult = result.description;
        break;
      case 'demo.create_note':
        executionResult = 'Demo note action accepted by the trusted executor.';
        break;
      default:
        return error(res, 403, 'Action type is not executable.');
    }

    await actionRef.update({
      status: 'completed',
      result: executionResult,
      executionCompletedAt: FieldValue.serverTimestamp(),
    });

    await auditRef.update({
      event: 'execution_completed',
      result: executionResult,
      completedAt: FieldValue.serverTimestamp(),
    });

    return res.json({
      status: 'completed',
      result: executionResult,
    });
  } catch (e) {
    const status = Number.isInteger(e?.code) ? e.code : 500;
    try {
      await actionRef.update({
        status: 'failed',
        result: e.message || 'Execution failed.',
        executionCompletedAt: FieldValue.serverTimestamp(),
      });
      await auditRef.set({
        actionId,
        event: 'execution_failed',
        uid: req.uid,
        error: e.message || 'Execution failed.',
        createdAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    } catch {}

    return error(res, status, e.message || 'Execution failed.');
  }
});

const port = Number(process.env.PORT || 8080);
app.listen(port, () => {
  console.log(`AUREN Action Executor listening on :${port}`);
});
