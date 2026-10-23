const MAX_ID_LENGTH = 128;
const MAX_READING = Number.MAX_SAFE_INTEGER;

function requiredId(value, field) {
  if (typeof value !== 'string' || !value.trim() || value.length > MAX_ID_LENGTH || value.includes('/')) {
    throw Object.assign(new Error(`A valid ${field} is required.`), { code: 400 });
  }
  return value.trim();
}

function date(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw Object.assign(new Error('date must use YYYY-MM-DD.'), { code: 400 });
  }
  const parsed = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
    throw Object.assign(new Error('Invalid reading date.'), { code: 400 });
  }
  return value;
}

export function normalizeWaterReading(input, ownerUid) {
  requiredId(ownerUid, 'owner uid');
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw Object.assign(new Error('Reading must be an object.'), { code: 400 });
  }
  const meterId = requiredId(input.meterId, 'meter id');
  const readingDate = date(input.date);
  if (!Number.isSafeInteger(input.value) || input.value < 0 || input.value > MAX_READING) {
    throw Object.assign(new Error('Reading value must be a non-negative safe integer.'), { code: 400 });
  }
  const unit = typeof input.unit === 'string' ? input.unit.trim().toLowerCase() : 'litre';
  if (!['litre', 'kilolitre', 'gallon'].includes(unit)) {
    throw Object.assign(new Error('Unsupported water unit.'), { code: 400 });
  }
  return { ownerUid: ownerUid.trim(), meterId, date: readingDate, value: input.value, unit };
}

export function calculateWaterConsumption(previous, current) {
  if (!previous || !current || previous.meterId !== current.meterId || previous.unit !== current.unit) {
    throw Object.assign(new Error('Readings must share a meter and unit.'), { code: 400 });
  }
  if (typeof previous.date !== 'string' || typeof current.date !== 'string' || current.date <= previous.date) {
    throw Object.assign(new Error('Current reading must be later than previous reading.'), { code: 400 });
  }
  if (!Number.isSafeInteger(previous.value) || !Number.isSafeInteger(current.value)
      || previous.value < 0 || current.value < previous.value) {
    throw Object.assign(new Error('Meter readings must be non-negative and monotonic.'), { code: 400 });
  }
  return { meterId: current.meterId, unit: current.unit, from: previous.date, to: current.date, consumed: current.value - previous.value };
}
