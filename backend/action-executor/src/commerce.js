import crypto from 'node:crypto';
import { FieldValue } from 'firebase-admin/firestore';

export function createTransactionId(){return 'txn_'+crypto.randomUUID();}
export function validateCommerceRequest(input){
  return !!input &&
    typeof input.agentId==='string' &&
    typeof input.currency==='string' &&
    /^[A-Z]{3}$/.test(input.currency) &&
    Number.isInteger(input.amountMinor) &&
    input.amountMinor>0 &&
    typeof input.idempotencyKey==='string' &&
    input.idempotencyKey.length>=16;
}
export async function reserveSpending(db,uid,amountMinor,currency,actionId,idempotencyKey){
  if(!Number.isInteger(amountMinor)||amountMinor<=0)throw Object.assign(new Error('Invalid transaction amount.'),{code:400});
  if(!idempotencyKey||idempotencyKey.length<16)throw Object.assign(new Error('Invalid idempotency key.'),{code:400});
  const ref=db.collection('users').doc(uid).collection('wallet').doc('primary');
  const txRef=db.collection('users').doc(uid).collection('wallet_transactions').doc(idempotencyKey);
  return db.runTransaction(async t=>{
    const existing=await t.get(txRef);
    if(existing.exists)return existing.data();
    const s=await t.get(ref);
    const w=s.exists?s.data():{currency,availableMinor:0,reservedMinor:0};
    if(w.currency!==currency)throw Object.assign(new Error('Wallet currency mismatch.'),{code:409});
    const available=(w.availableMinor||0)-(w.reservedMinor||0);
    if(available<amountMinor)throw Object.assign(new Error('Insufficient available wallet balance.'),{code:403});
    const transactionId=createTransactionId();
    t.set(ref,{currency,availableMinor:w.availableMinor||0,reservedMinor:(w.reservedMinor||0)+amountMinor,updatedAt:FieldValue.serverTimestamp()},{merge:true});
    t.create(txRef,{transactionId,type:'reserve',amountMinor,currency,status:'reserved',actionId,idempotencyKey,createdAt:FieldValue.serverTimestamp()});
    return {transactionId,status:'reserved'};
  });
}
