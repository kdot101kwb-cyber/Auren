'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {listNovaWalletProviders, normalizeNovaWalletEntry} = require('./nova_wallet_catalog');

test('registers Bravo and MyCashi as manual-only Sudan wallet trackers', () => {
  const wallets = listNovaWalletProviders();
  assert.deepEqual(wallets.map((wallet) => wallet.id), ['bravo_sudan', 'mycashi_sudan']);
  for (const wallet of wallets) {
    assert.equal(wallet.country, 'SD');
    assert.equal(wallet.integration, 'manual_tracking');
    assert.ok(wallet.capabilities.includes('manual_balance_entry'));
    assert.ok(wallet.unsupported.includes('live_balance_sync'));
    assert.ok(wallet.unsupported.includes('direct_transfer'));
    assert.equal(wallet.requiresUserApproval, true);
  }
});

test('normalizes manual income without claiming provider verification', () => {
  const entry = normalizeNovaWalletEntry({walletId:'bravo_sudan', type:'income', amount:'25000', currency:'sdg'});
  assert.equal(entry.amount, 25000);
  assert.equal(entry.currency, 'SDG');
  assert.equal(entry.status, 'recorded_by_user');
  assert.equal(entry.executionMode, 'manual_only');
  assert.match(entry.disclaimer, /has not verified/i);
});

test('transfer records require approval and never execute automatically', () => {
  const entry = normalizeNovaWalletEntry({walletId:'mycashi_sudan', type:'transfer', amount:10});
  assert.equal(entry.requiresApproval, true);
  assert.equal(entry.status, 'awaiting_user_approval');
  assert.equal(entry.executionMode, 'manual_only');
});

test('rejects unknown wallets, unsupported types, and invalid amounts', () => {
  assert.throws(() => normalizeNovaWalletEntry({walletId:'unknown', type:'income', amount:1}), /walletId/);
  assert.throws(() => normalizeNovaWalletEntry({walletId:'bravo_sudan', type:'cashout', amount:1}), /type/);
  assert.throws(() => normalizeNovaWalletEntry({walletId:'bravo_sudan', type:'income', amount:0}), /amount/);
  assert.throws(() => normalizeNovaWalletEntry({walletId:'bravo_sudan', type:'income', amount:'NaN'}), /amount/);
});
