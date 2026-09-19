import crypto from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

export const DISPUTE_STATES = Object.freeze(['open','under_review','resolved','rejected','cancelled']);
export const LIABILITY_STATES = Object.freeze(['none','pending','assigned','resolved']);

export function createDisputeId(){ return 'dsp_'+crypto.randomUUID(); }

export async function openDispute(db, uid, {transactionId, reason, description}){
  if(typeof transactionId!=='string'||!transactionId.trim()) throw Object.assign(new Error('transactionId is required.'),{code:400});
  if(typeof reason!=='string'||reason.trim().length<2) throw Object.assign(new Error('Dispute reason is required.'),{code:400});
  if(typeof description!=='string'||description.trim().length<5) throw Object.assign(new Error('Dispute description is required.'),{code:400});
  const txQuery=await db.collection('users').doc(uid).collection('wallet_transactions').where('transactionId','==',transactionId.trim()).limit(1).get();
  if(txQuery.empty) throw Object.assign(new Error('Transaction not found.'),{code:404});
  const tx=txQuery.docs[0].data();
  if(!['reserved','settled','refunded'].includes(tx.status)) throw Object.assign(new Error('Transaction is not eligible for dispute.'),{code:409});
  const disputeId=createDisputeId();
  const ref=db.collection('users').doc(uid).collection('disputes').doc(disputeId);
  const liabilityRef=db.collection('users').doc(uid).collection('agent_liability').doc(disputeId);
  await db.runTransaction(async t=>{
    t.create(ref,{disputeId,transactionId,reason:reason.trim().slice(0,200),description:description.trim().slice(0,4000),state:'open',liabilityState:'pending',createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp()});
    t.create(liabilityRef,{disputeId,transactionId,agentId:tx.agentId||null,state:'pending',amountMinor:tx.amountMinor||0,currency:tx.currency||null,createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp()});
  });
  return {disputeId,state:'open',liabilityState:'pending'};
}
