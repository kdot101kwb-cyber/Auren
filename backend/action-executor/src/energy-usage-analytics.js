const ENERGY_UNITS = Object.freeze(['kwh', 'wh', 'm3', 'litre']);
const MAX_LABEL_LENGTH = 120;

function validDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
}

export function normalizeEnergyEntry(input, ownerUid) {
  if (typeof ownerUid !== 'string' || !ownerUid.trim() || ownerUid.length > 128 || ownerUid.includes('/')) {
    throw Object.assign(new Error('A valid owner uid is required.'), { code: 400 });
  }
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw Object.assign(new Error('Energy entry must be an object.'), { code: 400 });
  }
  const label = typeof input.label === 'string' ? input.label.trim() : '';
  if (!label || label.length > MAX_LABEL_LENGTH || /[\u0000-\u001f\u007f]/.test(label)) {
    throw Object.assign(new Error('A valid entry label is required.'), { code: 400 });
  }
  const unit = typeof input.unit === 'string' ? input.unit.trim().toLowerCase() : '';
  if (!ENERGY_UNITS.includes(unit)) throw Object.assign(new Error('Unsupported energy/resource unit.'), { code: 400 });
  if (!validDate(input.date)) throw Object.assign(new Error('date must be a valid YYYY-MM-DD date.'), { code: 400 });
  if (!Number.isSafeInteger(input.amount) || input.amount < 0) {
    throw Object.assign(new Error('amount must be a non-negative safe integer.'), { code: 400 });
  }
  const costMinor = input.costMinor == null ? null : input.costMinor;
  if (costMinor !== null && (!Number.isSafeInteger(costMinor) || costMinor < 0)) {
    throw Object.assign(new Error('costMinor must be a non-negative safe integer.'), { code: 400 });
  }
  return { ownerUid: ownerUid.trim(), label, date: input.date, unit, amount: input.amount, costMinor };
}

export function summarizeResourceUsage(entries, { from, to } = {}) {
  if (!Array.isArray(entries)) throw Object.assign(new Error('Entries must be an array.'), { code: 400 });
  if ((from && !validDate(from)) || (to && !validDate(to)) || (from && to && from > to)) {
    throw Object.assign(new Error('Invalid summary date range.'), { code: 400 });
  }
  const totals = new Map();
  for (const entry of entries) {
    if (!entry || !validDate(entry.date) || (from && entry.date < from) || (to && entry.date > to)) continue;
    if (!ENERGY_UNITS.includes(entry.unit) || !Number.isSafeInteger(entry.amount) || entry.amount < 0) continue;
    const key = entry.unit;
    const current = totals.get(key) || { unit: key, amount: 0, costMinor: 0, costEntries: 0, entries: 0 };
    const nextAmount = current.amount + entry.amount;
    if (!Number.isSafeInteger(nextAmount)) continue;
    current.amount = nextAmount;
    current.entries += 1;
    if (Number.isSafeInteger(entry.costMinor) && entry.costMinor >= 0) {
      const nextCost = current.costMinor + entry.costMinor;
      if (Number.isSafeInteger(nextCost)) {
        current.costMinor = nextCost;
        current.costEntries += 1;
      }
    }
    totals.set(key, current);
  }
  return [...totals.values()].sort((a, b) => a.unit.localeCompare(b.unit));
}

export { ENERGY_UNITS };
