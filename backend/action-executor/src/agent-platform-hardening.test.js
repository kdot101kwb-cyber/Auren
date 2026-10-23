import test from 'node:test';
import assert from 'node:assert/strict';
import { createAgentId } from './agent-identity.js';
import { createCredentialFingerprint, publicCredential } from './credentials.js';
import { normalizeListing, validateListingForPublish, listingVersionKey } from './agent-marketplace.js';
import { createAgentEndpointId, validateEnvelope, MAX_ENVELOPE_BYTES } from './agent-protocol.js';
import { openDispute, addEvidence, resolveDispute, createDisputeId } from './disputes.js';
import { writeAuditEvent } from './audit-log.js';

test('agent identity and public credential identifiers are deterministic and reject invalid ids', () => {
  assert.equal(createAgentId('user-123'), createAgentId('user-123'));
  assert.match(createAgentId('user-123'), /^[a-f0-9]{32}$/);
  assert.throws(() => createAgentId('user/other'), /owner uid/i);
  assert.throws(() => createAgentId('  '), /owner uid/i);
  assert.equal(createCredentialFingerprint('agent:primary').length, 64);
  assert.equal(publicCredential('agent:primary').credentialId, publicCredential('agent:primary').credentialId);
  assert.throws(() => publicCredential('../secret'), /agent id/i);
  assert.throws(() => createAgentEndpointId('agent/other'), /agent id/i);
});

test('marketplace normalization bounds metadata and removes invalid capabilities', () => {
  const listing = normalizeListing({
    name: '  Demo Agent  ',
    description: 'D'.repeat(1500),
    capabilities: ['messages.send', 'messages.send', '../unsafe', '', 4, 'actions.execute'],
    state: 'published',
    pricing: { model: 'free', currency: 'usd', amountMinor: 500 },
  }, { agentId: 'agent-1', name: 'Fallback', version: '1.2' });

  assert.equal(listing.name, 'Demo Agent');
  assert.equal(listing.description.length, 1000);
  assert.deepEqual(listing.capabilities, ['messages.send', 'actions.execute']);
  assert.equal(listing.pricing.currency, 'USD');
  assert.equal(listing.pricing.amountMinor, 0);
  assert.equal(validateListingForPublish(listing), true);
  assert.equal(validateListingForPublish({ ...listing, state: 'draft' }), false);
  assert.equal(validateListingForPublish({ ...listing, pricing: { ...listing.pricing, amountMinor: -1 } }), false);
  assert.equal(listingVersionKey('agent-1', '1.2'), 'agent-1@1.2');
});

test('A2A envelopes reject malformed ids, wrong versions, and oversized payloads', () => {
  const envelope = {
    protocol: 'AUREN-A2A',
    version: '1.0',
    messageId: 'message-123',
    senderAgentId: 'agent-a',
    recipientAgentId: 'agent-b',
    type: 'messages.send',
    payload: { text: 'hello' },
  };
  assert.equal(validateEnvelope(envelope), true);
  assert.equal(validateEnvelope({ ...envelope, version: '9.0' }), false);
  assert.equal(validateEnvelope({ ...envelope, senderAgentId: '' }), false);
  assert.equal(validateEnvelope({ ...envelope, payload: 'x'.repeat(MAX_ENVELOPE_BYTES) }), false);
  assert.equal(validateEnvelope(null), false);
  assert.equal(createAgentEndpointId('agent-a').length, 32);
});

test('dispute entry points reject unbounded or malformed input before database access', async () => {
  const noDatabaseCalls = () => { throw new Error('database should not be accessed'); };
  const db = { collection: noDatabaseCalls };
  await assert.rejects(openDispute(db, 'owner-1', {
    transactionId: 't'.repeat(129), reason: 'reason', description: 'long enough',
  }), /transactionId/i);
  await assert.rejects(openDispute(db, 'owner/other', {
    transactionId: 'tx-1', reason: 'reason', description: 'long enough',
  }), /owner uid/i);
  await assert.rejects(addEvidence(db, 'owner-1', {
    disputeId: 'dsp-1', type: 'text', description: 'x'.repeat(4001),
  }), /description/i);
  await assert.rejects(resolveDispute(db, 'owner-1', {
    disputeId: 'dsp-1', resolution: 'refund', amountMinor: Number.MAX_SAFE_INTEGER + 1,
  }), /safe integer/i);
  assert.match(createDisputeId(), /^dsp_[0-9a-f-]{36}$/);
});

test('audit events enforce owner scope, field count, and serialized size', async () => {
  const writes = [];
  const db = {
    collection(name) {
      assert.equal(name, 'users');
      return {
        doc(uid) {
          assert.equal(uid, 'owner-1');
          return {
            collection(child) {
              assert.equal(child, 'action_audit');
              return { doc() { return { id: 'audit-1', set: async (value) => writes.push(value) }; } };
            },
          };
        },
      };
    },
  };
  assert.equal(await writeAuditEvent(db, 'owner-1', { action: 'agent.run', status: 'preview' }), 'audit-1');
  assert.equal(writes[0].uid, 'owner-1');
  assert.equal(writes[0].action, 'agent.run');
  await assert.rejects(writeAuditEvent(db, 'owner/other', { action: 'x' }), /owner uid/i);
  await assert.rejects(writeAuditEvent(db, 'owner-1', Object.fromEntries(
    Array.from({ length: 41 }, (_, i) => [`field${i}`, i]),
  )), /too many fields/i);
  await assert.rejects(writeAuditEvent(db, 'owner-1', { detail: 'x'.repeat(17 * 1024) }), /size limit/i);
});
