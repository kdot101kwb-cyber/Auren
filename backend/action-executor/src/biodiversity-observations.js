const MAX_TEXT_LENGTH = 240;
const MAX_ID_LENGTH = 128;

function cleanText(value, field, max = MAX_TEXT_LENGTH, required = true) {
  if (typeof value !== 'string') {
    if (!required && value == null) return '';
    throw Object.assign(new Error(`${field} must be text.`), { code: 400 });
  }
  const result = value.trim();
  if ((required && !result) || result.length > max || /[\u0000-\u001f\u007f]/.test(result)) {
    throw Object.assign(new Error(`Invalid ${field}.`), { code: 400 });
  }
  return result;
}

function validDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(date.getTime()) && date.toISOString().slice(0, 10) === value;
}

export function normalizeBiodiversityObservation(input, ownerUid) {
  if (typeof ownerUid !== 'string' || !ownerUid.trim() || ownerUid.length > MAX_ID_LENGTH || ownerUid.includes('/')) {
    throw Object.assign(new Error('A valid owner uid is required.'), { code: 400 });
  }
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw Object.assign(new Error('Observation must be an object.'), { code: 400 });
  }
  if (!validDate(input.observedOn)) throw Object.assign(new Error('observedOn must be a valid YYYY-MM-DD date.'), { code: 400 });
  const observationId = input.observationId == null ? '' : cleanText(input.observationId, 'observationId', MAX_ID_LENGTH);
  const latitude = input.latitude == null ? null : input.latitude;
  const longitude = input.longitude == null ? null : input.longitude;
  if ((latitude === null) !== (longitude === null)) {
    throw Object.assign(new Error('Latitude and longitude must be supplied together.'), { code: 400 });
  }
  if (latitude !== null && (!Number.isFinite(latitude) || latitude < -90 || latitude > 90
      || !Number.isFinite(longitude) || longitude < -180 || longitude > 180)) {
    throw Object.assign(new Error('Coordinates are out of range.'), { code: 400 });
  }
  const visibility = ['private', 'approximate', 'public'].includes(input.visibility) ? input.visibility : 'private';
  return {
    ownerUid: ownerUid.trim(),
    observationId,
    species: cleanText(input.species, 'species', 160),
    observedOn: input.observedOn,
    habitat: cleanText(input.habitat ?? '', 'habitat', 160, false),
    notes: cleanText(input.notes ?? '', 'notes', 2000, false),
    latitude,
    longitude,
    visibility,
    // Public display must apply a separate coarse-location projection before sharing.
  };
}

export function projectObservationForSharing(observation) {
  if (!observation || typeof observation !== 'object') {
    throw Object.assign(new Error('Observation is required.'), { code: 400 });
  }
  const base = {
    observationId: observation.observationId,
    species: observation.species,
    observedOn: observation.observedOn,
    habitat: observation.habitat || '',
    visibility: observation.visibility || 'private',
  };
  if (base.visibility !== 'public') return base;
  return {
    ...base,
    // Do not expose exact coordinates or owner identity through the sharing projection.
    locationAvailable: Number.isFinite(observation.latitude) && Number.isFinite(observation.longitude),
  };
}
