import express from 'express';
import { getApps, initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getActionDefinition, validatePayload } from './action-registry.js';
import { loadPermissionLedger, assertPermission, assertSpendingLimit } from './permission-ledger.js';
import { loadAgentIdentity } from './agent-identity.js';
import { writeAuditEvent } from './audit-log.js';
import { createExecutionKey } from './execution-guard.js';
import { publicCredential } from './credentials.js';

if (getApps().length === 0) {
  initializeApp({ credential: applicationDefault() });
}

const app = express();
app.use(express.json({ limit: '32kb' }));

const db = getFirestore();
const auth = getAuth();

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

  const agent = await loadAgentIdentity(db, req.uid);
  const credential = publicCredential(agent.agentId);
  if (agent.status !== 'active') return error(res, 403, 'AUREN agent is not active.');

  try {
    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(actionRef);

      if (!snap.exists) {
        throw Object.assign(new Error('Action not found.'), { code: 404 });
      }

      const action = snap.data();
      const executionKey = createExecutionKey(req.uid, actionId);
      const executionRef = db.collection('users').doc(req.uid).collection('action_executions').doc(executionKey);

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

      const definition = getActionDefinition(action.actionType);
      if (!definition) {
        throw Object.assign(
          new Error('Action type is not registered.'),
          { code: 403 },
        );
      }

      if (action.requiresApproval !== definition.requiresApproval ||
          action.permission !== definition.permission ||
          action.riskLevel !== definition.riskLevel ||
          action.approvalLevel !== definition.approvalLevel) {
        throw Object.assign(
          new Error('Action security metadata does not match the registry.'),
          { code: 409 },
        );
      }

      if (!validatePayload(definition, action.payload)) {
        throw Object.assign(
          new Error('Action payload is not allowed.'),
          { code: 400 },
        );
      }

      const ledger = await loadPermissionLedger(db, req.uid);
      assertPermission(ledger, action);
      assertSpendingLimit(ledger, action);

      const executionSnap = await tx.get(executionRef);
      if (executionSnap.exists) {
        const execution = executionSnap.data();
        if (execution.status === 'completed') {
          throw Object.assign(new Error('Action has already been completed.'), { code: 409 });
        }
        throw Object.assign(new Error('Action execution is already claimed.'), { code: 409 });
      }

      tx.create(executionRef, {
        actionId,
        executionKey,
        agentId: agent.agentId,
        credentialId: credential.credentialId,
        status: 'executing',
        attempt: 1,
        startedAt: FieldValue.serverTimestamp(),
      });

      tx.update(actionRef, {
        status: 'executing',
        executionStartedAt: FieldValue.serverTimestamp(),
      });

      return action;
    });

    await writeAuditEvent(db, req.uid, {
      actionId,
      event: 'execution_started',
      agentId: agent.agentId,
      credentialId: credential.credentialId,
      actionType: result.actionType,
    });

    let executionResult;

    switch (result.actionType) {
      case 'demo.echo':
        executionResult = result.payload?.text ?? result.description;
        break;
      case 'demo.create_note':
        executionResult = 'Demo note action accepted by the trusted executor.';
        break;
      default:
        return error(res, 403, 'Action type is not executable.');
    }

    const executionKey = createExecutionKey(req.uid, actionId);
    const executionRef = db.collection('users').doc(req.uid).collection('action_executions').doc(executionKey);

    await actionRef.update({
      status: 'completed',
      result: executionResult,
      executionCompletedAt: FieldValue.serverTimestamp(),
    });
    await executionRef.update({
      status: 'completed',
      result: executionResult,
      completedAt: FieldValue.serverTimestamp(),
    });

    await writeAuditEvent(db, req.uid, {
      actionId,
      event: 'execution_completed',
      agentId: agent.agentId,
      actionType: result.actionType,
      result: executionResult,
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
      await writeAuditEvent(db, req.uid, {
        actionId,
        event: 'execution_failed',
        agentId: agent.agentId,
        error: e.message || 'Execution failed.',
      });
    } catch {}

    return error(res, status, e.message || 'Execution failed.');
  }
});

const port = Number(process.env.PORT || 8080);
app.listen(port, () => {
  console.log(`AUREN Action Executor listening on :${port}`);
});
