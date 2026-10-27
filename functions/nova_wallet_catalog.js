'use strict';

// NOVA wallet registry for user-owned Sudanese payment apps.
// Manual tracking only: no provider authentication, live balance reads, or transfers.
const WALLETS = Object.freeze([
  {
    id: 'bravo_sudan',
    name: 'Bravo',
    country: 'SD',
    category: 'mobile_wallet',
    appUrl: 'https://play.google.com/store/apps/details?id=istinara.bravocash',
    integration: 'manual_tracking',
    capabilities: ['manual_balance_entry', 'manual_income_entry', 'manual_expense_entry', 'receipt_reference'],
    unsupported: ['live_balance_sync', 'direct_transfer', 'automatic_payment'],
    requiresUserApproval: true,
    verificationNote: 'Confirm the installed app and current provider terms before relying on account or payout details.',
  },
  {
    id: 'mycashi_sudan',
    name: 'MyCashi',
    country: 'SD',
    category: 'mobile_wallet',
    appUrl: 'https://play.google.com/store/apps/details?id=com.alsoug.mycashi',
    integration: 'manual_tracking',
    capabilities: ['manual_balance_entry', 'manual_income_entry', 'manual_expense_entry', 'receipt_reference'],
    unsupported: ['live_balance_sync', 'direct_transfer', 'automatic_payment'],
    requiresUserApproval: true,
    verificationNote: 'Confirm the installed app and current provider terms before relying on account or payout details.',
  },
  {
    id: 'trust_wallet',
    name: 'Trust Wallet',
    country: 'GLOBAL',
    category: 'self_custody_crypto_wallet',
    appUrl: 'https://trustwallet.com/',
    integration: 'manual_tracking',
    capabilities: ['manual_balance_entry', 'manual_income_entry', 'manual_expense_entry', 'public_address_tracking_planned'],
    unsupported: ['seed_phrase_import', 'private_key_import', 'live_balance_sync', 'direct_transfer', 'automatic_payment'],
    requiresUserApproval: true,
    verificationNote: 'Never request a recovery phrase or private key. Public-address balance lookup is a separate future read-only integration and is not enabled by this catalog.',
  },
  {
    id: 'paypal',
    name: 'PayPal',
    country: 'GLOBAL',
    category: 'online_payment_account',
    appUrl: 'https://www.paypal.com/',
    integration: 'manual_tracking',
    capabilities: ['manual_balance_entry', 'manual_income_entry', 'manual_expense_entry', 'receipt_reference'],
    unsupported: ['live_balance_sync', 'direct_transfer', 'automatic_payment'],
    requiresUserApproval: true,
    verificationNote: 'Availability, receiving, and withdrawal features vary by country and account. No PayPal OAuth/API integration is enabled.',
  },
]);
const ENTRY_TYPES = new Set(['income', 'expense', 'transfer', 'balance_adjustment']);

function listNovaWalletProviders() {
  return WALLETS.map((wallet) => ({
    ...wallet,
    capabilities: [...wallet.capabilities],
    unsupported: [...wallet.unsupported],
  }));
}

function normalizeNovaWalletEntry(data = {}) {
  const walletId = String(data.walletId || '').trim();
  if (!WALLETS.some((wallet) => wallet.id === walletId)) {
    throw new Error('walletId must be a supported NOVA wallet provider.');
  }
  const type = String(data.type || '').trim().toLowerCase();
  if (!ENTRY_TYPES.has(type)) throw new Error('type must be income, expense, transfer, or balance_adjustment.');
  const amount = Number(data.amount);
  if (!Number.isFinite(amount) || amount <= 0 || amount > 1e12) {
    throw new Error('amount must be a positive finite number.');
  }
  const currency = String(data.currency || 'SDG').trim().toUpperCase();
  if (!/^[A-Z]{3,8}$/.test(currency)) throw new Error('currency must be a valid currency code.');
  return {
    walletId,
    type,
    amount,
    currency,
    note: String(data.note || '').trim().slice(0, 500),
    reference: String(data.reference || '').trim().slice(0, 120),
    occurredAt: data.occurredAt ? new Date(data.occurredAt).toISOString() : null,
    requiresApproval: type === 'transfer',
    executionMode: 'manual_only',
    status: type === 'transfer' ? 'awaiting_user_approval' : 'recorded_by_user',
    disclaimer: 'NOVA records user-entered information only; it has not verified a provider balance or moved money.',
  };
}
exports.listNovaWalletProviders = listNovaWalletProviders;
exports.normalizeNovaWalletEntry = normalizeNovaWalletEntry;
