import { FieldValue } from 'firebase-admin/firestore';

export async function writeAuditEvent(db, uid, event) {
  const ref = db.collection('users').doc(uid).collection('action_audit').doc();
  await ref.set({
    ...event,
    uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return ref.id;
}
