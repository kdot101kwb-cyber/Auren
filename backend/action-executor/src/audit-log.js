import { FieldValue } from 'firebase-admin/firestore';

const MAX_AUDIT_EVENT_BYTES = 16 * 1024;
const MAX_AUDIT_EVENT_FIELDS = 40;

function validateAuditEvent(event) {
  if (!event || typeof event !== 'object' || Array.isArray(event)) {
    throw Object.assign(new Error('Audit event must be an object.'), { code: 400 });
  }
  const prototype = Object.getPrototypeOf(event);
  if (prototype !== Object.prototype && prototype !== null) {
    throw Object.assign(new Error('Audit event must be a plain object.'), { code: 400 });
  }
  if (Object.keys(event).length > MAX_AUDIT_EVENT_FIELDS) {
    throw Object.assign(new Error('Audit event contains too many fields.'), { code: 400 });
  }
  let serialized;
  try {
    serialized = JSON.stringify(event);
  } catch {
    throw Object.assign(new Error('Audit event must be JSON-serializable.'), { code: 400 });
  }
  if (typeof serialized !== 'string' || Buffer.byteLength(serialized, 'utf8') > MAX_AUDIT_EVENT_BYTES) {
    throw Object.assign(new Error('Audit event exceeds the size limit.'), { code: 400 });
  }
  return JSON.parse(serialized);
}

export async function writeAuditEvent(db, uid, event) {
  if (typeof uid !== 'string' || !uid.trim() || uid.length > 128 || uid.includes('/')) {
    throw Object.assign(new Error('A valid owner uid is required.'), { code: 400 });
  }
  const safeEvent = validateAuditEvent(event);
  const ref = db.collection('users').doc(uid.trim()).collection('action_audit').doc();
  await ref.set({
    ...safeEvent,
    uid: uid.trim(),
    createdAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}
