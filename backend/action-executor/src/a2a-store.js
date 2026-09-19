import { FieldValue } from 'firebase-admin/firestore';
export async function saveMessage(db,message){const ref=db.collection('agent_messages').doc(message.messageId);await ref.create({...message,createdAt:FieldValue.serverTimestamp()});return ref.id;}
