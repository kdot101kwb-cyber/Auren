export async function loadPermissionLedger(db, uid) {
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
  const data = snap.data();
  return {
    enabled: data.enabled === true,
    allowedActions: new Set(
      Array.isArray(data.allowedActions) ? data.allowedActions : []
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

export function assertPermission(ledger, action) {
  if (!ledger.enabled) throw Object.assign(
    new Error('AUREN agent permissions are disabled.'), { code: 403 }
  );
  if (ledger.allowedActions.size > 0 &&
      !ledger.allowedActions.has(action.actionType)) {
    throw Object.assign(
      new Error('Action is not granted by the permission ledger.'), { code: 403 }
    );
  }
}

export function assertSpendingLimit(ledger, action) {
  const amount = Number.isInteger(action.spendingLimitMinor)
    ? action.spendingLimitMinor : 0;
  if (amount < 0) throw Object.assign(
    new Error('Invalid spending amount.'), { code: 400 }
  );
  if (ledger.dailySpendingLimitMinor !== null &&
      ledger.spentTodayMinor + amount > ledger.dailySpendingLimitMinor) {
    throw Object.assign(
      new Error('Daily AUREN spending limit exceeded.'), { code: 403 }
    );
  }
}
