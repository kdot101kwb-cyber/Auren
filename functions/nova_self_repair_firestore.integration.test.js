'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'auren-nova-repair-emulator';
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error('FIRESTORE_EMULATOR_HOST is required; run this suite through Firebase Emulator.');
}
try { initializeApp({projectId:PROJECT_ID}); } catch (_) {}
const db = getFirestore();
const {
  recordApplyCompletion,
  recordRecoveryQuarantine,
} = require('./nova_self_repair_service');

const uid = 'nova-repair-race-' + process.pid;
const proposalId = 'repairrace' + String(process.pid).padStart(8, '0');
const ref = db.collection('users').doc(uid).collection('nova_repair_proposals').doc(proposalId);
const branchSha = 'c'.repeat(40);
const result = {branch:'nova/repairs/' + proposalId, commitSha:'d'.repeat(40)};

async function seedApplyingProposal() {
  await ref.set({
    ownerUid:uid,
    state:'applying',
    sourceCommitSha:'a'.repeat(40),
    applyStartedAt:Timestamp.fromMillis(Date.now() - 16 * 60 * 1000),
  });
}

test.after(async () => {
  await db.recursiveDelete(ref).catch(() => {});
  await db.recursiveDelete(db.collection('users').doc(uid).collection('nova_audit')).catch(() => {});
});

test('Firestore transaction keeps recovery quarantine when a delayed worker completes', async () => {
  await seedApplyingProposal();

  await recordRecoveryQuarantine(db, ref, uid, branchSha, Date.now());
  const completion = await recordApplyCompletion(db, ref, uid, result);
  const final = (await ref.get()).data();

  assert.equal(completion.state, 'recovery_required');
  assert.equal(final.state, 'recovery_required');
  assert.equal(final.recoveryObservedCommitSha, branchSha);
  assert.equal(final.repairCommitSha, result.commitSha);
  assert.equal(final.recoveryOutcome, 'branch_found_after_recovery_check');
});

test('Firestore completion safely preserves manual-review quarantine when no recovery SHA was observed', async () => {
  await ref.set({
    ownerUid:uid,
    state:'recovery_required',
    sourceCommitSha:'a'.repeat(40),
    recoveryOutcome:'apply_error_requires_manual_review',
  });
  const completion = await recordApplyCompletion(db, ref, uid, result);
  const final = (await ref.get()).data();

  assert.equal(completion.state, 'recovery_required');
  assert.equal(final.state, 'recovery_required');
  assert.equal(final.recoveryObservedCommitSha, null);
  assert.equal(final.recoveryOutcome, 'apply_error_requires_manual_review');
  assert.equal(final.repairCommitSha, result.commitSha);
});

test('concurrent Firestore recovery and worker completion never lose the pushed commit', async () => {
  await seedApplyingProposal();

  const outcomes = await Promise.allSettled([
    recordRecoveryQuarantine(db, ref, uid, branchSha, Date.now()),
    recordApplyCompletion(db, ref, uid, result),
  ]);
  const final = (await ref.get()).data();

  assert.ok(['recovery_required', 'validation_pending'].includes(final.state));
  assert.equal(final.repairCommitSha, result.commitSha);
  if (final.state === 'recovery_required') {
    assert.equal(final.recoveryObservedCommitSha, branchSha);
    assert.equal(final.recoveryOutcome, 'branch_found_after_recovery_check');
  } else {
    assert.equal(final.state, 'validation_pending');
    assert.ok(outcomes.some(item => item.status === 'fulfilled'));
  }
});

test('Firestore transaction refuses recovery for another owner', async () => {
  await seedApplyingProposal();
  await assert.rejects(
    () => recordRecoveryQuarantine(db, ref, 'different-owner', branchSha, Date.now()),
    /Only the proposal owner/,
  );
  assert.equal((await ref.get()).data().state, 'applying');
});
